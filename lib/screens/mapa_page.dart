import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  LatLng? _userLocation;
  List<Map<String, dynamic>> _restaurantes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _getUserLocation();
  }

  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse('http://SEU_DOMINIO/api/restaurantes?populate=*'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      setState(() {
        _restaurantes = data.cast<Map<String, dynamic>>();
      });
    } else {
      throw Exception('Erro ao buscar restaurantes');
    }
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa dos Restaurantes")),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: _userLocation,
                zoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: _userLocation!,
                      builder: (ctx) => const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                    ),
                    ..._restaurantes.map((rest) {
                      final imageUrl = 'http://SEU_DOMINIO${rest["imagem"]["url"]}';
                      final point = LatLng(rest["latitude"], rest["longitude"]);

                      return Marker(
                        width: 80,
                        height: 80,
                        point: point,
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(rest["nome"]),
                                content: Image.network(imageUrl),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Fechar"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      );
                    }).toList()
                  ],
                ),
              ],
            ),
    );
  }
}
