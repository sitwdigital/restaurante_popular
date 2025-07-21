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

  void calcularDistancia(LatLng local) {
    distanciaKm = Geolocator.distanceBetween(
      local.latitude,
      local.longitude,
      latitude,
      longitude,
    ) / 1000;
  }
}

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final String _baseUrl = 'https://sitw.com.br/restaurante_popular';
  List<Unidade> unidades = [];
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
    await Permission.location.request();
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userLocation = LatLng(pos.latitude, pos.longitude);

    final response = await http.get(Uri.parse('$_baseUrl/wp-json/wp/v2/unidade'));
    if (response.statusCode != 200) {
      setState(() => loading = false);
      return;
    }

    final List<dynamic> data = jsonDecode(response.body);
    List<Unidade> carregadas = [];

    for (var item in data) {
      final acf = item['acf'] ?? {};

      String imagemUrl = '';
      final imagemData = acf['imagem'];
      if (imagemData is Map && imagemData.containsKey('url')) {
        imagemUrl = imagemData['url'];
      }

      final unidade = Unidade(
        nome: acf['nome'] ?? item['title']['rendered'] ?? '',
        endereco: acf['endereco'] ?? '',
        imagemUrl: imagemUrl,
        latitude: double.tryParse(acf['latitude'] ?? '') ?? 0.0,
        longitude: double.tryParse(acf['longitude'] ?? '') ?? 0.0,
        avaliacao: double.tryParse(acf['avaliacao']?.toString() ?? '0') ?? 0.0,
      );

      unidade.calcularDistancia(userLocation!);
      carregadas.add(unidade);
    }

    carregadas.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));

    setState(() {
      unidades = carregadas;
      markers = carregadas.map((u) => Marker(
        markerId: MarkerId(u.nome),
        position: LatLng(u.latitude, u.longitude),
        infoWindow: InfoWindow(title: u.nome, snippet: u.endereco),
      )).toSet();
      loading = false;
    });
  }

  void _focarMapa(Unidade unidade) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(unidade.latitude, unidade.longitude), 16),
    );
  }

  void _filtrar(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  Future<void> _abrirRota(double latitude, double longitude) async {
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
    final wazeUrl = 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(Uri.parse(wazeUrl))) {
      await launchUrl(Uri.parse(wazeUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o aplicativo de navegação.')),
      );
    }
  }

  Widget _buildEstrelas(double avaliacao) {
    return Row(
      children: List.generate(5, (index) => Icon(
        index < avaliacao.round()
          ? Icons.star
          : Icons.star_border,
        color: Colors.amber,
        size: 16,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading || userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final unidadesFiltradas = unidades.where((u) =>
      u.nome.toLowerCase().contains(searchQuery) ||
      u.endereco.toLowerCase().contains(searchQuery)
    ).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Text('Unidades', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF204181))),
                  SizedBox(height: 4),
                  Text('Encontre todas as unidades por cidade ou bairro. Consulte endereço, contato e horário de cada uma.', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _filtrar,
                      decoration: InputDecoration(
                        hintText: 'Buscar por cidade ou bairro',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: GoogleMap(
                    onMapCreated: (controller) => mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: userLocation!,
                      zoom: 13,
                    ),
                    myLocationEnabled: true,
                    markers: markers,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: unidadesFiltradas.length,
                itemBuilder: (context, index) {
                  final u = unidadesFiltradas[index];
                  return GestureDetector(
                    onTap: () => _focarMapa(u),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                _buildEstrelas(u.avaliacao),
                                const SizedBox(height: 4),
                                Text(u.endereco, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('${u.distanciaKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 200,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _abrirRota(u.latitude, u.longitude),
                                    icon: const Icon(Icons.send, size: 16),
                                    label: const Text("Ver rota"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF204181),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      textStyle: const TextStyle(fontSize: 13),
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
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported),
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