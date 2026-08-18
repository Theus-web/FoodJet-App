import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/restaurant_provider.dart';
import '../../services/restaurant_service.dart';
import '../login_screen.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState
    extends State<RestaurantSettingsScreen> {
  static const Color laranja = Color(0xFFF97316);

  final ImagePicker imagePicker = ImagePicker();
  final RestaurantService restaurantService = RestaurantService();

  XFile? logoSelecionada;
  Uint8List? logoBytes;

  String logoAtual = '';

  bool carregando = false;
  bool carregandoDados = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarDados();
    });
  }

  // ==========================================================
  // CARREGAR DADOS
  // ==========================================================

  Future<void> carregarDados() async {
    await carregarLogo();

    if (!mounted) return;

    setState(() {
      carregandoDados = false;
    });
  }

  // ==========================================================
  // CARREGAR LOGO
  // ==========================================================

  Future<void> carregarLogo() async {
    final provider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    String imagem = provider.imagem ?? '';

    if (imagem.trim().isEmpty) {
      try {
        final restauranteId = provider.getRestaurantId();

        if (restauranteId != null &&
            restauranteId.trim().isNotEmpty) {
          final restaurante =
              await restaurantService.buscarRestaurante(
            restauranteId,
          );

          imagem = (
            restaurante['imagem'] ??
            restaurante['logo'] ??
            ''
          ).toString();

          if (restaurante.isNotEmpty) {
            provider.setRestaurant(
              id: restauranteId,
              nomeRestaurante:
                  (restaurante['nome'] ?? '').toString(),
              telefoneRestaurante:
                  restaurante['telefone']?.toString(),
              imagemRestaurante: imagem,
              statusAberto:
                  restaurante['aberto'] is bool
                      ? restaurante['aberto'] as bool
                      : null,
            );
          }
        }
      } catch (_) {}
    }

    if (imagem.trim().isEmpty) {
      try {
        final restauranteId =
            await restaurantService.obterRestauranteId();

        if (restauranteId != null &&
            restauranteId.trim().isNotEmpty) {
          final restaurante =
              await restaurantService.buscarRestaurante(
            restauranteId,
          );

          imagem = (
            restaurante['imagem'] ??
            restaurante['logo'] ??
            ''
          ).toString();
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      logoAtual = imagem;
    });
  }

  // ==========================================================
  // OBTER ID
  // ==========================================================

  Future<String?> obterIdRestaurante() async {
    final provider = Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    String? id = provider.getRestaurantId();

    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }

    try {
      id = await restaurantService.obterRestauranteId();

      if (id != null && id.trim().isNotEmpty) {
        id = id.trim();

        provider.setRestaurantId(id);

        return id;
      }
    } catch (_) {}

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final chaves = [
        'restauranteId',
        'restaurantId',
        'restaurante_id',
        'restaurant_id',
      ];

      for (final chave in chaves) {
        final valor = prefs.getString(chave);

        if (valor != null &&
            valor.trim().isNotEmpty) {
          id = valor.trim();

          provider.setRestaurantId(id);

          return id;
        }
      }

      final jsons = [
        prefs.getString('restaurante'),
        prefs.getString('restaurant'),
        prefs.getString('restauranteAtual'),
      ];

      for (final json in jsons) {
        if (json == null || json.trim().isEmpty) {
          continue;
        }

        try {
          final decoded = jsonDecode(json);

          if (decoded is Map) {
            final mapa =
                Map<String, dynamic>.from(decoded);

            final valor =
                mapa['id'] ??
                mapa['_id'] ??
                mapa['restauranteId'] ??
                mapa['restaurantId'];

            if (valor != null &&
                valor.toString().trim().isNotEmpty) {
              id = valor.toString().trim();

              await prefs.setString(
                'restauranteId',
                id,
              );

              provider.setRestaurantId(id);

              return id;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  // ==========================================================
  // SELECIONAR LOGO
  // ==========================================================

  Future<void> selecionarLogo() async {
    try {
      final imagem =
          await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (imagem == null) return;

      final bytes =
          await imagem.readAsBytes();

      if (bytes.isEmpty) {
        mostrarMensagem(
          'A imagem selecionada está vazia.',
          erro: true,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        logoSelecionada = imagem;
        logoBytes = bytes;
      });

      mostrarMensagem(
        'Nova logo selecionada.',
      );
    } catch (_) {
      if (!mounted) return;

      mostrarMensagem(
        'Não foi possível selecionar a imagem.',
        erro: true,
      );
    }
  }

  // ==========================================================
  // REMOVER LOGO
  // ==========================================================

  void removerLogo() {
    setState(() {
      logoSelecionada = null;
      logoBytes = null;
      logoAtual = '';
    });

    mostrarMensagem(
      'A logo será removida ao salvar.',
    );
  }

  // ==========================================================
  // BASE64
  // ==========================================================

  String? gerarBase64() {
    if (logoSelecionada == null ||
        logoBytes == null ||
        logoBytes!.isEmpty) {
      return null;
    }

    String mime = 'image/jpeg';

    final nome =
        logoSelecionada!.name.toLowerCase();

    if (nome.endsWith('.png')) {
      mime = 'image/png';
    } else if (nome.endsWith('.webp')) {
      mime = 'image/webp';
    }

    return 'data:$mime;base64,${base64Encode(logoBytes!)}';
  }

  // ==========================================================
  // SALVAR LOGO
  // ==========================================================

  Future<void> salvarLogo() async {
    if (carregando) return;

    final novaImagem = gerarBase64();

    if (novaImagem == null &&
        logoAtual.isNotEmpty) {
      mostrarMensagem(
        'Escolha uma nova imagem ou remova a logo atual.',
        erro: true,
      );
      return;
    }

    final restauranteId =
        await obterIdRestaurante();

    if (restauranteId == null ||
        restauranteId.trim().isEmpty) {
      mostrarMensagem(
        'Restaurante não identificado. Faça login novamente.',
        erro: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      carregando = true;
    });

    try {
      final dados =
          <String, dynamic>{};

      if (novaImagem != null) {
        dados['imagem'] = novaImagem;
      } else {
        dados['imagem'] = '';
      }

      await restaurantService.atualizarRestaurante(
        restauranteId,
        dados,
      );

      final provider =
          Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      logoAtual = novaImagem ?? '';

      provider.setRestaurant(
        id: restauranteId,
        nomeRestaurante:
            provider.nome ?? '',
        telefoneRestaurante:
            provider.telefone,
        imagemRestaurante:
            logoAtual,
        statusAberto:
            provider.aberto,
      );

      if (!mounted) return;

      setState(() {
        logoSelecionada = null;
        logoBytes = null;
      });

      mostrarMensagem(
        'Logo atualizada com sucesso!',
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensagem(
        'Erro ao atualizar logo: $e',
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
  // IMAGEM DA LOGO
  // ==========================================================

  Widget imagemLogo() {
    if (logoBytes != null &&
        logoBytes!.isNotEmpty) {
      return Image.memory(
        logoBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder:
            (_, __, ___) => placeholderLogo(),
      );
    }

    if (logoAtual.isNotEmpty) {
      if (logoAtual.startsWith('data:image')) {
        try {
          final partes =
              logoAtual.split(',');

          if (partes.length == 2) {
            final bytes =
                base64Decode(partes[1]);

            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder:
                  (_, __, ___) => placeholderLogo(),
            );
          }
        } catch (_) {
          return placeholderLogo();
        }
      }

      if (logoAtual.startsWith('http://') ||
          logoAtual.startsWith('https://')) {
        return Image.network(
          logoAtual,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder:
              (context, child, progress) {
            if (progress == null) {
              return child;
            }

            return const Center(
              child: CircularProgressIndicator(
                color: laranja,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder:
              (_, __, ___) => placeholderLogo(),
        );
      }
    }

    return placeholderLogo();
  }

  Widget placeholderLogo() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 60,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS RESTAURANTE
  // ==========================================================

  Future<void> alterarStatusRestaurante(
    bool aberto,
  ) async {
    final restauranteId =
        await obterIdRestaurante();

    if (restauranteId == null ||
        restauranteId.isEmpty) {
      mostrarMensagem(
        'Restaurante não identificado.',
        erro: true,
      );
      return;
    }

    try {
      await restaurantService.alterarStatus(
        restauranteId,
        aberto ? 'ABERTO' : 'FECHADO',
      );

      if (!mounted) return;

      final provider =
          Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      provider.definirStatus(aberto);

      mostrarMensagem(
        aberto
            ? 'Restaurante aberto para pedidos.'
            : 'Restaurante fechado para pedidos.',
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      mostrarMensagem(
        'Não foi possível alterar o status: $e',
        erro: true,
      );
    }
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
            erro ? Colors.red : Colors.green,
      ),
    );
  }

  // ==========================================================
  // CARD
  // ==========================================================

  Widget cardConfiguracao({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 7,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: laranja.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(14),
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
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 3),
          child: Text(
            descricao,
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget tituloSecao(String titulo) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left: 4,
        top: 14,
        bottom: 10,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titulo,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color:
                Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CENTRAL DE AJUDA
  // ==========================================================

  void abrirCentralAjuda() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              22,
              15,
              22,
              25,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                const Icon(
                  Icons.help_outline,
                  size: 55,
                  color: laranja,
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  'Central de ajuda',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Encontre orientações para utilizar '
                  'o FoodJet Restaurante.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                _itemAjuda(
                  Icons.storefront_outlined,
                  'Como abrir ou fechar a loja',
                  'Use o botão de status para controlar '
                      'quando seu restaurante aceita pedidos.',
                ),
                _itemAjuda(
                  Icons.image_outlined,
                  'Alterar a logo',
                  'Escolha uma imagem na galeria e toque '
                      'em Salvar logo.',
                ),
                _itemAjuda(
                  Icons.shopping_bag_outlined,
                  'Pedidos',
                  'Os novos pedidos aparecem na área '
                      'de pedidos do restaurante.',
                ),
                _itemAjuda(
                  Icons.support_agent_outlined,
                  'Precisa de ajuda?',
                  'Use Falar com suporte para entrar em '
                      'contato com a equipe FoodJet.',
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemAjuda(
    IconData icon,
    String titulo,
    String descricao,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: laranja,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUPORTE
  // ==========================================================

  void abrirSuporte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              22,
              18,
              22,
              30,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration:
                      BoxDecoration(
                    color:
                        laranja.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    size: 40,
                    color: laranja,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  'Falar com suporte',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Entre em contato com a equipe '
                  'FoodJet para receber ajuda.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      mostrarMensagem(
                        'Canal de suporte FoodJet em breve.',
                      );
                    },
                    icon: const Icon(
                      Icons.chat_outlined,
                    ),
                    label: const Text(
                      'Entrar em contato',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          laranja,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
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

  // ==========================================================
  // SEGURANÇA
  // ==========================================================

  void abrirSeguranca() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: laranja,
              ),
              SizedBox(width: 10),
              Text('Segurança'),
            ],
          ),
          content: const Text(
            'Mantenha sua senha segura e não '
            'compartilhe seus dados de acesso '
            'com outras pessoas.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SAIR DA CONTA
  // ==========================================================

  Future<void> sairDaConta() async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Sair da conta?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Você será desconectado do '
            'FoodJet Restaurante e voltará '
            'para a tela de login.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child:
                  const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.remove('token');
      await prefs.remove('usuario');
      await prefs.remove('user');
      await prefs.remove('access_token');
      await prefs.remove('auth_token');

      await prefs.remove('restauranteId');
      await prefs.remove('restaurantId');
      await prefs.remove('restaurante');
      await prefs.remove('restaurant');
      await prefs.remove('restauranteAtual');
      await prefs.remove('usuarioLogado');
      await prefs.remove('userData');

      if (!mounted) return;

      final provider =
          Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      provider.logout();

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensagem(
        'Não foi possível sair da conta: $e',
        erro: true,
      );
    }
  }

  // ==========================================================
  // EXCLUIR CONTA
  // ==========================================================

  Future<void> confirmarExclusaoConta() async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Excluir conta?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Essa ação excluirá permanentemente '
            'a conta do restaurante. Essa operação '
            'não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child:
                  const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Excluir conta',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await excluirConta();
  }

  Future<void> excluirConta() async {
    try {
      final restauranteId =
          await obterIdRestaurante();

      if (restauranteId == null ||
          restauranteId.isEmpty) {
        mostrarMensagem(
          'Restaurante não identificado.',
          erro: true,
        );
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: laranja,
            ),
          );
        },
      );

      await restaurantService.excluirConta(
        restauranteId,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      final provider =
          Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      provider.logout();

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      mostrarMensagem(
        'Erro ao excluir conta: $e',
        erro: true,
      );
    }
  }

  // ==========================================================
  // INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<RestaurantProvider>(
      context,
    );

    final nomeRestaurante =
        provider.nome?.trim().isNotEmpty == true
            ? provider.nome!
            : 'Meu restaurante';

    final statusAtual =
        provider.aberto;

    if (carregandoDados) {
      return const Scaffold(
        backgroundColor:
            Color(0xFFF5F5F5),
        body: Center(
          child:
              CircularProgressIndicator(
            color: laranja,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            children: [
              // ==================================================
              // CABEÇALHO
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Color(0xFFF97316),
                      Color(0xFFEA580C),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color:
                          laranja.withValues(
                        alpha: 0.22,
                      ),
                      blurRadius: 18,
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                      clipBehavior:
                          Clip.antiAlias,
                      child: imagemLogo(),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configurações da loja',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            nomeRestaurante,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // IDENTIDADE
              // ==================================================

              tituloSecao(
                'Identidade da loja',
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior:
                          Clip.none,
                      children: [
                        Container(
                          width: 170,
                          height: 170,
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              28,
                            ),
                            border:
                                Border.all(
                              color:
                                  Colors.grey.shade200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 18,
                                offset:
                                    const Offset(
                                  0,
                                  7,
                                ),
                              ),
                            ],
                          ),
                          clipBehavior:
                              Clip.antiAlias,
                          child: imagemLogo(),
                        ),
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Material(
                            color: laranja,
                            elevation: 5,
                            shape:
                                const CircleBorder(),
                            child: InkWell(
                              customBorder:
                                  const CircleBorder(),
                              onTap:
                                  carregando
                                      ? null
                                      : selecionarLogo,
                              child:
                                  const Padding(
                                padding:
                                    EdgeInsets.all(
                                  13,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color:
                                      Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    const Text(
                      'Logo do restaurante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Essa imagem será exibida '
                      'para seus clientes no FoodJet.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            carregando
                                ? null
                                : selecionarLogo,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: laranja,
                        ),
                        label: const Text(
                          'Escolher nova imagem',
                          style: TextStyle(
                            color: laranja,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          side:
                              const BorderSide(
                            color: laranja,
                            width: 1.5,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextButton.icon(
                      onPressed:
                          carregando
                              ? null
                              : removerLogo,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Remover logo',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            carregando
                                ? null
                                : salvarLogo,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              laranja,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: carregando
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
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Salvar logo',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // FUNCIONAMENTO
              // ==================================================

              tituloSecao(
                'Funcionamento',
              ),

              cardConfiguracao(
                icone: statusAtual
                    ? Icons.storefront
                    : Icons.storefront_outlined,
                titulo: statusAtual
                    ? 'Restaurante aberto'
                    : 'Restaurante fechado',
                descricao: statusAtual
                    ? 'Sua loja está recebendo pedidos'
                    : 'Sua loja não está recebendo pedidos',
                trailing: Switch(
                  value: statusAtual,
                  activeColor: laranja,
                  onChanged:
                      alterarStatusRestaurante,
                ),
              ),

              // ==================================================
              // AJUDA
              // ==================================================

              tituloSecao(
                'Ajuda e suporte',
              ),

              cardConfiguracao(
                icone:
                    Icons.help_outline,
                titulo:
                    'Central de ajuda',
                descricao:
                    'Veja orientações para utilizar o FoodJet',
                trailing:
                    const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
                onTap:
                    abrirCentralAjuda,
              ),

              cardConfiguracao(
                icone:
                    Icons.support_agent_outlined,
                titulo:
                    'Falar com suporte',
                descricao:
                    'Entre em contato com a equipe FoodJet',
                trailing:
                    const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
                onTap:
                    abrirSuporte,
              ),

              // ==================================================
              // SEGURANÇA
              // ==================================================

              tituloSecao(
                'Segurança',
              ),

              cardConfiguracao(
                icone:
                    Icons.lock_outline,
                titulo:
                    'Segurança da conta',
                descricao:
                    'Informações para proteger seu acesso',
                trailing:
                    const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
                onTap:
                    abrirSeguranca,
              ),

              // ==================================================
              // CONTA
              // ==================================================

              tituloSecao(
                'Conta',
              ),

              cardConfiguracao(
                icone:
                    Icons.logout,
                titulo:
                    'Sair da conta',
                descricao:
                    'Sair do restaurante e voltar para o login',
                trailing:
                    const Icon(
                  Icons.chevron_right,
                  color: Colors.orange,
                ),
                onTap:
                    sairDaConta,
              ),

              cardConfiguracao(
                icone:
                    Icons.delete_forever_outlined,
                titulo:
                    'Excluir conta',
                descricao:
                    'Excluir permanentemente o restaurante',
                trailing:
                    const Icon(
                  Icons.chevron_right,
                  color: Colors.red,
                ),
                onTap:
                    confirmarExclusaoConta,
              ),

              const SizedBox(
                height: 20,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Colors.orange.shade100,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          Colors.orange.shade700,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        'As configurações da sua loja '
                        'controlam o funcionamento do '
                        'restaurante no FoodJet.',
                        style: TextStyle(
                          color:
                              Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}