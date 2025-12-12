import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/read_only_field.dart';
import './reset_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  late TextEditingController _phoneController;

  late User _user;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<AuthProvider>(context, listen: false).user!;
    
    String initialPhone = _user.phone ?? '';
    if (RegExp(r'^\d{11}$').hasMatch(initialPhone)) {
      initialPhone = '(${initialPhone.substring(0,2)}) ${initialPhone.substring(2,7)}-${initialPhone.substring(7)}';
    }

    _phoneController = TextEditingController(text: initialPhone);
    _imageBase64 = _user.profileImageBase64;
  }

  @override
  void dispose() {
    _phoneController.dispose();
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

  Future<void> _triggerPasswordReset() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .forgotPassword(_user.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código de verificação enviado para o seu email.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const ResetPasswordScreen()),
        );
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    
    final updatedUser = User(
      id: _user.id,
      username: _user.username,
      email: _user.email,
      role: _user.role,
      codAssessor: _user.codAssessor,
      nome: _user.nome,
      escritorio: _user.escritorio,
      phone: _phoneController.text,
      profileImageBase64: _imageBase64,
    );

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); 
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
    if (_imageBase64 != null) {
      imageProvider = MemoryImage(base64Decode(_imageBase64!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
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
                        right: 0,
                        child: Material(
                          color: Theme.of(context).colorScheme.primary,
                          clipBehavior: Clip.hardEdge,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _pickImage,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.edit,
                                  size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text("Dados do Utilizador", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ReadOnlyField(label: 'Username', value: _user.username),
                ReadOnlyField(label: 'Email', value: _user.email),
                ReadOnlyField(label: 'Role', value: _user.role),
                ReadOnlyField(label: 'Nome Completo', value: _user.nome),
                if (_user.escritorio != null)
                   ReadOnlyField(label: 'Escritório', value: _user.escritorio!),

                const SizedBox(height: 24),
                const Text("Campos Editáveis",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(xx) xxxxx-xxxx',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    PhoneInputFormatter(),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text("Segurança",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _triggerPasswordReset, 
                  icon: const Icon(Icons.lock_reset),
                  label: const Text("Redefinir Senha (Enviar Código)"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    foregroundColor: Colors.white, 
                  ),
                ),

                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
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

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (newText.length > 11) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(newText[i]);
    }
    final String formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}