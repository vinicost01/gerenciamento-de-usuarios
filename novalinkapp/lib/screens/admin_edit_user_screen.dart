import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class AdminEditUserScreen extends StatefulWidget {
  final User user;
  const AdminEditUserScreen({super.key, required this.user});

  @override
  State<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TextEditingController _usernameController;
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _escritorioController;
  late TextEditingController _codAssessorController;
  String? _selectedRole;
  String? _imageBase64;
  final List<String> _roles = ['admin', 'user'];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _nomeController = TextEditingController(text: widget.user.nome);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _escritorioController = TextEditingController(text: widget.user.escritorio);
    _codAssessorController =
        TextEditingController(text: widget.user.codAssessor);
    _selectedRole = widget.user.role;
    _imageBase64 = widget.user.profileImageBase64;
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
      _imageBase64 = "";
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    final updatedUser = User(
      id: widget.user.id,
      username: _usernameController.text,
      nome: _nomeController.text,
      email: _emailController.text,
      role: _selectedRole!,
      codAssessor: _codAssessorController.text,
      phone: _phoneController.text,
      escritorio: _escritorioController.text,
      profileImageBase64: _imageBase64,
    );
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .adminUpdateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário atualizado com sucesso!'),
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
        title: Text('Editar ${widget.user.username}'),
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
                            ? const Icon(Icons.person,
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
                                  child: Icon(Icons.edit,
                                      size: 20, color: Colors.white),
                                ),
                              ),
                            ),
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
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) =>
                      value!.isEmpty ? 'Username é obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome Completo'),
                  validator: (value) =>
                      value!.isEmpty ? 'Nome é obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? 'Email é obrigatório' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Role é obrigatória' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codAssessorController,
                  decoration: const InputDecoration(labelText: 'Cód. Assessor'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _escritorioController,
                  decoration: const InputDecoration(labelText: 'Escritório'),
                ),

                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    child: const Text('Salvar Alterações'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}