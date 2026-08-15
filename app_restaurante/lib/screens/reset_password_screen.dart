import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String codigo;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.codigo,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {

  final AuthService authService = AuthService();

  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool carregando = false;

  bool mostrarSenha = false;
  bool mostrarConfirmacao = false;

  @override
  void dispose() {
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> redefinirSenha() async {
    final senha = senhaController.text;
    final confirmarSenha = confirmarSenhaController.text;

    if (senha.isEmpty || confirmarSenha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha todos os campos."),
        ),
      );

      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "A senha deve ter pelo menos 6 caracteres.",
          ),
        ),
      );

      return;
    }

    if (senha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "As senhas não são iguais.",
          ),
        ),
      );

      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await authService.redefinirSenha(
        email: widget.email,
        codigo: widget.codigo,
        novaSenha: senha,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Senha alterada com sucesso!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

        title: const Text(
          "Nova senha",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Container(
            width: double.infinity,

            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(28),

              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: 0.08),

                  blurRadius: 25,

                  offset:
                      const Offset(0, 10),
                ),
              ],
            ),

            child: Column(
              children: [

                Container(
                  height: 90,
                  width: 90,

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF97316),

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

                const Text(
                  "Criar nova senha",
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Digite sua nova senha abaixo",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: senhaController,

                  obscureText:
                      !mostrarSenha,

                  decoration: InputDecoration(
                    labelText: "Nova senha",

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color:
                          Color(0xFFF97316),
                    ),

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          mostrarSenha =
                              !mostrarSenha;
                        });
                      },

                      icon: Icon(
                        mostrarSenha
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),

                    filled: true,

                    fillColor:
                        const Color(0xfff8f8f8),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),

                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller:
                      confirmarSenhaController,

                  obscureText:
                      !mostrarConfirmacao,

                  decoration: InputDecoration(
                    labelText:
                        "Confirmar nova senha",

                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,
                      color:
                          Color(0xFFF97316),
                    ),

                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          mostrarConfirmacao =
                              !mostrarConfirmacao;
                        });
                      },

                      icon: Icon(
                        mostrarConfirmacao
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),

                    filled: true,

                    fillColor:
                        const Color(0xfff8f8f8),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),

                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,

                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                        carregando
                            ? null
                            : redefinirSenha,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF97316),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),

                    child: carregando
                        ? const CircularProgressIndicator(
                            color:
                                Colors.white,
                          )
                        : const Text(
                            "ALTERAR SENHA",

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  17,

                              fontWeight:
                                  FontWeight.bold,
                            ),
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