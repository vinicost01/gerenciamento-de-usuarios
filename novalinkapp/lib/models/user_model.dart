import 'dart:convert';
import 'package:flutter/material.dart';

class User {
  final int id;
  final String username;
  String nome;
  final String email;
  String? phone;
  final String? codAssessor;
  final String role;
  String? escritorio;
  String? profileImageBase64;

  User({
    required this.id,
    required this.username,
    required this.nome,
    required this.email,
    this.phone,
    this.codAssessor,
    required this.role,
    this.escritorio,
    this.profileImageBase64,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      nome: json['nome'],
      email: json['email'],
      phone: json['phone'],
      codAssessor: json['cod_assessor'],
      role: json['role'],
      escritorio: json['escritorio'],
      profileImageBase64: json['profile_image_base64'],
    );
  }
  ImageProvider? get profileImage {
    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(profileImageBase64!));
      } catch (e) {
        print('Erro ao descodificar Base64: $e');
        return null;
      }
    }
    return null;
  }
}