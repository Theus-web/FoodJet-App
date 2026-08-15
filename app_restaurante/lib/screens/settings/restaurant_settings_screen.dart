import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/restaurant_provider.dart';
import '../../services/restaurant_service.dart';
import '../../core/services/auth_service.dart';
import '../login_screen.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState
    extends State<RestaurantSettingsScreen> {
  // ============================================================
  // CORES
  // ============================================================

  static const Color laranja = Color(0xFFF97316);
  static const Color laranjaEscuro = Color(0xFFEA580C);
  static const Color fundo = Color(0xFFF6F7F9);
  static const Color texto = Color(0xFF171717);
  static const Color textoSecundario = Color(0xFF6B7280);
  static const Color vermelho = Color(0xFFDC2626);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final telefoneController = TextEditingController();
  final enderecoController = TextEditingController();

  // ============================================================
  // SERVICES
  // ============================================================

  final RestaurantService service = RestaurantService();
  final AuthService authService = AuthService();

  // ============================================================
  // ESTADO
  // ============================================================

  bool carregando = true;
  bool salvando = false;
  bool excluindoConta = false;
  bool saindo = false;
  bool aberto = true;

  String restauranteId = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarRestaurante();
    });
  }

  // ============================================================
  // CARREGAR RESTAURANTE
  // ============================================================

  Future<void> carregarRestaurante() async {
    try {
      final provider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      restauranteId = provider.restauranteId ?? '';

      if (restauranteId.isEmpty) {
        restauranteId =
            await authService.obterRestauranteId() ?? '';
      }

      if (restauranteId.isEmpty) {
        if (!mounted) return;

        setState(() {
          carregando = false;
        });

        _mostrarMensagem(
          'Restaurante não identificado.',
          erro: true,
        );

        return;
      }

      final dados =
          await service.buscarRestaurante(restauranteId);

      if (!mounted) return;

      final status =
          dados['status']?.toString().toUpperCase();

      setState(() {
        nomeController.text =
            dados['nome']?.toString() ?? '';

        descricaoController.text =
            dados['descricao']?.toString() ?? '';

        telefoneController.text =
            dados['telefone']?.toString() ?? '';

        enderecoController.text =
            dados['endereco']?.toString() ?? '';

        if (status == 'ABERTO') {
          aberto = true;
        } else if (status == 'FECHADO') {
          aberto = false;
        } else if (dados['aberto'] is bool) {
          aberto = dados['aberto'] as bool;
        } else {
          aberto = true;
        }

        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível carregar os dados do restaurante.',
        erro: true,
      );
    }
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<void> salvarConfiguracoes() async {
    if (salvando) return;

    if (restauranteId.isEmpty) {
      restauranteId =
          await authService.obterRestauranteId() ?? '';
    }

    if (restauranteId.isEmpty) {
      _mostrarMensagem(
        'Restaurante não identificado.',
        erro: true,
      );
      return;
    }

    if (nomeController.text.trim().isEmpty) {
      _mostrarMensagem(
        'Informe o nome do restaurante.',
        erro: true,
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final dados = {
        'nome': nomeController.text.trim(),
        'descricao': descricaoController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'endereco': enderecoController.text.trim(),
        'aberto': aberto,
      };

      await service.atualizarRestaurante(
        restauranteId,
        dados,
      );

      await service.alterarStatus(
        restauranteId,
        aberto ? 'ABERTO' : 'FECHADO',
      );

      if (!mounted) return;

      setState(() {
        salvando = false;
      });

      _mostrarMensagem(
        'Configurações salvas com sucesso!',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        salvando = false;
      });

      _mostrarMensagem(
        'Erro ao salvar as configurações.',
        erro: true,
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _confirmarLogout() async {
    if (saindo) return;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: laranja,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sair da conta?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Você será desconectado desta conta do restaurante. '
            'Será necessário fazer login novamente para acessar o FoodJet.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: textoSecundario,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: laranja,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sair',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await _logout();
  }

  // ============================================================
  // EXECUTAR LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (saindo) return;

    setState(() {
      saindo = true;
    });

    try {
      await authService.logout();

      if (!mounted) return;

      try {
        final provider = Provider.of<RestaurantProvider>(
          context,
          listen: false,
        );

        provider.limpar();
      } catch (_) {
        // O logout continua mesmo se o Provider não puder ser limpo.
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saindo = false;
      });

      _mostrarMensagem(
        'Não foi possível sair da conta.',
        erro: true,
      );
    }
  }
   
   

  // ============================================================
  // CONFIRMAÇÃO DE EXCLUSÃO
  // ============================================================

  Future<void> _confirmarExclusaoConta() async {
    if (excluindoConta) return;

    final primeiraConfirmacao = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: vermelho,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Excluir conta?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Essa ação encerrará a conta do restaurante no FoodJet e iniciará a exclusão dos dados vinculados.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: textoSecundario,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: vermelho,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (primeiraConfirmacao != true) return;

    if (!mounted) return;

    await _segundaConfirmacao();
  }

  // ============================================================
  // SEGUNDA CONFIRMAÇÃO
  // ============================================================

  Future<void> _segundaConfirmacao() async {
    final segundaConfirmacao = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Tem certeza?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      color: vermelho,
                      size: 23,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A conta será encerrada.',
                        style: TextStyle(
                          color: vermelho,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Você perderá o acesso ao restaurante e aos recursos da plataforma.',
                  style: TextStyle(
                    color: Color(0xFF7F1D1D),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Produtos, dados vinculados e outros registros que puderem ser eliminados serão excluídos pelo servidor.',
                  style: TextStyle(
                    color: Color(0xFF7F1D1D),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Registros que precisem ser mantidos por obrigação legal poderão permanecer armazenados pelo período necessário.',
                  style: TextStyle(
                    color: Color(0xFF7F1D1D),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Não, cancelar',
                style: TextStyle(
                  color: textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: vermelho,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Excluir minha conta',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (segundaConfirmacao != true) return;

    await _excluirConta();
  }

  // ============================================================
  // EXCLUIR CONTA COMPLETAMENTE
  // ============================================================

  Future<void> _excluirConta() async {
  if (excluindoConta) return;

  setState(() {
    excluindoConta = true;
  });

  try {
    String? id;

    // ============================================================
    // 1. PEGAR ID PELO PROVIDER
    // ============================================================

    try {
      final provider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      final providerId = provider.restauranteId;

      if (providerId != null &&
          providerId.toString().trim().isNotEmpty) {
        id = providerId.toString().trim();

        debugPrint(
          '🟠 ID pelo Provider: $id',
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ Erro ao obter ID pelo Provider: $e',
      );
    }

    // ============================================================
    // 2. PEGAR ID PELA SESSÃO
    // ============================================================

    if (id == null || id.isEmpty) {
      try {
        final sessionId =
            await authService.obterRestauranteId();

        if (sessionId != null &&
            sessionId.toString().trim().isNotEmpty) {
          id = sessionId.toString().trim();

          debugPrint(
            '🟢 ID pela sessão: $id',
          );
        }
      } catch (e) {
        debugPrint(
          '⚠️ Erro ao obter ID da sessão: $e',
        );
      }
    }

    // ============================================================
    // 3. PEGAR ID PELO RESTAURANTE SALVO
    // ============================================================

    if (id == null || id.isEmpty) {
      try {
        final restaurante =
            await authService.buscarRestauranteSessao();

        if (restaurante != null) {
          final valor = restaurante['id'];

          if (valor != null &&
              valor.toString().trim().isNotEmpty) {
            id = valor.toString().trim();

            debugPrint(
              '🔵 ID pelo restaurante salvo: $id',
            );
          }
        }
      } catch (e) {
        debugPrint(
          '⚠️ Erro ao buscar restaurante salvo: $e',
        );
      }
    }

    // ============================================================
    // 4. PEGAR ID PELO USUÁRIO
    // ============================================================

    if (id == null || id.isEmpty) {
      try {
        final usuario =
            await authService.obterUsuario();

        if (usuario != null) {
          final campos = [
            'restauranteId',
            'restaurantId',
            'restaurante_id',
          ];

          for (final campo in campos) {
            final valor = usuario[campo];

            if (valor != null &&
                valor.toString().trim().isNotEmpty) {
              id = valor.toString().trim();

              debugPrint(
                '🟣 ID pelo usuário [$campo]: $id',
              );

              break;
            }
          }
        }
      } catch (e) {
        debugPrint(
          '⚠️ Erro ao obter usuário: $e',
        );
      }
    }

    // ============================================================
    // 5. VALIDAR ID
    // ============================================================

    final idFinal = id?.trim();

    if (idFinal == null || idFinal.isEmpty) {
      throw Exception(
        'Não foi possível identificar o restaurante da conta atual.',
      );
    }

    restauranteId = idFinal;

    debugPrint('====================================');
    debugPrint('🗑️ EXCLUSÃO DE CONTA');
    debugPrint('🏪 RESTAURANTE: $restauranteId');
    debugPrint('====================================');

    // ============================================================
    // 6. EXCLUIR NO BACKEND
    // ============================================================

    final sucesso = await service.excluirConta(
      restauranteId,
    );

    debugPrint(
      '📡 Resultado da exclusão: $sucesso',
    );

    if (!sucesso) {
      throw Exception(
        'O servidor não confirmou a exclusão da conta.',
      );
    }

    debugPrint(
      '✅ Conta excluída no servidor.',
    );

    // ============================================================
    // 7. LIMPAR PROVIDER
    // ============================================================

    try {
      if (mounted) {
        final provider =
            Provider.of<RestaurantProvider>(
          context,
          listen: false,
        );

        provider.limpar();

        debugPrint(
          '✅ RestaurantProvider limpo.',
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ Erro ao limpar Provider: $e',
      );
    }

    // ============================================================
    // 8. LIMPAR SESSÃO
    // ============================================================

    try {
      await authService.logout();

      debugPrint(
        '✅ SharedPreferences/session limpos.',
      );
    } catch (e) {
      debugPrint(
        '⚠️ Erro ao fazer logout: $e',
      );
    }

    // ============================================================
    // 9. IR PARA LOGIN
    // ============================================================

    if (!mounted) return;

    debugPrint(
      '🚀 Indo para LoginScreen...',
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  } catch (e) {
    debugPrint('====================================');
    debugPrint('❌ ERRO NA EXCLUSÃO');
    debugPrint(e.toString());
    debugPrint('====================================');

    if (!mounted) return;

    setState(() {
      excluindoConta = false;
    });

    _mostrarMensagem(
      e.toString().replaceFirst(
        'Exception: ',
        '',
      ),
      erro: true,
    );
  }
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: texto,
        title: const Text(
          'Configurações',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed:
                carregando ? null : carregarRestaurante,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: laranja,
              ),
            )
          : RefreshIndicator(
              color: laranja,
              onRefresh: carregarRestaurante,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  40,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _cabecalho(),

                    const SizedBox(height: 24),

                    _tituloSecao(
                      'Informações do restaurante',
                      'Mantenha os dados do estabelecimento atualizados.',
                      Icons.restaurant_rounded,
                    ),

                    const SizedBox(height: 12),

                    _card(
                      child: Column(
                        children: [
                          _campo(
                            controller: nomeController,
                            label: 'Nome do restaurante',
                            hint: 'Ex.: Pizzaria do João',
                            icon: Icons.storefront_rounded,
                          ),
                          const SizedBox(height: 14),
                          _campo(
                            controller: descricaoController,
                            label: 'Descrição',
                            hint:
                                'Conte um pouco sobre seu restaurante',
                            icon:
                                Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 14),
                          _campo(
                            controller: telefoneController,
                            label: 'Telefone',
                            hint: '(00) 00000-0000',
                            icon: Icons.phone_rounded,
                            keyboardType:
                                TextInputType.phone,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _tituloSecao(
                      'Localização',
                      'Endereço utilizado pelo restaurante.',
                      Icons.location_on_rounded,
                    ),

                    const SizedBox(height: 12),

                    _card(
                      child: _campo(
                        controller: enderecoController,
                        label: 'Endereço completo',
                        hint:
                            'Rua, número, bairro, cidade...',
                        icon:
                            Icons.location_on_outlined,
                        maxLines: 3,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _tituloSecao(
                      'Funcionamento',
                      'Controle quando seu restaurante recebe pedidos.',
                      Icons.schedule_rounded,
                    ),

                    const SizedBox(height: 12),

                    _card(
                      padding: EdgeInsets.zero,
                      child: _statusRestaurante(),
                    ),

                    const SizedBox(height: 24),

                    _tituloSecao(
                      'Pedidos',
                      'Controle como os pedidos são recebidos.',
                      Icons.receipt_long_rounded,
                    ),

                    const SizedBox(height: 12),

                    _card(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _iconeBox(
                                Icons.touch_app_rounded,
                                laranja,
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Aceitação manual',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w800,
                                        color: texto,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Você decide quando aceitar cada pedido.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            textoSecundario,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFFF7ED),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'MANUAL',
                                  style: TextStyle(
                                    color: laranja,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF9FAFB),
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                            child: const Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color:
                                      textoSecundario,
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'Novos pedidos ficarão aguardando sua aceitação na aba de Pedidos.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          textoSecundario,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _tituloSecao(
                      'Ajuda e suporte',
                      'Precisa de ajuda? Fale com a administração do FoodJet.',
                      Icons.support_agent_rounded,
                    ),

                    const SizedBox(height: 12),

                    _card(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(20),
                        onTap: _abrirSuporte,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(0xFFEFF6FF),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color:
                                      Color(0xFF2563EB),
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Central de suporte',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w800,
                                        color: texto,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Problemas, dúvidas ou solicitações? Abra um chamado.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            textoSecundario,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _tituloSecao(
                      'Privacidade e conta',
                      'Gerencie sua conta e seus dados no FoodJet.',
                      Icons.privacy_tip_rounded,
                    ),

                    const SizedBox(height: 12),

                    _card(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(0xFFFEF2F2),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.privacy_tip_rounded,
                                    color: vermelho,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Exclusão da conta',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w900,
                                          color: texto,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Se você não quiser mais operar pelo FoodJet, poderá solicitar a exclusão da conta e dos dados vinculados.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              textoSecundario,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(13),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(0xFFFFF7ED),
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                              child: const Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: laranja,
                                    size: 19,
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Alguns registros poderão precisar ser mantidos pelo período exigido por lei ou por outras obrigações aplicáveis.',
                                      style: TextStyle(
                                        color:
                                            Color(0xFF9A3412),
                                        fontSize: 11,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed:
                                    excluindoConta || saindo
                                        ? null
                                        : _confirmarExclusaoConta,
                                icon: excluindoConta
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: vermelho,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  excluindoConta
                                      ? 'Excluindo conta...'
                                      : 'Excluir minha conta',
                                ),
                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      vermelho,
                                  side:
                                      const BorderSide(
                                    color: vermelho,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  textStyle:
                                      const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          InkWell(
                            onTap:
                                excluindoConta || saindo
                                    ? null
                                    : _confirmarLogout,
                            borderRadius:
                                const BorderRadius.only(
                              bottomLeft:
                                  Radius.circular(20),
                              bottomRight:
                                  Radius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(0xFFFFF7ED),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: laranja,
                                      size: 27,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sair da conta',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w900,
                                            color: texto,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'Encerrar a sessão neste dispositivo.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                textoSecundario,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (saindo)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: laranja,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons
                                          .arrow_forward_ios_rounded,
                                      size: 16,
                                      color:
                                          Color(0xFF9CA3AF),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            salvando || saindo
                                ? null
                                : salvarConfiguracoes,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: laranja,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.orange.shade200,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: salvando
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_rounded,
                                    size: 20,
                                  ),
                                  SizedBox(width: 9),
                                  Text(
                                    'Salvar alterações',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Center(
                      child: Text(
                        'FoodJet Restaurante',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _cabecalho() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            laranja,
            laranjaEscuro,
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: laranja.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Gerencie as informações e o funcionamento do seu restaurante.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TÍTULO
  // ============================================================

  Widget _tituloSecao(
    String titulo,
    String descricao,
    IconData icone,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icone,
            color: laranja,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: texto,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                descricao,
                style: const TextStyle(
                  fontSize: 11,
                  color: textoSecundario,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // ÍCONE
  // ============================================================

  Widget _iconeBox(
    IconData icone,
    Color cor,
  ) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Icon(
        icone,
        color: cor,
        size: 22,
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusRestaurante() {
    return InkWell(
      borderRadius:
          BorderRadius.circular(20),
      onTap: () {
        setState(() {
          aberto = !aberto;
        });
      },
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: aberto
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Icon(
                aberto
                    ? Icons.storefront_rounded
                    : Icons.storefront_outlined,
                color: aberto
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    aberto
                        ? 'Restaurante aberto'
                        : 'Restaurante fechado',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: texto,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    aberto
                        ? 'Seu restaurante está online e recebendo pedidos.'
                        : 'Seu restaurante está offline e não receberá novos pedidos.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: textoSecundario,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch(
              value: aberto,
              activeThumbColor: Colors.white,
              activeTrackColor:
                  const Color(0xFF16A34A),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor:
                  const Color(0xFFD1D5DB),
              onChanged: (valor) {
                setState(() {
                  aberto = valor;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO
  // ============================================================

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: textoSecundario,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: laranja,
          size: 21,
        ),
        filled: true,
        fillColor:
            const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: laranja,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUPORTE
  // ============================================================

  void _abrirSuporte() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RestaurantSupportScreen(),
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                erro
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(mensagem),
              ),
            ],
          ),
          backgroundColor: erro
              ? Colors.red.shade700
              : const Color(0xFF16A34A),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    telefoneController.dispose();
    enderecoController.dispose();

    super.dispose();
  }
}

// ==================================================================
// TELA DE SUPORTE
// ==================================================================

class RestaurantSupportScreen
    extends StatefulWidget {
  const RestaurantSupportScreen({
    super.key,
  });

  @override
  State<RestaurantSupportScreen> createState() =>
      _RestaurantSupportScreenState();
}

class _RestaurantSupportScreenState
    extends State<RestaurantSupportScreen> {
  static const Color laranja =
      Color(0xFFF97316);

  final assuntoController =
      TextEditingController();

  final mensagemController =
      TextEditingController();

  String categoriaSelecionada =
      'Pedidos';

  bool enviando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF171717),
        title: const Text(
          'Suporte',
          style: TextStyle(
            fontSize: 21,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),
              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.16,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        17,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .support_agent_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Como podemos ajudar?',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Envie sua dúvida ou problema para a administração do FoodJet.',
                          style:
                              TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Categoria do chamado',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
                color:
                    Color(0xFF171717),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _categoria(
                    Icons
                        .receipt_long_rounded,
                    'Pedidos',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _categoria(
                    Icons
                        .account_balance_wallet_rounded,
                    'Pagamentos',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _categoria(
                    Icons
                        .settings_suggest_rounded,
                    'Sistema',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Abrir chamado',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
                color:
                    Color(0xFF171717),
              ),
            ),

            const SizedBox(height: 12),

            _campoSuporte(
              assuntoController,
              'Assunto',
              'Ex.: Problema com pedido',
              Icons.subject_rounded,
            ),

            const SizedBox(height: 12),

            _campoSuporte(
              mensagemController,
              'Descreva o problema',
              'Explique o que aconteceu...',
              Icons
                  .chat_bubble_outline_rounded,
              maxLines: 6,
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFEFF6FF),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Icon(
                    Icons
                        .info_outline_rounded,
                    color:
                        Color(0xFF2563EB),
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'A administração analisará sua solicitação e poderá entrar em contato para resolver o problema.',
                      style:
                          TextStyle(
                        color:
                            Color(0xFF1D4ED8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: enviando
                    ? null
                    : _enviarChamado,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      laranja,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                child: enviando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 19,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Enviar chamado',
                            style:
                                TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'FoodJet • Central de suporte',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      Colors.grey.shade500,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoria(
    IconData icone,
    String titulo,
  ) {
    final selecionada =
        categoriaSelecionada == titulo;

    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: () {
        setState(() {
          categoriaSelecionada =
              titulo;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        padding:
            const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selecionada
              ? const Color(0xFFFFF7ED)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: selecionada
                ? laranja
                : const Color(
                    0xFFE5E7EB,
                  ),
            width:
                selecionada ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: selecionada
                  ? laranja
                  : const Color(
                      0xFF6B7280,
                    ),
              size: 23,
            ),
            const SizedBox(height: 7),
            Text(
              titulo,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
                color: selecionada
                    ? laranja
                    : const Color(
                        0xFF171717,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoSuporte(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight:
            FontWeight.w600,
      ),
      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: laranja,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 16,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color:
                Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: laranja,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Future<void> _enviarChamado() async {
    if (assuntoController.text
        .trim()
        .isEmpty) {
      _mensagem(
        'Informe o assunto do chamado.',
        erro: true,
      );
      return;
    }

    if (mensagemController.text
        .trim()
        .isEmpty) {
      _mensagem(
        'Descreva o problema para o suporte.',
        erro: true,
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      await Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) return;

      setState(() {
        enviando = false;
      });

      _mensagem(
        'Chamado enviado com sucesso!',
      );

      assuntoController.clear();
      mensagemController.clear();

      setState(() {
        categoriaSelecionada =
            'Pedidos';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        enviando = false;
      });

      _mensagem(
        'Não foi possível enviar o chamado.',
        erro: true,
      );
    }
  }

  void _mensagem(
    String texto, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                erro
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(texto),
              ),
            ],
          ),
          backgroundColor: erro
              ? Colors.red.shade700
              : const Color(0xFF16A34A),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  void dispose() {
    assuntoController.dispose();
    mensagemController.dispose();

    super.dispose();
  }
}