import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suporte',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _card(
            context,
            Icons.chat_bubble_outline_rounded,
            'Falar com suporte',
            'Entre em contato com a equipe FoodJet.',
          ),
          _card(
            context,
            Icons.help_outline_rounded,
            'Central de ajuda',
            'Veja respostas para dúvidas frequentes.',
          ),
          _card(
            context,
            Icons.sos_rounded,
            'Emergência',
            'Acione o suporte e compartilhe sua localização.',
            danger: true,
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: (danger
                  ? FoodJetColors.red
                  : FoodJetColors.orange)
              .withOpacity(.1),
          child: Icon(
            icon,
            color: danger
                ? FoodJetColors.red
                : FoodJetColors.orange,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
