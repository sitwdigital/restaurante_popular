import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

class Unidade {
  final String nome;
  final String endereco;
  final String imagemUrl;
  final double latitude;
  final double longitude;

  Unidade({
    required this.nome,
    required this.endereco,
    required this.imagemUrl,
    required this.latitude,
    required this.longitude,
  });
}

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final String _baseUrl = 'http://192.168.15.3:1337';
  List<Unidade> unidades = [];
  List<Unidade> unidadesFiltradas = [];
  Set<Marker> markers = {};
  LatLng? userLocation;
  GoogleMapController? mapController;
  bool loading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await _solicitarPermissao();
    await _pegarLocalizacao();

    final response = await http.get(Uri.parse('$_baseUrl/api/unidades?populate=*'));
    final data = jsonDecode(response.body);

    List<Unidade> carregadas = [];

    for (var item in data['data']) {
      String imageUrl = '';
      final imgField = item['imagem'];
      if (imgField is Map) {
        final url = imgField['url'] as String?;
        if (url != null && url.isNotEmpty) {
          imageUrl = '$_baseUrl$url';
        }
      }

      final unidade = Unidade(
        nome: item['nome'],
        endereco: item['endereco'] ?? '',
        imagemUrl: imageUrl,
        latitude: item['latitude']?.toDouble() ?? 0.0,
        longitude: item['longitude']?.toDouble() ?? 0.0,
      );

      carregadas.add(unidade);
    }

    setState(() {
      unidades = carregadas;
      unidadesFiltradas = carregadas;
      markers = carregadas.map((u) {
        return Marker(
          markerId: MarkerId(u.nome),
          position: LatLng(u.latitude, u.longitude),
          infoWindow: InfoWindow(title: u.nome, snippet: u.endereco),
        );
      }).toSet();
      loading = false;
    });
  }

  Future<void> _solicitarPermissao() async {
    await Permission.location.request();
  }

  Future<void> _pegarLocalizacao() async {
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      userLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  void _focarMapa(Unidade unidade) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(unidade.latitude, unidade.longitude), 16),
    );
  }

  void _filtrarUnidades(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      unidadesFiltradas = unidades.where((u) {
        return u.nome.toLowerCase().contains(searchQuery) ||
               u.endereco.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading || userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar com logo e notificação
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SvgPicture.asset('assets/images/logo.svg', height: 40),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 28, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Título e subtítulo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Unidades',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF204181)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Encontre todas as unidades por cidade ou bairro. Consulte endereço, contato e horário de cada uma.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // Barra de busca
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _filtrarUnidades,
                      decoration: InputDecoration(
                        hintText: 'Buscar por cidade ou bairro',
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF204181)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF204181)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF204181),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mapa
            Expanded(
              flex: 1,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: userLocation!,
                  zoom: 13,
                ),
                onMapCreated: (controller) => mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: markers,
              ),
            ),

            // Lista de unidades
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: unidadesFiltradas.length,
                itemBuilder: (context, index) {
                  final u = unidadesFiltradas[index];
                  return GestureDetector(
                    onTap: () => _focarMapa(u),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: u.imagemUrl.isNotEmpty
                                ? Image.network(
                                    u.imagemUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, error, stack) => const Icon(Icons.image_not_supported),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(u.endereco, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
