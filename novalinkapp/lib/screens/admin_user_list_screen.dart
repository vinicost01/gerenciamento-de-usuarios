import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import './admin_edit_user_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture =
          Provider.of<AuthProvider>(context, listen: false).fetchAllUsers();
    });
  }

  void _navigateToEditScreen(User user) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => AdminEditUserScreen(user: user),
      ),
    );
    if (result == true) {
      _loadUsers();
    }
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exluir Usuário'),
        content: Text('Tem a certeza que deseja excluir "${user.username}"? Esta ação é irreversível.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); 
              try {
                await Provider.of<AuthProvider>(context, listen: false).deleteUser(user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuário excluido com sucesso!'), backgroundColor: Colors.green),
                  );
                  _loadUsers(); 
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, index) {
              final user = users[index];
              final imageProvider = user.profileImage;
              final isCurrentUser = user.id == currentUserId;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withAlpha(50),
                    backgroundImage: imageProvider,
                    child: (imageProvider == null)
                        ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(user.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user.email} (Role: ${user.role})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () => _navigateToEditScreen(user),
                        tooltip: 'Editar',
                      ),
                      if (!isCurrentUser)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(user),
                          tooltip: 'Excluir',
                        ),
                    ],
                  ),
                  onTap: () {
                    _navigateToEditScreen(user);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}