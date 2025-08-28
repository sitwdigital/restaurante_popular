// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unidade.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnidadeAdapter extends TypeAdapter<Unidade> {
  @override
  final int typeId = 0;

  @override
  Unidade read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Unidade(
      id: fields[0] as int,
      nome: fields[1] as String,
      endereco: fields[2] as String,
      imagemUrl: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      avaliacao: fields[6] as double,
      distanciaKm: fields[7] as double,
      distanciaRotaKm: fields[8] as double?,
      rotaAtualizadaEmEpochMs: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Unidade obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.endereco)
      ..writeByte(3)
      ..write(obj.imagemUrl)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.avaliacao)
      ..writeByte(7)
      ..write(obj.distanciaKm)
      ..writeByte(8)
      ..write(obj.distanciaRotaKm)
      ..writeByte(9)
      ..write(obj.rotaAtualizadaEmEpochMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnidadeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
