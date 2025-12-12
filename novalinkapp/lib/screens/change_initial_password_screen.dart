import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChangeInitialPasswordScreen extends StatefulWidget {
  const ChangeInitialPasswordScreen({super.key});

  @override
  State<ChangeInitialPasswordScreen> createState() => _ChangeInitialPasswordScreenState();
}

class _ChangeInitialPasswordScreenState extends State<ChangeInitialPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final RegExp _passwordRegex = RegExp(r'^(?=.*[0-9])(?=.*[^a-zA-Z0-9]).{8,}$');

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .changeInitialPassword(_newPasswordController.text);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Sucesso'),
            content: const Text('Senha alterada com sucesso! Por favor, faça login novamente com a nova senha.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); 
                  Navigator.of(context).pop(); 
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alterar Senha Provisória'),
        automaticallyImplyLeading: false, 
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              const Text(
                "Ação Necessária",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Esta é a sua primeira vez a aceder ou a sua senha expirou. Por segurança, deve definir uma nova senha agora.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Mín. 8 caracteres, 1 número, 1 símbolo',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obrigatório';
                  if (!_passwordRegex.hasMatch(value)) {
                    return 'Senha fraca (min 8 chars, 1 num, 1 simbolo)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Nova Senha',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) => value!.isEmpty ? 'Obrigatório' : null,
              ),
              
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('DEFINIR NOVA SENHA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}