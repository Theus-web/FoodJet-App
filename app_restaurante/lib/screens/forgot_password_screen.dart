import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import 'verify_recovery_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final AuthService authService = AuthService();

  final TextEditingController emailController =
      TextEditingController();

  bool enviando = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> recuperarSenha() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite seu email."),
        ),
      );
      return;
    }

    if (!email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite um email válido."),
        ),
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      await authService.solicitarRecuperacao(
        email: email,
      );

      if (!mounted) return;

      // Vai para a tela onde o usuário digita
      // o código recebido por email.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyRecoveryCodeScreen(
            email: email,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = e
          .toString()
          .replaceFirst("Exception: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Container(
            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Column(
              children: [
                // ÍCONE
                Container(
                  height: 90,
                  width: 90,

                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316),
                    borderRadius:
                        BorderRadius.circular(25),
                  ),

                  child: const Icon(
                    Icons.lock_reset,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 25),

                // TÍTULO
                const Text(
                  "Recuperar senha",

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Digite seu email para receber\n"
                  "um código de recuperação.",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                // EMAIL
                TextField(
                  controller: emailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: InputDecoration(
                    labelText: "Email",

                    hintText:
                        "Digite seu email",

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFF97316),
                    ),

                    filled: true,

                    fillColor:
                        const Color(0xfff8f8f8),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),

                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // BOTÃO
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF97316),

                      disabledBackgroundColor:
                          Colors.orange.shade200,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),

                    onPressed:
                        enviando
                            ? null
                            : recuperarSenha,

                    child: enviando
                        ? const SizedBox(
                            height: 25,
                            width: 25,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "ENVIAR CÓDIGO",

                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // VOLTAR
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Voltar para login",

                    style: TextStyle(
                      color: Color(0xFFF97316),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}