import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../config/api.dart';
import '../../../services/auth_service.dart';
// ignore: unused_import
import '../screens/home/home_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({
    super.key,
  });

  @override
  State<CadastroScreen> createState() =>
      _CadastroScreenState();
}

class _CadastroScreenState
    extends State<CadastroScreen> {

  final nomeController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final telefoneController =
      TextEditingController();

  final cpfController =
      TextEditingController();

  final senhaController =
      TextEditingController();

  final veiculoController =
      TextEditingController();

  final placaController =
      TextEditingController();

  bool carregando = false;
  bool esconderSenha = true;

  String? erro;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    cpfController.dispose();
    senhaController.dispose();
    veiculoController.dispose();
    placaController.dispose();

    super.dispose();
  }

  Future<void> cadastrar() async {
    FocusScope.of(context).unfocus();

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final response = await http.post(
        Uri.parse(Api.register),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nome': nomeController.text.trim(),
          'email': emailController.text.trim(),
          'telefone':
              telefoneController.text.trim(),
          'cpf': cpfController.text.trim(),
          'senha': senhaController.text,
          'tipo': 'ENTREGADOR',
          'veiculo':
              veiculoController.text.trim(),
          'placa':
              placaController.text
                  .trim()
                  .toUpperCase(),
        }),
      );

      Map<String, dynamic> data = {};

      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          data['mensagem']?.toString() ??
              data['erro']?.toString() ??
              'Erro ao cadastrar.',
        );
      }

      final token =
          data['token']?.toString();

      if (token != null &&
          token.isNotEmpty) {
        final prefs =
            await AuthService.getToken();

        if (prefs != null) {
          // token já salvo caso o backend o retorne
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Entregador cadastrado com sucesso!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  InputDecoration campo(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastro de Entregador',
        ),
        backgroundColor:
            const Color(0xFFF97316),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller:
                  nomeController,
              decoration: campo(
                'Nome completo',
                Icons.person_outline,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: campo(
                'E-mail',
                Icons.email_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  telefoneController,
              keyboardType:
                  TextInputType.phone,
              decoration: campo(
                'Telefone',
                Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  cpfController,
              keyboardType:
                  TextInputType.number,
              decoration: campo(
                'CPF',
                Icons.badge_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  senhaController,
              obscureText:
                  esconderSenha,
              decoration:
                  campo(
                    'Senha',
                    Icons.lock_outline,
                  ).copyWith(
                suffixIcon:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      esconderSenha =
                          !esconderSenha;
                    });
                  },
                  icon: Icon(
                    esconderSenha
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  veiculoController,
              decoration: campo(
                'Veículo',
                Icons.two_wheeler,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  placaController,
              textCapitalization:
                  TextCapitalization
                      .characters,
              decoration: campo(
                'Placa',
                Icons.pin_outlined,
              ),
            ),

            if (erro != null) ...[
              const SizedBox(height: 16),
              Text(
                erro!,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    carregando
                        ? null
                        : cadastrar,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFFF97316,
                  ),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: carregando
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'CRIAR CONTA',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}