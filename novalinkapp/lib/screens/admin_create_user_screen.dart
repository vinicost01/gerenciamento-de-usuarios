import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  final _usernameController = TextEditingController();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _escritorioController = TextEditingController();
  final _codAssessorController = TextEditingController();
  
  String _selectedRole = 'user';
  String? _imageBase64;
  final List<String> _roles = ['admin', 'user'];

  final RegExp _passwordRegex = RegExp(r'^(?=.*[0-9])(?=.*[^a-zA-Z0-9]).{8,}$');

  @override
  void dispose() {
    _usernameController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _escritorioController.dispose();
    _codAssessorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(imageBytes);
      setState(() {
        _imageBase64 = base64String;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _imageBase64 = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final userData = {
      'username': _usernameController.text,
      'nome': _nomeController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'role': _selectedRole,
      'phone': _phoneController.text,
      'cod_assessor': _codAssessorController.text,
      'escritorio': _escritorioController.text,
      'profile_image_base64': _imageBase64,
    };

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .createUser(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
      imageProvider = MemoryImage(base64Decode(_imageBase64!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Usuário'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: imageProvider,
                        child: (imageProvider == null)
                            ? const Icon(Icons.person_add,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: -10,
                        child: Row(
                          children: [
                            Material(
                              color: Theme.of(context).colorScheme.primary,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.hardEdge,
                              child: InkWell(
                                onTap: _pickImage,
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.add_a_photo,
                                      size: 20, color: Colors.white),
                                ),
                              ),
                            ),
                            if (_imageBase64 != null)
                              Material(
                                color: Colors.red[700],
                                shape: const CircleBorder(),
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  onTap: _clearImage,
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.delete,
                                        size: 20, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text("Informações de Acesso", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username *', prefixIcon: Icon(Icons.account_circle)),
                  validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha Inicial *', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Obrigatório';
                    if (!_passwordRegex.hasMatch(value)) {
                      return 'Min. 8 caracteres, 1 número e 1 símbolo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role *', prefixIcon: Icon(Icons.security)),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),

                const SizedBox(height: 24),
                const Text("Dados Pessoais", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome Completo *', prefixIcon: Icon(Icons.badge)),
                  validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codAssessorController,
                  decoration: const InputDecoration(labelText: 'Cód. Assessor', prefixIcon: Icon(Icons.confirmation_number)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _escritorioController,
                  decoration: const InputDecoration(labelText: 'Escritório', prefixIcon: Icon(Icons.business)),
                ),

                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    child: const Text('CRIAR USUÁRIO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}