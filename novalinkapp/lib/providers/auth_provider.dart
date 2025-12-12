import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  bool _isLoading = false;
  bool _mustChangePassword = false;
  
  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get mustChangePassword => _mustChangePassword;

  final http.Client _client = http.Client();

  AuthProvider() {
    _tryAutoLogin();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _tryAutoLogin() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authData')) {
      _setLoading(false);
      return;
    }
    try {
      final extractedData =
          json.decode(prefs.getString('authData')!) as Map<String, dynamic>;
      _token = extractedData['token'] as String;
      _user = User.fromJson(extractedData['user'] as Map<String, dynamic>);
    } catch (e) {
      await prefs.remove('authData');
      _token = null;
      _user = null;
    }
    _setLoading(false);
  }

  Future<void> login(String identifier, String password) async {
    _setLoading(true);
    final url = Uri.parse('$API_BASE_URL/api/Auth/login');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['accessToken'];
        _user = User.fromJson(responseData['user']);
        _mustChangePassword = responseData['mustChangePassword'] ?? false;

        if (!_mustChangePassword) {
           final prefs = await SharedPreferences.getInstance();
           final authData = json.encode({
             'token': _token,
             'user': responseData['user'], 
           });
           await prefs.setString('authData', authData);
        }
        
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Falha no login');
      }
    } on SocketException {
      _setLoading(false);
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua rede e o IP da API.');
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _mustChangePassword = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authData');
    notifyListeners();
  }

  Future<void> changeInitialPassword(String newPassword) async {
     final url = Uri.parse('$API_BASE_URL/api/Auth/change-initial-password');
     try {
       final response = await _client.post(
         url,
         headers: {
           'Content-Type': 'application/json',
           'Authorization': 'Bearer $_token', 
         },
         body: json.encode({'newPassword': newPassword}),
       );

       if (response.statusCode == 200) {
         _mustChangePassword = false;
         await logout(); 
       } else {
         final errorData = json.decode(response.body);
         throw Exception(errorData['message'] ?? 'Erro ao alterar senha.');
       }
     } catch (e) {
       rethrow;
     }
  }

  Future<void> updateProfile(User updatedUser, {String? newPassword, String? currentPassword}) async {
    _setLoading(true);
    final url = Uri.parse('$API_BASE_URL/api/Users/me');
    try {
      final Map<String, dynamic> bodyData = {
        'nome': updatedUser.nome,
        'phone': updatedUser.phone,
        'escritorio': updatedUser.escritorio,
        'profile_image_base64': updatedUser.profileImageBase64,
      };

      if (newPassword != null && newPassword.isNotEmpty) {
        bodyData['password'] = newPassword;
        bodyData['current_password'] = currentPassword;
      }

      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(bodyData),
      );

      if (response.statusCode == 200) {
        _user = User.fromJson(json.decode(response.body));
        final prefs = await SharedPreferences.getInstance();
        final authData = json.encode({
          'token': _token,
          'user': json.decode(response.body),
        });
        await prefs.setString('authData', authData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Falha ao atualizar');
      }
    } on SocketException {
      _setLoading(false);
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua rede.');
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<List<User>> fetchAllUsers() async {
    final url = Uri.parse('$API_BASE_URL/api/Users');
    try {
      final response = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((data) => User.fromJson(data)).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Falha ao obter utilizadores');
      }
    } on SocketException {
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua rede.');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> adminUpdateUser(User updatedUser) async {
    final url = Uri.parse('$API_BASE_URL/api/Users/${updatedUser.id}');
    try {
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'username': updatedUser.username,
          'nome': updatedUser.nome,
          'email': updatedUser.email,
          'phone': updatedUser.phone,
          'cod_assessor': updatedUser.codAssessor,
          'role': updatedUser.role,
          'escritorio': updatedUser.escritorio,
          'profile_image_base64': updatedUser.profileImageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final updatedUserData = User.fromJson(json.decode(response.body));
        if (_user?.id == updatedUserData.id) {
          _user = updatedUserData;
          final prefs = await SharedPreferences.getInstance();
          final authData = json.encode({
            'token': _token,
            'user': json.decode(response.body),
          });
          await prefs.setString('authData', authData);
        }
        notifyListeners();
        return updatedUserData; 
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Falha ao atualizar');
      }
    } on SocketException {
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua rede.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$API_BASE_URL/api/Users');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Falha ao criar utilizador');
      }
    } on SocketException {
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua rede.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    final url = Uri.parse('$API_BASE_URL/api/Users/$id');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 204) { 
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Falha ao eliminar utilizador');
      }
    } on SocketException {
      throw Exception('Não foi possível ligar ao servidor. Verifique a sua rede.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$API_BASE_URL/api/Auth/forgot-password');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao solicitar redefinição.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final url = Uri.parse('$API_BASE_URL/api/Auth/reset-password');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao redefinir senha.');
      }
    } catch (e) {
      rethrow;
    }
  }
}