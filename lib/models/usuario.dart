import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String dni;
  final String email;
  final String nombreCompleto;
  final String telefono;
  final String direccion;
  final String referencia;
  final int puntosAcumulados;

  const Usuario({
    required this.uid,
    required this.dni,
    required this.email,
    required this.nombreCompleto,
    required this.telefono,
    required this.direccion,
    required this.referencia,
    required this.puntosAcumulados,
  });

  /// Crea un Usuario desde un DocumentSnapshot de Firestore.
  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Usuario(
      uid: data['uid'] ?? '',
      dni: data['dni'] ?? doc.id,
      email: data['email'] ?? '',
      nombreCompleto: data['nombreCompleto'] ?? '',
      telefono: data['telefono'] ?? '',
      direccion: data['direccion'] ?? '',
      referencia: data['referencia'] ?? '',
      puntosAcumulados: (data['puntosAcumulados'] ?? 0).toInt(),
    );
  }

  /// Convierte el Usuario a un Map para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'dni': dni,
      'email': email,
      'nombreCompleto': nombreCompleto,
      'telefono': telefono,
      'direccion': direccion,
      'referencia': referencia,
      'puntosAcumulados': puntosAcumulados,
    };
  }

  /// Crea una copia de Usuario con campos modificados.
  Usuario copyWith({
    String? uid,
    String? dni,
    String? email,
    String? nombreCompleto,
    String? telefono,
    String? direccion,
    String? referencia,
    int? puntosAcumulados,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      dni: dni ?? this.dni,
      email: email ?? this.email,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      referencia: referencia ?? this.referencia,
      puntosAcumulados: puntosAcumulados ?? this.puntosAcumulados,
    );
  }

  @override
  String toString() {
    return 'Usuario(uid: $uid, dni: $dni, email: $email, nombreCompleto: $nombreCompleto, telefono: $telefono, direccion: $direccion, referencia: $referencia, puntosAcumulados: $puntosAcumulados)';
  }
}
