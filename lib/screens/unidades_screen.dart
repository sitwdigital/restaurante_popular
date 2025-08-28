// lib/screens/unidades_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';

import 'package:restaurante_popular/models/unidade.dart';

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({Key? key}) : super(key: key);

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final String _baseUrl = 'https://sitw.com.br/restaurante_popular';
  final TextEditingController _searchController = TextEditingController();

  // Fator para estimar "rota" a partir da reta (ajuste fino entre 1.25 ~ 1.35)
  static const double _fatorRotaAprox = 1.25;

  List<Unidade> _allUnidades = [];
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  final int _perPage = 15;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final ok = await _ensureLocationPermission();
    if (!ok) {
      setState(() => _loading = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _userLocation = LatLng(pos.latitude, pos.longitude);

    await _loadFromCache();   // mostra rápido o que tiver
    _refreshFromApi();        // sincroniza do WP em segundo plano
  }

  Future<bool> _ensureLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;
    status = await Permission.location.request();
    return status.isGranted;
  }

  Future<void> _loadFromCache() async {
    final box = await Hive.openBox<Unidade>('unidadesBox');
    if (box.isNotEmpty) {
      final cached = box.values.toList();

      if (_userLocation != null) {
        for (final u in cached) {
          u.calcularDistancia(_userLocation!); // reta (km)
        }
        cached.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
      }

      final markers = cached
          .where((u) => u.latitude != 0 && u.longitude != 0)
          .map(
            (u) => Marker(
              markerId: MarkerId('unidade_${u.id}'),
              position: LatLng(u.latitude, u.longitude),
              infoWindow: InfoWindow(title: u.nome, snippet: u.endereco),
            ),
          )
          .toSet();

      setState(() {
        _allUnidades = cached;
        _markers = markers;
        _loading = false;
      });
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final freshList = await _fetchAllPaged();

      if (_userLocation != null) {
        for (final u in freshList) {
          u.calcularDistancia(_userLocation!); // reta (km)
        }
        freshList.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
      }

      final box = await Hive.openBox<Unidade>('unidadesBox');
      await box.clear();
      await box.addAll(freshList);

      final markers = freshList
          .where((u) => u.latitude != 0 && u.longitude != 0)
          .map(
            (u) => Marker(
              markerId: MarkerId('unidade_${u.id}'),
              position: LatLng(u.latitude, u.longitude),
              infoWindow: InfoWindow(title: u.nome, snippet: u.endereco),
            ),
          )
          .toSet();

      if (mounted) {
        setState(() {
          _allUnidades = freshList;
          _markers = markers;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Unidade>> _fetchAllPaged() async {
    final List<Unidade> all = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final url = '$_baseUrl/wp-json/wp/v2/unidade?per_page=50&page=$page';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) break;

      final List data = jsonDecode(res.body) as List;
      if (data.isEmpty) {
        hasMore = false;
      } else {
        all.addAll(data.map((e) => Unidade.fromWpJson(e)).toList());
        page++;
      }
    }
    return all;
  }

  void _onSearch(String text) {
    setState(() {
      _search = text.trim();
      _currentPage = 1;
    });
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _scrollToMap() async {
    if (!_scrollController.hasClients || _mapKey.currentContext == null) return;

    final box = _mapKey.currentContext!.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    const topPadding = 12.0;

    final currentOffset = _scrollController.offset;
    final target = currentOffset + pos.dy - topPadding;
    final max = _scrollController.position.maxScrollExtent;
    final safeTarget = target.clamp(0.0, max);

    await _scrollController.animateTo(
      safeTarget,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _abrirRota(double lat, double lng) async {
    final google =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final waze = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(google)) {
      await launchUrl(google, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(waze)) {
      await launchUrl(waze, mode: LaunchMode.externalApplication);
    }
  }

  List<Unidade> get _filtered {
    final filtro = _search.toLowerCase();
    if (filtro.isEmpty) return _allUnidades;
    return _allUnidades.where((u) {
      final nome = u.nome.toLowerCase();
      final endereco = u.endereco.toLowerCase();
      return nome.contains(filtro) || endereco.contains(filtro);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final all = _filtered;
    final totalPages = (all.length / _perPage).ceil().clamp(1, 9999);
    final start = (_currentPage - 1) * _perPage;
    final end = (_currentPage * _perPage).clamp(0, all.length);
    final pageItems = (start >= 0 && start < all.length && end >= start)
        ? all.sublist(start, end)
        : <Unidade>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/images/logo.svg', height: 40),
                    const Spacer(),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Unidades',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF046596),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Encontre o Restaurante Popular mais próximo de você!',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),

              // Busca
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Buscar por cidade ou bairro',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF046596)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF046596)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _onSearch(_searchController.text),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF046596),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Mapa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    key: _mapKey,
                    height: 200,
                    child: GoogleMap(
                      onMapCreated: (c) => _mapController = c,
                      initialCameraPosition:
                          CameraPosition(target: _userLocation!, zoom: 13),
                      myLocationEnabled: true,
                      markers: _markers,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Lista
              ...pageItems.map(
                (u) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await _scrollToMap();
                      final dest = LatLng(u.latitude, u.longitude);
                      await _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(dest, 16),
                      );
                      _mapController?.showMarkerInfoWindow(
                        MarkerId('unidade_${u.id}'),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(
                                    5,
                                    (idx) => Icon(
                                      idx < u.avaliacao.round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Distância aproximada de rota (reta × fator)
                                Builder(
                                  builder: (_) {
                                    final kmReta = u.distanciaKm;
                                    final kmAprox = kmReta * _fatorRotaAprox;
                                    return Row(
                                      children: [
                                        const Icon(Icons.directions_car, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${kmAprox.toStringAsFixed(1)} km (aprox.)',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 6),
                                Text(u.endereco, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _abrirRota(u.latitude, u.longitude),
                                    icon: const Icon(Icons.navigation, size: 16),
                                    label: const Text('Ver rota'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF046596),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (u.imagemUrl.isNotEmpty)
                                ? Image.network(
                                    u.imagemUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_not_supported),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.white,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Paginação
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_currentPage != 1) {
                            setState(() => _currentPage = 1);
                            _scrollToTop();
                          }
                        },
                        child: _paginationButton(Icons.first_page),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_currentPage > 1) {
                            setState(() => _currentPage--);
                            _scrollToTop();
                          }
                        },
                        child: _paginationButton(Icons.chevron_left),
                      ),
                      ..._buildCompactPagination(totalPages),
                      GestureDetector(
                        onTap: () {
                          if (_currentPage < totalPages) {
                            setState(() => _currentPage++);
                            _scrollToTop();
                          }
                        },
                        child: _paginationButton(Icons.chevron_right),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_currentPage != totalPages) {
                            setState(() => _currentPage = totalPages);
                            _scrollToTop();
                          }
                        },
                        child: _paginationButton(Icons.last_page),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paginationButton(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 16, color: Colors.black),
    );
  }

  List<Widget> _buildCompactPagination(int totalPages) {
    List<Widget> items = [];
    int maxPagesToShow = 4;

    if (totalPages <= 0) return items;

    int start = (_currentPage - (maxPagesToShow ~/ 2));
    int end = start + maxPagesToShow - 1;

    if (start < 1) {
      start = 1;
      end = (maxPagesToShow).clamp(1, totalPages);
    } else if (end > totalPages) {
      end = totalPages;
      start = (end - maxPagesToShow + 1).clamp(1, totalPages);
    }

    for (int i = start; i <= end; i++) {
      final isCurrent = i == _currentPage;
      items.add(
        GestureDetector(
          onTap: () {
            setState(() => _currentPage = i);
            _scrollToTop();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFF046596) : const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$i',
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return items;
  }
}
