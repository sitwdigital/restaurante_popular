// IMPORTS 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Unidade {
  final String nome;
  final String endereco;
  final String imagemUrl;
  final double latitude;
  final double longitude;
  final double avaliacao;
  late final double distanciaKm;

  Unidade({
    required this.nome,
    required this.endereco,
    required this.imagemUrl,
    required this.latitude,
    required this.longitude,
    required this.avaliacao,
  });

  void calcularDistancia(LatLng userLoc) {
    distanciaKm = Geolocator.distanceBetween(
      userLoc.latitude,
      userLoc.longitude,
      latitude,
      longitude,
    ) / 1000;
  }
}

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({Key? key}) : super(key: key);

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final String _baseUrl = 'https://sitw.com.br/restaurante_popular';
  final TextEditingController _searchController = TextEditingController();

  List<Unidade> _allUnidades = [];
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  final int _perPage = 15;

  final ScrollController _scrollController = ScrollController();

  // >>> NOVO: key para descobrir a posição do mapa na tela
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // >>> NOVO: anima a rolagem até o mapa
  Future<void> _scrollToMap() async {
    if (!_scrollController.hasClients) return;
    if (_mapKey.currentContext == null) return;

    // Posição do mapa em coordenadas globais
    final box = _mapKey.currentContext!.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);

    // Converte para offset dentro do scroll atual
    final currentOffset = _scrollController.offset;
    // Margem para não “colar” demais no topo
    const topPadding = 12.0;

    final target = currentOffset + pos.dy - topPadding;
    final max = _scrollController.position.maxScrollExtent;
    final safeTarget = target.clamp(0.0, max);

    await _scrollController.animateTo(
      safeTarget,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadData() async {
    await Permission.location.request();
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _userLocation = LatLng(pos.latitude, pos.longitude);

    final List<Unidade> list = [];
    int page = 1;
    while (true) {
      final res = await http.get(Uri.parse('$_baseUrl/wp-json/wp/v2/unidade?per_page=100&page=$page'));
      if (res.statusCode != 200) break;
      final data = jsonDecode(res.body) as List<dynamic>;
      if (data.isEmpty) break;
      for (var item in data) {
        final acf = item['acf'] ?? {};
        final lat = double.tryParse(acf['latitude'] ?? '') ?? 0.0;
        final lng = double.tryParse(acf['longitude'] ?? '') ?? 0.0;
        final u = Unidade(
          nome: '${acf['nome'] ?? item['title']['rendered'] ?? ''}',
          endereco: '${acf['endereco'] ?? ''}',
          imagemUrl: acf['imagem'] is Map ? acf['imagem']['url'] ?? '' : '',
          latitude: lat,
          longitude: lng,
          avaliacao: double.tryParse(acf['avaliacao']?.toString() ?? '0') ?? 0.0,
        );
        if (_userLocation != null) u.calcularDistancia(_userLocation!);
        list.add(u);
      }
      page++;
    }

    list.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));

    setState(() {
      _allUnidades = list;
      _markers = list
          .map(
            (u) => Marker(
              markerId: MarkerId(u.nome),
              position: LatLng(u.latitude, u.longitude),
              infoWindow: InfoWindow(title: u.nome, snippet: u.endereco),
            ),
          )
          .toSet();
      _loading = false;
    });
  }

  void _onSearch(String text) {
    setState(() {
      _search = text;
      _currentPage = 1;
    });
  }

  List<Unidade> get _filtered {
    final filtro = _search.toLowerCase();
    return _allUnidades.where((u) {
      final nome = u.nome.toLowerCase();
      final endereco = u.endereco.toLowerCase();
      return nome.contains(filtro) || endereco.contains(filtro);
    }).toList();
  }

  Future<void> _abrirRota(double lat, double lng) async {
    final google = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final waze = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(google)) {
      await launchUrl(google, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(waze)) {
      await launchUrl(waze, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _userLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final all = _filtered;
    final totalPages = (all.length / _perPage).ceil();
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 40,
                      colorFilter: null,
                    ),
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
              // >>> ADICIONADO key para encontrarmos a posição do mapa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    key: _mapKey, // <<< AQUI
                    height: 200,
                    child: GoogleMap(
                      onMapCreated: (c) => _mapController = c,
                      initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 13),
                      myLocationEnabled: true,
                      markers: _markers,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...pageItems.map(
                (u) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GestureDetector(
                    onTap: () async {
                      // 1) rola até o mapa
                      await _scrollToMap();
                      // 2) anima a câmera para a unidade
                      final dest = LatLng(u.latitude, u.longitude);
                      await _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(dest, 16),
                      );
                      // 3) mostra o balão (InfoWindow) do marker
                      _mapController?.showMarkerInfoWindow(MarkerId(u.nome));
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
                                Text(u.endereco, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  '${u.distanciaKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
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
                            child: Image.network(
                              u.imagemUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
