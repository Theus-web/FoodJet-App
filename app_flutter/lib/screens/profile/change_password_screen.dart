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
  final TextEditingController senhaAtualController =
      TextEditingController();

  final TextEditingController novaSenhaController =
      TextEditingController();

  final TextEditingController confirmarSenhaController =
      TextEditingController();

  final AuthService authService = AuthService();

  bool carregando = false;

  bool esconderSenhaAtual = true;
  bool esconderNovaSenha = true;
  bool esconderConfirmarSenha = true;

  static const Color laranja = Color(0xFFF97316);

  @override
  void dispose() {
    senhaAtualController.dispose();
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }

  // ============================================================
  // ALTERAR SENHA
  // ============================================================

  Future<void> alterarSenha() async {
    FocusScope.of(context).unfocus();

    final senhaAtual =
        senhaAtualController.text.trim();

    final novaSenha =
        novaSenhaController.text;

    final confirmarSenha =
        confirmarSenhaController.text;

    // ==========================================================
    // VALIDAR CAMPOS
    // ==========================================================

    if (senhaAtual.isEmpty ||
        novaSenha.isEmpty ||
        confirmarSenha.isEmpty) {
      _mostrarMensagem(
        'Preencha todos os campos.',
        erro: true,
      );
      return;
    }

    // ==========================================================
    // VALIDAR NOVA SENHA
    // ==========================================================

    if (novaSenha.length < 6) {
      _mostrarMensagem(
        'A nova senha deve ter pelo menos 6 caracteres.',
        erro: true,
      );
      return;
    }

    // ==========================================================
    // CONFIRMAR SENHA
    // ==========================================================

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
      // ========================================================
      // VERIFICAR SESSÃO
      // ========================================================

      final token = await authService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        _mostrarMensagem(
          'Sessão expirada. Faça login novamente.',
          erro: true,
        );

        return;
      }

      // ========================================================
      // ALTERAR SENHA
      // ========================================================

      final resultado =
          await authService.alterarSenha(
        token: token,
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
      );

      if (!mounted) return;

      // ========================================================
      // SUCESSO
      // ========================================================

      _mostrarMensagem(
        resultado['mensagem']?.toString() ??
            'Senha alterada com sucesso.',
      );

      senhaAtualController.clear();
      novaSenhaController.clear();
      confirmarSenhaController.clear();

      await Future.delayed(
        const Duration(
          milliseconds: 1000,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      String mensagem = e.toString();

      if (mensagem.startsWith('Exception: ')) {
        mensagem = mensagem.substring(
          'Exception: '.length,
        );
      }

      _mostrarMensagem(
        mensagem.isEmpty
            ? 'Não foi possível alterar a senha.'
            : mensagem,
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

  // ============================================================
  // MOSTRAR MENSAGEM
  // ============================================================

  void _mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
            erro ? Colors.red : Colors.green,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // DECORAÇÃO DOS CAMPOS
  // ============================================================

  InputDecoration _decoracao(
    String label,
    IconData icone,
    bool esconder,
    VoidCallback alternar,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
      ),
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
        color: Colors.grey.shade600,
        onPressed: alternar,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: laranja,
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO DE SENHA
  // ============================================================

  Widget _campoSenha({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    required bool esconder,
    required VoidCallback alternar,
  }) {
    return TextField(
      controller: controller,
      obscureText: esconder,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      decoration: _decoracao(
        label,
        icone,
        esconder,
        alternar,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // ÍCONE
              // ==================================================

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
                    Icons.lock_reset,
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
                  height: 1.4,
                  color:
                      Colors.black87,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // SENHA ATUAL
              // ==================================================

              _campoSenha(
                controller:
                    senhaAtualController,
                label:
                    'Senha atual',
                icone:
                    Icons.lock_outline,
                esconder:
                    esconderSenhaAtual,
                alternar: () {
                  setState(() {
                    esconderSenhaAtual =
                        !esconderSenhaAtual;
                  });
                },
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // NOVA SENHA
              // ==================================================

              _campoSenha(
                controller:
                    novaSenhaController,
                label:
                    'Nova senha',
                icone:
                    Icons.lock_reset_outlined,
                esconder:
                    esconderNovaSenha,
                alternar: () {
                  setState(() {
                    esconderNovaSenha =
                        !esconderNovaSenha;
                  });
                },
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'A senha deve ter pelo menos 6 caracteres.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // CONFIRMAR SENHA
              // ==================================================

              _campoSenha(
                controller:
                    confirmarSenhaController,
                label:
                    'Confirmar nova senha',
                icone:
                    Icons.verified_user_outlined,
                esconder:
                    esconderConfirmarSenha,
                alternar: () {
                  setState(() {
                    esconderConfirmarSenha =
                        !esconderConfirmarSenha;
                  });
                },
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // BOTÃO
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height:
                    55,
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
                    elevation: 0,
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
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // AVISO DE SEGURANÇA
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  15,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.orange.shade100,
                  ),
                ),

                child:
                    Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons
                          .security_outlined,
                      color:
                          laranja,
                      size: 22,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        'Nunca compartilhe sua senha com outras pessoas.',
                        style:
                            TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}