import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

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
      userLoc.latitude, userLoc.longitude,
      latitude, longitude,
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
  List<Unidade> _allUnidades = [];
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  bool _loading = true;
  String _search = '';

  int _currentPage = 1;
  final int _perPage = 15;

  @override
  void initState() {
    super.initState();
    _loadData();
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
          nome: acf['nome'] ?? item['title']['rendered'] ?? '',
          endereco: acf['endereco'] ?? '',
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
      _markers = list.map((u) => Marker(
        markerId: MarkerId(u.nome),
        position: LatLng(u.latitude, u.longitude),
        infoWindow: InfoWindow(title: u.nome, snippet: u.endereco),
      )).toSet();
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
    return _allUnidades.where((u) {
      return u.nome.toLowerCase().contains(_search.toLowerCase()) ||
             u.endereco.toLowerCase().contains(_search.toLowerCase());
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

  List<int> _buildPageNumbers(int totalPages) {
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => index + 1);
    } else if (_currentPage <= 3) {
      return [1, 2, 3, 4, 5];
    } else if (_currentPage >= totalPages - 2) {
      return [totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
    } else {
      return [_currentPage - 2, _currentPage - 1, _currentPage, _currentPage + 1, _currentPage + 2];
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
    final end = (start + _perPage).clamp(0, all.length);
    final pageItems = all.sublist(start, end);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Unidades', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF204181))),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Encontre todas as unidades por cidade ou bairro.\nConsulte endereço, contato e horário de cada uma.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Buscar por cidade ou bairro',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF204181))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF204181))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 48, width: 48,
                      decoration: BoxDecoration(color: Color(0xFF204181), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        child: AbsorbPointer(
                          absorbing: false,
                          child: GoogleMap(
                            onMapCreated: (c) => _mapController = c,
                            initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 13),
                            myLocationEnabled: true,
                            markers: _markers,
                            gestureRecognizers: {},
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pageItems.map((u) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: GestureDetector(
                      onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(u.latitude, u.longitude), 16)),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.nome, style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(children: List.generate(5, (idx) => Icon(idx < u.avaliacao.round() ? Icons.star : Icons.star_border, size: 16, color: Colors.amber))),
                                  const SizedBox(height: 4),
                                  Text(u.endereco, style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('${u.distanciaKm.toStringAsFixed(1)} km', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 120,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _abrirRota(u.latitude, u.longitude),
                                      icon: const Icon(Icons.navigation, size: 16),
                                      label: const Text('Ver rota'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF204181),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              child: Image.network(u.imagemUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                  if (totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPageBtn(Icons.first_page, () => setState(() => _currentPage = 1)),
                          _buildPageBtn(Icons.chevron_left, () { if (_currentPage > 1) setState(() => _currentPage--); }),
                          for (int p in _buildPageNumbers(totalPages)) Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() => _currentPage = p),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: p == _currentPage ? Color(0xFF204181) : Color(0xFFF2F3F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text('$p', style: TextStyle(color: p == _currentPage ? Colors.white : Colors.black, fontSize: 12)),
                              ),
                            ),
                          ),
                          _buildPageBtn(Icons.chevron_right, () { if (_currentPage < totalPages) setState(() => _currentPage++); }),
                          _buildPageBtn(Icons.last_page, () => setState(() => _currentPage = totalPages)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF2F3F5), borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
