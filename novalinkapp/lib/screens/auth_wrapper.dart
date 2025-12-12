import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import './home_screen.dart';
import './login_screen.dart';
import './change_initial_password_screen.dart'; 

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        if (auth.isLoading && auth.token == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAuthenticated) {
          if (auth.mustChangePassword) {
            return const ChangeInitialPasswordScreen();
          }
          return const HomeScreen();
        } 
        else {
          return const LoginScreen();
        }
      },
    );
  }
}