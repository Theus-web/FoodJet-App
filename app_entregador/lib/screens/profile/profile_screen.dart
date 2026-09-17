
import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu perfil',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: FoodJetColors.orange,
              ),
            );
          }

          final user = snapshot.data ?? <String, dynamic>{};

          final nome = _stringValue(
            user['nome'] ??
                user['name'] ??
                user['nome_completo'],
          );

          final email = _stringValue(
            user['email'],
          );

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: FoodJetColors.dark,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: FoodJetColors.orange,
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nome.isEmpty ? 'Entregador' : nome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _item(
                Icons.badge_outlined,
                'Dados pessoais',
              ),
              _item(
                Icons.two_wheeler_outlined,
                'Veículo',
              ),
              _item(
                Icons.description_outlined,
                'Documentos',
              ),
              _item(
                Icons.account_balance_outlined,
                'Dados bancários',
              ),
              _item(
                Icons.support_agent_rounded,
                'Suporte',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => logout(context),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: FoodJetColors.red,
                ),
                label: const Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: FoodJetColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';

    return value.toString().trim();
  }

  Widget _item(
    IconData icon,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: FoodJetColors.orange,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
      ),
    );
  }
}

