import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const SettingsScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificacoes = true;

  static const Color laranja = Color(0xFFF97316);

  // ==================================================
  // SERVIÇO DE AUTENTICAÇÃO
  // ==================================================

  final AuthService authService = AuthService();

  // ==================================================
  // DADOS PESSOAIS
  // ==================================================

  late String nome;
  late String telefone;
  late String email;

  @override
  void initState() {
    super.initState();

    nome =
        widget.usuario['nome']?.toString() ?? 'Usuário';

    final telefoneUsuario =
        widget.usuario['telefone']?.toString() ?? '';

    telefone = telefoneUsuario.isEmpty
        ? 'Telefone não informado'
        : telefoneUsuario;

    email =
        widget.usuario['email']?.toString() ??
        'E-mail não informado';
  }

  // ==================================================
  // ATUALIZAR NOME
  // ==================================================

  Future<void> _salvarNome(String novoNome) async {
    try {
      final token = await authService.obterToken();

      if (token == null || token.isEmpty) {
        _mensagem(
          'Sua sessão expirou. Faça login novamente.',
        );
        return;
      }

      final resultado =
          await authService.atualizarPerfil(
        token: token,
        nome: novoNome,
      );

      if (!mounted) return;

      final statusCode = resultado['statusCode'];

      if (statusCode == 200) {
        setState(() {
          nome = novoNome;
        });

        widget.usuario['nome'] = novoNome;

        _mensagem(
          'Nome atualizado e salvo com sucesso.',
        );
      } else {
        _mensagem(
          resultado['erro']?.toString() ??
              resultado['mensagem']?.toString() ??
              'Não foi possível atualizar o nome.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'ERRO AO ATUALIZAR NOME: $e',
      );

      _mensagem(
        'Não foi possível conectar ao servidor.',
      );
    }
  }

  // ==================================================
  // ATUALIZAR TELEFONE
  // ==================================================

  Future<void> _salvarTelefone(
    String novoTelefone,
  ) async {
    try {
      final token = await authService.obterToken();

      if (token == null || token.isEmpty) {
        _mensagem(
          'Sua sessão expirou. Faça login novamente.',
        );
        return;
      }

      final resultado =
          await authService.atualizarPerfil(
        token: token,
        telefone: novoTelefone,
      );

      if (!mounted) return;

      final statusCode = resultado['statusCode'];

      if (statusCode == 200) {
        setState(() {
          telefone = novoTelefone;
        });

        widget.usuario['telefone'] = novoTelefone;

        _mensagem(
          'Telefone atualizado e salvo com sucesso.',
        );
      } else {
        _mensagem(
          resultado['erro']?.toString() ??
              resultado['mensagem']?.toString() ??
              'Não foi possível atualizar o telefone.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'ERRO AO ATUALIZAR TELEFONE: $e',
      );

      _mensagem(
        'Não foi possível conectar ao servidor.',
      );
    }
  }

  // ==================================================
  // ATUALIZAR E-MAIL
  // ==================================================

  Future<void> _salvarEmail(
    String novoEmail,
  ) async {
    try {
      final token = await authService.obterToken();

      if (token == null || token.isEmpty) {
        _mensagem(
          'Sua sessão expirou. Faça login novamente.',
        );
        return;
      }

      final resultado =
          await authService.atualizarPerfil(
        token: token,
        email: novoEmail,
      );

      if (!mounted) return;

      final statusCode = resultado['statusCode'];

      if (statusCode == 200) {
        setState(() {
          email = novoEmail;
        });

        widget.usuario['email'] = novoEmail;

        _mensagem(
          'E-mail atualizado e salvo com sucesso.',
        );
      } else {
        _mensagem(
          resultado['erro']?.toString() ??
              resultado['mensagem']?.toString() ??
              'Não foi possível atualizar o e-mail.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'ERRO AO ATUALIZAR EMAIL: $e',
      );

      _mensagem(
        'Não foi possível conectar ao servidor.',
      );
    }
  }

  // ==================================================
  // ALTERAR SENHA
  // ==================================================

  Future<void> _salvarNovaSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    try {
      final token = await authService.obterToken();

      if (token == null || token.isEmpty) {
        _mensagem(
          'Sua sessão expirou. Faça login novamente.',
        );
        return;
      }

      final resultado =
          await authService.alterarSenha(
        token: token,
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
      );

      if (!mounted) return;

      final statusCode = resultado['statusCode'];

      if (statusCode == 200) {
        _mensagem(
          'Senha alterada com sucesso.',
        );
      } else {
        _mensagem(
          resultado['erro']?.toString() ??
              resultado['mensagem']?.toString() ??
              'Não foi possível alterar a senha.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'ERRO AO ALTERAR SENHA: $e',
      );

      _mensagem(
        'Não foi possível conectar ao servidor.',
      );
    }
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    // ==================================================
    // FOODJET SEMPRE NO TEMA CLARO
    // ==================================================

    const Color fundo = Color(0xFFF5F5F5);
    const Color card = Colors.white;
    const Color texto = Colors.black87;
    const Color textoSecundario = Colors.black54;
    const Color divisor = Colors.black12;

    return Scaffold(
      backgroundColor: fundo,

      // ==================================================
      // APP BAR
      // ==================================================

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Configurações',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ==================================================
      // CONTEÚDO
      // ==================================================

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ==================================================
          // DADOS PESSOAIS
          // ==================================================

          const Text(
            'Dados pessoais',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: texto,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                // ==================================================
                // NOME
                // ==================================================

                ListTile(
                  leading: _iconeDados(
                    Icons.person_outline,
                  ),
                  title: const Text(
                    'Nome',
                    style: TextStyle(
                      fontSize: 13,
                      color: textoSecundario,
                    ),
                  ),
                  subtitle: Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    color: textoSecundario,
                    size: 20,
                  ),
                  onTap: () {
                    _mostrarEditarDado(
                      titulo: 'Alterar nome',
                      label: 'Nome completo',
                      valorAtual: nome,
                      icone: Icons.person_outline,
                      aoSalvar: _salvarNome,
                    );
                  },
                ),

                const Divider(
                  height: 1,
                  color: divisor,
                ),

                // ==================================================
                // TELEFONE
                // ==================================================

                ListTile(
                  leading: _iconeDados(
                    Icons.phone_outlined,
                  ),
                  title: const Text(
                    'Telefone',
                    style: TextStyle(
                      fontSize: 13,
                      color: textoSecundario,
                    ),
                  ),
                  subtitle: Text(
                    telefone,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    color: textoSecundario,
                    size: 20,
                  ),
                  onTap: () {
                    _mostrarEditarDado(
                      titulo: 'Alterar telefone',
                      label: 'Número de telefone',
                      valorAtual: telefone,
                      icone: Icons.phone_outlined,
                      teclado: TextInputType.phone,
                      aoSalvar: _salvarTelefone,
                    );
                  },
                ),

                const Divider(
                  height: 1,
                  color: divisor,
                ),

                // ==================================================
                // E-MAIL
                // ==================================================

                ListTile(
                  leading: _iconeDados(
                    Icons.email_outlined,
                  ),
                  title: const Text(
                    'E-mail',
                    style: TextStyle(
                      fontSize: 13,
                      color: textoSecundario,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.edit_outlined,
                    color: textoSecundario,
                    size: 20,
                  ),
                  onTap: () {
                    _mostrarEditarDado(
                      titulo: 'Alterar e-mail',
                      label: 'E-mail',
                      valorAtual: email,
                      icone: Icons.email_outlined,
                      teclado: TextInputType.emailAddress,
                      aoSalvar: _salvarEmail,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ==================================================
          // PREFERÊNCIAS
          // ==================================================

          const Text(
            'Preferências',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: texto,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                // ==================================================
                // NOTIFICAÇÕES
                // ==================================================

                SwitchListTile(
                  value: notificacoes,
                  onChanged: (valor) {
                    setState(() {
                      notificacoes = valor;
                    });

                    _mensagem(
                      valor
                          ? 'Notificações ativadas.'
                          : 'Notificações desativadas.',
                    );
                  },
                  secondary: _iconeDados(
                    Icons.notifications_outlined,
                  ),
                  title: const Text(
                    'Notificações',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  subtitle: const Text(
                    'Receber notificações de pedidos e ofertas',
                    style: TextStyle(
                      color: textoSecundario,
                    ),
                  ),
                  activeColor: laranja,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ==================================================
          // CONTA
          // ==================================================

          const Text(
            'Conta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: texto,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                // ==================================================
                // ALTERAR SENHA
                // ==================================================

                ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: laranja,
                  ),
                  title: const Text(
                    'Alterar senha',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  subtitle: const Text(
                    'Altere a senha da sua conta',
                    style: TextStyle(
                      color: textoSecundario,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: textoSecundario,
                  ),
                  onTap: _mostrarAlterarSenha,
                ),

                const Divider(
                  height: 1,
                  color: divisor,
                ),

                // ==================================================
                // AJUDA
                // ==================================================

                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: laranja,
                  ),
                  title: const Text(
                    'Ajuda e suporte',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  subtitle: const Text(
                    'Precisa de ajuda com o FoodJet?',
                    style: TextStyle(
                      color: textoSecundario,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: textoSecundario,
                  ),
                  onTap: _mostrarAjudaSuporte,
                ),

                const Divider(
                  height: 1,
                  color: divisor,
                ),

                // ==================================================
                // SOBRE
                // ==================================================

                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: laranja,
                  ),
                  title: const Text(
                    'Sobre o FoodJet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: texto,
                    ),
                  ),
                  subtitle: const Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      color: textoSecundario,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: textoSecundario,
                  ),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'FoodJet',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 FoodJet',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ==================================================
          // RODAPÉ
          // ==================================================

          const Center(
            child: Text(
              'FoodJet • Delivery rápido e inteligente',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textoSecundario,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(
                color: textoSecundario,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==================================================
  // ÍCONE DOS DADOS
  // ==================================================

  Widget _iconeDados(
    IconData icone,
  ) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icone,
        color: laranja,
      ),
    );
  }

  // ==================================================
  // EDITAR DADO PESSOAL
  // ==================================================

  void _mostrarEditarDado({
    required String titulo,
    required String label,
    required String valorAtual,
    required IconData icone,
    required Future<void> Function(String) aoSalvar,
    TextInputType teclado = TextInputType.text,
  }) {
    final controller = TextEditingController(
      text: valorAtual,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: laranja,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: controller,
                  keyboardType: teclado,
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: label,
                    labelStyle: const TextStyle(
                      color: Colors.black54,
                    ),
                    prefixIcon: Icon(
                      icone,
                      color: laranja,
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(
                        color: laranja,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final valor =
                          controller.text.trim();

                      if (valor.isEmpty) {
                        _mensagem(
                          'Preencha o campo.',
                        );
                        return;
                      }

                      await aoSalvar(valor);

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: laranja,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Salvar alterações',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================================================
  // ALTERAR SENHA
  // ==================================================

  void _mostrarAlterarSenha() {
    final senhaAtualController =
        TextEditingController();

    final novaSenhaController =
        TextEditingController();

    final confirmarSenhaController =
        TextEditingController();

    bool mostrarSenhaAtual = false;
    bool mostrarNovaSenha = false;
    bool mostrarConfirmarSenha = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.lock_reset,
                        size: 45,
                        color: laranja,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Center(
                      child: Text(
                        'Alterar senha',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        'Digite seus dados para alterar sua senha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    _campoSenha(
                      controller:
                          senhaAtualController,
                      label: 'Senha atual',
                      mostrar: mostrarSenhaAtual,
                      aoAlternar: () {
                        setModalState(() {
                          mostrarSenhaAtual =
                              !mostrarSenhaAtual;
                        });
                      },
                      icone: Icons.lock_outline,
                    ),

                    const SizedBox(height: 15),

                    _campoSenha(
                      controller:
                          novaSenhaController,
                      label: 'Nova senha',
                      mostrar: mostrarNovaSenha,
                      aoAlternar: () {
                        setModalState(() {
                          mostrarNovaSenha =
                              !mostrarNovaSenha;
                        });
                      },
                      icone: Icons.lock_reset,
                    ),

                    const SizedBox(height: 15),

                    _campoSenha(
                      controller:
                          confirmarSenhaController,
                      label: 'Confirmar nova senha',
                      mostrar: mostrarConfirmarSenha,
                      aoAlternar: () {
                        setModalState(() {
                          mostrarConfirmarSenha =
                              !mostrarConfirmarSenha;
                        });
                      },
                      icone:
                          Icons.verified_user_outlined,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final senhaAtual =
                              senhaAtualController
                                  .text
                                  .trim();

                          final novaSenha =
                              novaSenhaController
                                  .text
                                  .trim();

                          final confirmar =
                              confirmarSenhaController
                                  .text
                                  .trim();

                          if (senhaAtual.isEmpty ||
                              novaSenha.isEmpty ||
                              confirmar.isEmpty) {
                            _mensagem(
                              'Preencha todos os campos.',
                            );
                            return;
                          }

                          if (novaSenha.length < 6) {
                            _mensagem(
                              'A nova senha deve ter pelo menos 6 caracteres.',
                            );
                            return;
                          }

                          if (novaSenha != confirmar) {
                            _mensagem(
                              'As senhas não conferem.',
                            );
                            return;
                          }

                          FocusScope.of(
                            context,
                          ).unfocus();

                          await _salvarNovaSenha(
                            senhaAtual: senhaAtual,
                            novaSenha: novaSenha,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          Navigator.pop(context);
                        },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: laranja,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Alterar senha',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================================================
  // CAMPO DE SENHA
  // ==================================================

  Widget _campoSenha({
    required TextEditingController controller,
    required String label,
    required bool mostrar,
    required VoidCallback aoAlternar,
    required IconData icone,
  }) {
    return TextField(
      controller: controller,
      obscureText: !mostrar,
      style: const TextStyle(
        color: Colors.black,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black54,
        ),
        prefixIcon: Icon(
          icone,
          color: laranja,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            mostrar
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: aoAlternar,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.grey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: laranja,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ==================================================
  // AJUDA E SUPORTE
  // ==================================================

  void _mostrarAjudaSuporte() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajuda e suporte',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Como podemos ajudar?',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              _itemAjuda(
                Icons.receipt_long_outlined,
                'Problemas com meu pedido',
                () {
                  Navigator.pop(context);

                  _mensagem(
                    'Em breve você poderá falar sobre seu pedido.',
                  );
                },
              ),

              _itemAjuda(
                Icons.payment_outlined,
                'Problemas com pagamento',
                () {
                  Navigator.pop(context);

                  _mensagem(
                    'Suporte de pagamento selecionado.',
                  );
                },
              ),

              _itemAjuda(
                Icons.account_circle_outlined,
                'Problemas com minha conta',
                () {
                  Navigator.pop(context);

                  _mensagem(
                    'Suporte da conta selecionado.',
                  );
                },
              ),

              _itemAjuda(
                Icons.chat_outlined,
                'Falar com o suporte',
                () {
                  Navigator.pop(context);

                  _mensagem(
                    'Em breve o atendimento do FoodJet estará disponível.',
                  );
                },
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  // ==================================================
  // ITEM DE AJUDA
  // ==================================================

  Widget _itemAjuda(
    IconData icone,
    String titulo,
    VoidCallback aoClicar,
  ) {
    return ListTile(
      onTap: aoClicar,
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icone,
          color: laranja,
        ),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }

  // ==================================================
  // MENSAGEM
  // ==================================================

  void _mensagem(
    String mensagem,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          duration: const Duration(
            seconds: 3,
          ),
        ),
      );
  }
}