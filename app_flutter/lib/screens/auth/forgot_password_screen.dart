import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../login/login_screen.dart';

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

  final emailController =
      TextEditingController();

  final codigoController =
      TextEditingController();

  final novaSenhaController =
      TextEditingController();

  final confirmarSenhaController =
      TextEditingController();

  bool carregando = false;

  bool codigoEnviado = false;

  bool codigoValidado = false;

  bool esconderNovaSenha = true;

  bool esconderConfirmacao = true;

  @override
  void dispose() {
    emailController.dispose();
    codigoController.dispose();
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            erro ? Colors.red.shade600 : Colors.green.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==========================================================
  // SOLICITAR CÓDIGO
  // ==========================================================

  Future<void> solicitarCodigo() async {
    final email =
        emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      mostrarMensagem(
        'Informe seu e-mail.',
        erro: true,
      );
      return;
    }

    if (!email.contains('@')) {
      mostrarMensagem(
        'Informe um e-mail válido.',
        erro: true,
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final resultado =
          await authService.recuperarSenha(email);

      if (!mounted) return;

      if (resultado['erro'] != null) {
        mostrarMensagem(
          resultado['erro'].toString(),
          erro: true,
        );
        return;
      }

      setState(() {
        codigoEnviado = true;
      });

      mostrarMensagem(
        resultado['mensagem']?.toString() ??
            'Código enviado para seu e-mail.',
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // VALIDAR CÓDIGO
  // ==========================================================

  Future<void> validarCodigo() async {
    final email =
        emailController.text.trim().toLowerCase();

    final codigo =
        codigoController.text.trim();

    if (codigo.length != 6) {
      mostrarMensagem(
        'Digite o código de 6 dígitos.',
        erro: true,
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final resultado =
          await authService.validarCodigoRecuperacao(
        email: email,
        codigo: codigo,
      );

      if (!mounted) return;

      if (resultado['erro'] != null) {
        mostrarMensagem(
          resultado['erro'].toString(),
          erro: true,
        );
        return;
      }

      setState(() {
        codigoValidado = true;
      });

      mostrarMensagem(
        'Código confirmado.',
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // REDEFINIR SENHA
  // ==========================================================

  Future<void> redefinirSenha() async {
    final email =
        emailController.text.trim().toLowerCase();

    final codigo =
        codigoController.text.trim();

    final novaSenha =
        novaSenhaController.text;

    final confirmarSenha =
        confirmarSenhaController.text;

    if (novaSenha.length < 6) {
      mostrarMensagem(
        'A senha deve ter pelo menos 6 caracteres.',
        erro: true,
      );
      return;
    }

    if (novaSenha != confirmarSenha) {
      mostrarMensagem(
        'As senhas não são iguais.',
        erro: true,
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final resultado =
          await authService.redefinirSenha(
        email: email,
        codigo: codigo,
        novaSenha: novaSenha,
      );

      if (!mounted) return;

      if (resultado['erro'] != null) {
        mostrarMensagem(
          resultado['erro'].toString(),
          erro: true,
        );
        return;
      }

      mostrarMensagem(
        'Senha alterada com sucesso!',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 1000,
        ),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // DECORAÇÃO DOS CAMPOS
  // ==========================================================

  InputDecoration campoDecoracao({
    required String hint,
    required IconData icone,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(
        icone,
        color: const Color(0xFFF97316),
      ),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFF97316),
          width: 1.5,
        ),
      ),
    );
  }

  // ==========================================================
  // BOTÃO
  // ==========================================================

  Widget botao({
    required String texto,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFF97316),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        child: carregando
            ? const SizedBox(
                width: 23,
                height: 23,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // INDICADOR DE ETAPA
  // ==========================================================

  Widget etapa({
    required int numero,
    required String titulo,
    required bool ativa,
    required bool concluida,
  }) {
    final cor = ativa || concluida
        ? const Color(0xFFF97316)
        : Colors.grey.shade300;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: concluida
                  ? const Color(0xFFF97316)
                  : ativa
                      ? const Color(0xFFFFF1E8)
                      : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: cor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: concluida
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    )
                  : Text(
                      '$numero',
                      style: TextStyle(
                        color: ativa
                            ? const Color(0xFFF97316)
                            : Colors.grey,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ativa || concluida
                  ? Colors.black87
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CARD PRINCIPAL
  // ==========================================================

  Widget cardPrincipal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Recuperar senha',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            codigoValidado
                ? 'Crie uma nova senha para sua conta.'
                : codigoEnviado
                    ? 'Digite o código que enviamos para seu e-mail.'
                    : 'Digite seu e-mail para receber um código de recuperação.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),

          // ================================================
          // ETAPAS
          // ================================================

          Row(
            children: [
              etapa(
                numero: 1,
                titulo: 'E-mail',
                ativa: !codigoEnviado,
                concluida: codigoEnviado,
              ),
              etapa(
                numero: 2,
                titulo: 'Código',
                ativa:
                    codigoEnviado &&
                    !codigoValidado,
                concluida: codigoValidado,
              ),
              etapa(
                numero: 3,
                titulo: 'Nova senha',
                ativa: codigoValidado,
                concluida: false,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ================================================
          // E-MAIL
          // ================================================

          Text(
            'E-mail',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: emailController,
            enabled: !codigoValidado,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.done,
            decoration: campoDecoracao(
              hint: 'seuemail@exemplo.com',
              icone:
                  Icons.email_outlined,
            ),
          ),

          // ================================================
          // ENVIAR
          // ================================================

          if (!codigoEnviado) ...[
            const SizedBox(height: 20),

            botao(
              texto: 'Enviar código',
              onPressed:
                  solicitarCodigo,
            ),
          ],

          // ================================================
          // CÓDIGO
          // ================================================

          if (codigoEnviado &&
              !codigoValidado) ...[
            const SizedBox(height: 22),

            Text(
              'Código de verificação',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  codigoController,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration:
                  campoDecoracao(
                hint: '000000',
                icone:
                    Icons.lock_outline,
              ).copyWith(
                counterText: '',
              ),
            ),

            const SizedBox(height: 18),

            botao(
              texto: 'Confirmar código',
              onPressed:
                  validarCodigo,
            ),

            const SizedBox(height: 10),

            Center(
              child: TextButton(
                onPressed: carregando
                    ? null
                    : () {
                        setState(() {
                          codigoEnviado =
                              false;
                          codigoController
                              .clear();
                        });
                      },
                child: const Text(
                  'Usar outro e-mail',
                  style: TextStyle(
                    color:
                        Color(0xFFF97316),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // ================================================
          // NOVA SENHA
          // ================================================

          if (codigoValidado) ...[
            const SizedBox(height: 22),

            Text(
              'Nova senha',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  novaSenhaController,
              obscureText:
                  esconderNovaSenha,
              decoration:
                  campoDecoracao(
                hint: 'Digite sua nova senha',
                icone:
                    Icons.lock_outline,
                suffixIcon:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      esconderNovaSenha =
                          !esconderNovaSenha;
                    });
                  },
                  icon: Icon(
                    esconderNovaSenha
                        ? Icons
                            .visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Confirmar nova senha',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  confirmarSenhaController,
              obscureText:
                  esconderConfirmacao,
              decoration:
                  campoDecoracao(
                hint: 'Digite novamente sua senha',
                icone:
                    Icons.lock_outline,
                suffixIcon:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      esconderConfirmacao =
                          !esconderConfirmacao;
                    });
                  },
                  icon: Icon(
                    esconderConfirmacao
                        ? Icons
                            .visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'A senha deve ter pelo menos 6 caracteres.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 22),

            botao(
              texto: 'Criar nova senha',
              onPressed:
                  redefinirSenha,
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Recuperar acesso',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            25,
            18,
            25,
          ),
          child: Column(
            children: [
              // =================================================
              // LOGO
              // =================================================

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF1E8),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 34,
                  color:
                      Color(0xFFF97316),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Proteja sua conta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Recupere o acesso à sua conta FoodJet',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 25),

              cardPrincipal(),

              const SizedBox(height: 18),

              TextButton(
                onPressed: carregando
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                        );
                      },
                child: const Text(
                  'Voltar para o login',
                  style: TextStyle(
                    color:
                        Color(0xFFF97316),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}