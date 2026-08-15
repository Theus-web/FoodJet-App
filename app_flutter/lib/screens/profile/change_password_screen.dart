import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final senhaAtualController =
      TextEditingController();

  final novaSenhaController =
      TextEditingController();

  final confirmarSenhaController =
      TextEditingController();

  final AuthService authService =
      AuthService();

  bool carregando = false;

  bool esconderSenhaAtual = true;
  bool esconderNovaSenha = true;
  bool esconderConfirmarSenha = true;

  static const Color laranja =
      Color(0xFFF97316);

  @override
  void dispose() {
    senhaAtualController.dispose();
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }

  // ==================================================
  // ALTERAR SENHA
  // ==================================================

  Future<void> alterarSenha() async {
    FocusScope.of(context).unfocus();

    final senhaAtual =
        senhaAtualController.text;

    final novaSenha =
        novaSenhaController.text;

    final confirmarSenha =
        confirmarSenhaController.text;

    // ==============================================
    // VALIDAR CAMPOS
    // ==============================================

    if (senhaAtual.isEmpty ||
        novaSenha.isEmpty ||
        confirmarSenha.isEmpty) {
      _mostrarMensagem(
        'Preencha todos os campos.',
        erro: true,
      );

      return;
    }

    // ==============================================
    // VALIDAR NOVA SENHA
    // ==============================================

    if (novaSenha.length < 6) {
      _mostrarMensagem(
        'A nova senha deve ter pelo menos 6 caracteres.',
        erro: true,
      );

      return;
    }

    // ==============================================
    // CONFIRMAR SENHA
    // ==============================================

    if (novaSenha != confirmarSenha) {
      _mostrarMensagem(
        'As novas senhas não coincidem.',
        erro: true,
      );

      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      // ==============================================
      // RECUPERAR TOKEN SALVO NO LOGIN
      // ==============================================

      final token =
          await authService.obterToken();

      if (token == null ||
          token.isEmpty) {
        if (!mounted) return;

        _mostrarMensagem(
          'Sessão expirada. Faça login novamente.',
          erro: true,
        );

        return;
      }

      print(
        'TOKEN ENCONTRADO PARA ALTERAR SENHA',
      );

      // ==============================================
      // CHAMAR API
      // ==============================================

      final resultado =
          await authService.alterarSenha(
        token: token,
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
      );

      if (!mounted) return;

      print(
        'RESPOSTA ALTERAR SENHA: $resultado',
      );

      final statusCode =
          resultado['statusCode'];

      // ==============================================
      // SUCESSO
      // ==============================================

      if (statusCode == 200) {
        _mostrarMensagem(
          resultado['mensagem']?.toString() ??
              'Senha alterada com sucesso.',
        );

        senhaAtualController.clear();
        novaSenhaController.clear();
        confirmarSenhaController.clear();

        await Future.delayed(
          const Duration(
            seconds: 1,
          ),
        );

        if (!mounted) return;

        Navigator.pop(context);

        return;
      }

      // ==============================================
      // ERRO DA API
      // ==============================================

      _mostrarMensagem(
        resultado['erro']?.toString() ??
            resultado['mensagem']?.toString() ??
            'Não foi possível alterar a senha.',
        erro: true,
      );
    } catch (e) {
      if (!mounted) return;

      print(
        'ERRO ALTERAR SENHA: $e',
      );

      _mostrarMensagem(
        'Erro ao conectar com o servidor.',
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

  // ==================================================
  // MOSTRAR MENSAGEM
  // ==================================================

  void _mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
            erro
                ? Colors.red
                : Colors.green,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ==================================================
  // DECORAÇÃO DOS CAMPOS
  // ==================================================

  InputDecoration _decoracao(
    String label,
    IconData icone,
    bool esconder,
    VoidCallback alternar,
  ) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(
        icone,
        color: laranja,
      ),

      suffixIcon: IconButton(
        icon: Icon(
          esconder
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: alternar,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color: laranja,
          width: 2,
        ),
      ),
    );
  }

  // ==================================================
  // TELA
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor:
            laranja,

        foregroundColor:
            Colors.white,

        elevation: 0,

        title: const Text(
          'Alterar senha',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          20,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(
              height: 10,
            ),

            // ==========================================
            // ÍCONE
            // ==========================================

            Center(
              child: Container(
                width: 80,
                height: 80,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.orange.shade50,

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons.lock_outline,
                  size: 42,
                  color: laranja,
                ),
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            const Text(
              'Altere sua senha',

              style:
                  TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.black,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Digite sua senha atual e escolha uma nova senha para sua conta FoodJet.',

              style:
                  TextStyle(
                fontSize: 15,
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==========================================
            // SENHA ATUAL
            // ==========================================

            TextField(
              controller:
                  senhaAtualController,

              obscureText:
                  esconderSenhaAtual,

              decoration:
                  _decoracao(
                'Senha atual',
                Icons.lock_outline,
                esconderSenhaAtual,
                () {
                  setState(() {
                    esconderSenhaAtual =
                        !esconderSenhaAtual;
                  });
                },
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // NOVA SENHA
            // ==========================================

            TextField(
              controller:
                  novaSenhaController,

              obscureText:
                  esconderNovaSenha,

              decoration:
                  _decoracao(
                'Nova senha',
                Icons.lock_reset_outlined,
                esconderNovaSenha,
                () {
                  setState(() {
                    esconderNovaSenha =
                        !esconderNovaSenha;
                  });
                },
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // CONFIRMAR SENHA
            // ==========================================

            TextField(
              controller:
                  confirmarSenhaController,

              obscureText:
                  esconderConfirmarSenha,

              decoration:
                  _decoracao(
                'Confirmar nova senha',
                Icons.verified_user_outlined,
                esconderConfirmarSenha,
                () {
                  setState(() {
                    esconderConfirmarSenha =
                        !esconderConfirmarSenha;
                  });
                },
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==========================================
            // BOTÃO
            // ==========================================

            SizedBox(
              width:
                  double.infinity,

              height: 55,

              child:
                  ElevatedButton(
                onPressed:
                    carregando
                        ? null
                        : alterarSenha,

                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      laranja,

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      Colors.orange
                          .shade200,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                ),

                child:
                    carregando
                        ? const SizedBox(
                            width: 24,
                            height: 24,

                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : const Text(
                            'ALTERAR SENHA',

                            style:
                                TextStyle(
                              fontSize:
                                  16,
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