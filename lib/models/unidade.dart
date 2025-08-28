// lib/models/unidade.dart
import 'package:hive/hive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

part 'unidade.g.dart';

@HiveType(typeId: 0)
class Unidade extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String nome;

  @HiveField(2)
  final String endereco;

  @HiveField(3)
  final String imagemUrl;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final double avaliacao;

  /// Distância em linha reta (km), calculada em runtime
  @HiveField(7)
  double distanciaKm;

  /// Distância por rota (km) via Google Distance Matrix (opcional)
  @HiveField(8)
  double? distanciaRotaKm;

  /// Timestamp (epoch ms) de quando a rota foi calculada (TTL)
  @HiveField(9)
  int? rotaAtualizadaEmEpochMs;

  Unidade({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.imagemUrl,
    required this.latitude,
    required this.longitude,
    required this.avaliacao,
    this.distanciaKm = 0,
    this.distanciaRotaKm,
    this.rotaAtualizadaEmEpochMs,
  });

  factory Unidade.fromWpJson(Map<String, dynamic> json) {
    final acf = (json['acf'] ?? {}) as Map<String, dynamic>;

    double _parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
    }

    String _parseImagem(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map && v['url'] != null) return v['url'].toString();
      return '';
    }

    return Unidade(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      nome: (acf['nome'] ?? (json['title']?['rendered'] ?? '')).toString(),
      endereco: (acf['endereco'] ?? '').toString(),
      imagemUrl: _parseImagem(acf['imagem']),
      latitude: _parseDouble(acf['latitude']),
      longitude: _parseDouble(acf['longitude']),
      avaliacao: _parseDouble(acf['avaliacao']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'endereco': endereco,
        'imagemUrl': imagemUrl,
        'latitude': latitude,
        'longitude': longitude,
        'avaliacao': avaliacao,
        'distanciaKm': distanciaKm,
        'distanciaRotaKm': distanciaRotaKm,
        'rotaAtualizadaEmEpochMs': rotaAtualizadaEmEpochMs,
      };

  void calcularDistancia(LatLng userLoc) {
    distanciaKm = Geolocator.distanceBetween(
          userLoc.latitude,
          userLoc.longitude,
          latitude,
          longitude,
        ) /
        1000.0;
  }
}
