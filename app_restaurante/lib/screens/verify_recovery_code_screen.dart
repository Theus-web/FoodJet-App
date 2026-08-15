import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import 'reset_password_screen.dart';

class VerifyRecoveryCodeScreen extends StatefulWidget {
  final String email;

  const VerifyRecoveryCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyRecoveryCodeScreen> createState() =>
      _VerifyRecoveryCodeScreenState();
}

class _VerifyRecoveryCodeScreenState
    extends State<VerifyRecoveryCodeScreen> {
  final AuthService authService = AuthService();

  final TextEditingController codigoController =
      TextEditingController();

  bool verificando = false;

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  // ============================================================
  // VERIFICAR CÓDIGO
  // ============================================================

  Future<void> verificarCodigo() async {
    final codigo = codigoController.text.trim();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Digite o código recebido por email.",
          ),
        ),
      );

      return;
    }

    if (codigo.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "O código deve ter 6 números.",
          ),
        ),
      );

      return;
    }

    setState(() {
      verificando = true;
    });

    try {
      // ========================================================
      // VALIDA O CÓDIGO NO BACKEND
      // ========================================================

      await authService.validarCodigoRecuperacao(
        email: widget.email,
        codigo: codigo,
      );

      if (!mounted) return;

      // ========================================================
      // CÓDIGO CORRETO
      // ABRE TELA DE NOVA SENHA
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            codigo: codigo,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = e
          .toString()
          .replaceFirst(
            "Exception: ",
            "",
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          verificando = false;
        });
      }
    }
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Container(
            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(28),

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
                // ==================================================
                // ÍCONE
                // ==================================================

                Container(
                  height: 90,
                  width: 90,

                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF97316,
                    ),

                    borderRadius:
                        BorderRadius.circular(25),
                  ),

                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // TÍTULO
                // ==================================================

                const Text(
                  "Digite o código",

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // EMAIL
                // ==================================================

                Text(
                  "Enviamos um código de 6 números\n"
                  "para:\n${widget.email}",

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // CAMPO CÓDIGO
                // ==================================================

                TextField(
                  controller: codigoController,

                  keyboardType:
                      TextInputType.number,

                  maxLength: 6,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),

                  decoration: InputDecoration(
                    counterText: "",

                    labelText: "Código",

                    hintText: "000000",

                    prefixIcon: const Icon(
                      Icons.password,
                      color: Color(
                        0xFFF97316,
                      ),
                    ),

                    filled: true,

                    fillColor: const Color(
                      0xfff8f8f8,
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),

                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // BOTÃO VERIFICAR
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFF97316,
                      ),

                      disabledBackgroundColor:
                          Colors.orange.shade200,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),

                    onPressed:
                        verificando
                            ? null
                            : verificarCodigo,

                    child: verificando
                        ? const SizedBox(
                            height: 25,
                            width: 25,

                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "VERIFICAR CÓDIGO",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // ==================================================
                // VOLTAR
                // ==================================================

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Voltar",

                    style: TextStyle(
                      color: Color(
                        0xFFF97316,
                      ),

                      fontWeight:
                          FontWeight.bold,
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