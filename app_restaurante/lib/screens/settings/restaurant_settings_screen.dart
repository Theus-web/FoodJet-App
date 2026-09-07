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
  final ImagePicker imagePicker = ImagePicker();

  final RestaurantService restaurantService =
      RestaurantService();

  XFile? logoSelecionada;
  Uint8List? logoBytes;

  XFile? capaSelecionada;
  Uint8List? capaBytes;

  String logoAtual = '';
  String capaAtual = '';

  bool carregando = false;
  bool carregandoDados = true;
  bool capaFoiRemovida = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    carregarDados();
  }

  // ============================================================
  // CARREGAR DADOS
  // ============================================================

  Future<void> carregarDados() async {
    try {
      await carregarLogo();
      await carregarCapa();
    } catch (e) {
      print(
        '❌ Erro ao carregar configurações: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          carregandoDados = false;
        });
      }
    }
  }

  // ============================================================
  // OBTER ID RESTAURANTE
  // ============================================================

  Future<String?> obterIdRestaurante() async {
    try {
      final provider =
          Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      final idProvider =
          provider.getRestaurantId();

      if (idProvider != null &&
          idProvider.trim().isNotEmpty) {
        return idProvider.trim();
      }
    } catch (e) {
      print(
        '⚠️ Erro ao obter ID pelo Provider: $e',
      );
    }

    try {
      final idService =
          await restaurantService.obterRestauranteId();

      if (idService != null &&
          idService.trim().isNotEmpty) {
        return idService.trim();
      }
    } catch (e) {
      print(
        '⚠️ Erro ao obter ID pelo Service: $e',
      );
    }

    final prefs =
        await SharedPreferences.getInstance();

    final chavesId = [
      'restauranteId',
      'restaurantId',
      'restaurante_id',
      'restaurant_id',
    ];

    for (final chave in chavesId) {
      final valor =
          prefs.getString(chave);

      if (valor != null &&
          valor.trim().isNotEmpty) {
        return valor.trim();
      }
    }

    final chavesJson = [
      'restaurante',
      'restaurant',
      'restauranteAtual',
    ];

    for (final chave in chavesJson) {
      final json =
          prefs.getString(chave);

      if (json == null ||
          json.trim().isEmpty) {
        continue;
      }

      try {
        final decoded =
            jsonDecode(json);

        if (decoded is Map) {
          final mapa =
              Map<String, dynamic>.from(
            decoded,
          );

          final id =
              mapa['id'] ??
                  mapa['_id'] ??
                  mapa['restauranteId'] ??
                  mapa['restaurantId'];

          if (id != null &&
              id.toString()
                  .trim()
                  .isNotEmpty) {
            return id.toString().trim();
          }
        }
      } catch (_) {}
    }

    return null;
  }

  // ============================================================
  // CARREGAR LOGO
  // ============================================================

  Future<void> carregarLogo() async {
    final provider =
        Provider.of<RestaurantProvider>(
      context,
      listen: false,
    );

    String logo = '';

    try {
      final imagemProvider =
          provider.imagem;

      if (imagemProvider != null &&
          imagemProvider.trim().isNotEmpty) {
        logo = imagemProvider.trim();
      }
    } catch (_) {}

    if (logo.isEmpty) {
      try {
        final restauranteId =
            await obterIdRestaurante();

        if (restauranteId != null &&
            restauranteId.isNotEmpty) {
          final restaurante =
              await restaurantService
                  .buscarRestaurante(
            restauranteId,
          );

          logo =
              (
                restaurante['logo'] ??
                restaurante['logoUrl'] ??
                restaurante['imagem'] ??
                restaurante['imagemUrl'] ??
                ''
              ).toString();
        }
      } catch (e) {
        print(
          '⚠️ Erro ao buscar logo do servidor: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      logoAtual = logo.trim();
    });

    if (logoAtual.isNotEmpty) {
      try {
        provider.setRestaurant(
          id: provider.getRestaurantId() ?? '',
          nomeRestaurante:
              provider.nome ?? '',
          telefoneRestaurante:
              provider.telefone,
          imagemRestaurante:
              logoAtual,
          statusAberto:
              provider.aberto,
        );
      } catch (_) {}
    }
  }

  // ============================================================
  // CARREGAR CAPA
  // ============================================================

  Future<void> carregarCapa() async {
    String capa = '';

    try {
      final restauranteId =
          await obterIdRestaurante();

      if (restauranteId != null &&
          restauranteId.isNotEmpty) {
        final restaurante =
            await restaurantService
                .buscarRestaurante(
          restauranteId,
        );

        capa =
            (
              restaurante['capa'] ??
              restaurante['capaUrl'] ??
              restaurante['banner'] ??
              restaurante['bannerUrl'] ??
              ''
            ).toString();
      }
    } catch (e) {
      print(
        '⚠️ Erro ao carregar capa: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      capaAtual = capa.trim();
    });
  }

  // ============================================================
  // URL DA IMAGEM
  // ============================================================

  String obterUrlImagem(
    String caminho,
  ) {
    if (caminho.trim().isEmpty) {
      return '';
    }

    final valor =
        caminho.trim();

    if (valor.startsWith(
          'http://',
        ) ||
        valor.startsWith(
          'https://',
        )) {
      return valor;
    }

    String base =
        RestaurantService.baseUrl;

    if (base.endsWith('/api')) {
      base = base.substring(
        0,
        base.length - 4,
      );
    }

    if (base.endsWith('/')) {
      base = base.substring(
        0,
        base.length - 1,
      );
    }

    if (valor.startsWith('/')) {
      return '$base$valor';
    }

    return '$base/$valor';
  }

  // ============================================================
  // SELECIONAR LOGO
  // ============================================================

  Future<void> selecionarLogo() async {
    try {
      final imagem =
          await imagePicker.pickImage(
        source:
            ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (imagem == null) {
        return;
      }

      final bytes =
          await imagem.readAsBytes();

      if (bytes.isEmpty) {
        mostrarMensagem(
          'Não foi possível ler a imagem.',
          erro: true,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        logoSelecionada = imagem;
        logoBytes = bytes;
      });
    } catch (e) {
      mostrarMensagem(
        'Erro ao selecionar logo: $e',
        erro: true,
      );
    }
  }

  // ============================================================
  // REMOVER LOGO LOCALMENTE
  // ============================================================

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

  // ============================================================
  // SALVAR LOGO
  //
  // AGORA USA:
  //
  // restaurantService.uploadLogo()
  //
  // NÃO USA MAIS BASE64.
  // ============================================================

  Future<void> salvarLogo() async {
    if (carregando) {
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

    final bool existeLogoAtual =
        logoAtual.trim().isNotEmpty;

    final bool selecionouNovaLogo =
        logoSelecionada != null &&
            logoBytes != null &&
            logoBytes!.isNotEmpty;

    // ==========================================================
    // REMOVER LOGO
    // ==========================================================

    if (!selecionouNovaLogo &&
        !existeLogoAtual) {
      mostrarMensagem(
        'Nenhuma logo para salvar.',
        erro: true,
      );
      return;
    }

    if (!selecionouNovaLogo &&
        existeLogoAtual) {
      mostrarMensagem(
        'Escolha uma nova imagem ou remova a logo atual.',
        erro: true,
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      print('');
      print(
        '========================================',
      );
      print(
        '📤 FOODJET - SALVANDO LOGO',
      );
      print(
        '🏪 Restaurante: $restauranteId',
      );
      print(
        '========================================',
      );

      // ========================================================
      // UPLOAD REAL DA LOGO
      // ========================================================

      final resposta =
          await restaurantService.uploadLogo(
        restauranteId,
        logoSelecionada!,
      );

      print(
        '📦 Resposta do upload da logo:',
      );

      print(resposta);

      // ========================================================
      // OBTER RESTAURANTE ATUALIZADO
      // ========================================================

      Map<String, dynamic> restaurante = {};

      if (resposta['restaurante'] is Map) {
        restaurante =
            Map<String, dynamic>.from(
          resposta['restaurante'],
        );
      }

      // ========================================================
      // OBTER URL/CAMINHO DA LOGO
      // ========================================================

      String novaLogo =
          (
            restaurante['logo'] ??
            restaurante['logoUrl'] ??
            restaurante['imagem'] ??
            restaurante['imagemUrl'] ??
            resposta['logo'] ??
            resposta['logoUrl'] ??
            resposta['imagem'] ??
            resposta['imagemUrl'] ??
            ''
          ).toString().trim();

      // ========================================================
      // CASO O BACKEND NÃO DEVOLVA NO JSON,
      // BUSCAR NOVAMENTE
      // ========================================================

      if (novaLogo.isEmpty) {
        try {
          final atualizado =
              await restaurantService
                  .buscarRestaurante(
            restauranteId,
          );

          novaLogo =
              (
                atualizado['logo'] ??
                atualizado['logoUrl'] ??
                atualizado['imagem'] ??
                atualizado['imagemUrl'] ??
                ''
              ).toString().trim();
        } catch (e) {
          print(
            '⚠️ Não foi possível buscar logo atualizada: $e',
          );
        }
      }

      if (novaLogo.isEmpty) {
        throw Exception(
          'O servidor não retornou a localização da nova logo.',
        );
      }

      print(
        '🖼️ Nova logo: $novaLogo',
      );

      // ========================================================
      // ATUALIZAR ESTADO
      // ========================================================

      if (!mounted) return;

      setState(() {
        logoAtual = novaLogo;

        logoSelecionada = null;
        logoBytes = null;
      });

      // ========================================================
      // ATUALIZAR PROVIDER
      // ========================================================

      final provider =
          Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      provider.setRestaurant(
        id: restauranteId,
        nomeRestaurante:
            restaurante['nome'] ??
                provider.nome ??
                '',
        telefoneRestaurante:
            restaurante['telefone'] ??
                provider.telefone,
        imagemRestaurante:
            novaLogo,
        statusAberto:
            restaurante['aberto'] ??
                restaurante['online'] ??
                provider.aberto,
      );

      // ========================================================
      // LIMPAR CACHE LOCAL DA IMAGEM
      // ========================================================

      try {
        final url =
            obterUrlImagem(novaLogo);

        if (url.isNotEmpty) {
          await NetworkImage(url)
              .evict();
        }
      } catch (_) {}

      print(
        '========================================',
      );
      print(
        '✅ LOGO SALVA COM SUCESSO',
      );
      print(
        '🖼️ Caminho: $novaLogo',
      );
      print(
        '🌐 URL: ${obterUrlImagem(novaLogo)}',
      );
      print(
        '========================================',
      );

      mostrarMensagem(
        'Logo atualizada com sucesso!',
      );
    } catch (e) {
      print('');
      print(
        '========================================',
      );
      print(
        '❌ ERRO AO SALVAR LOGO',
      );
      print(e);
      print(
        '========================================',
      );

      if (mounted) {
        mostrarMensagem(
          'Erro ao atualizar a logo: $e',
          erro: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRMAR REMOÇÃO DA LOGO
  // ============================================================

  Future<void> excluirLogoServidor() async {
    if (carregando) {
      return;
    }

    final restauranteId =
        await obterIdRestaurante();

    if (restauranteId == null ||
        restauranteId.trim().isEmpty) {
      mostrarMensagem(
        'Restaurante não identificado.',
        erro: true,
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      print('');
      print(
        '========================================',
      );
      print(
        '🗑️ FOODJET - EXCLUINDO LOGO',
      );
      print(
        '🏪 Restaurante: $restauranteId',
      );
      print(
        '========================================',
      );

      await restaurantService
          .removerLogo(
        restauranteId,
      );

      if (!mounted) return;

      setState(() {
        logoAtual = '';
        logoSelecionada = null;
        logoBytes = null;
      });

      final provider =
          Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      provider.setRestaurant(
        id: restauranteId,
        nomeRestaurante:
            provider.nome ?? '',
        telefoneRestaurante:
            provider.telefone,
        imagemRestaurante:
            '',
        statusAberto:
            provider.aberto,
      );

      mostrarMensagem(
        'Logo removida com sucesso!',
      );
    } catch (e) {
      print(
        '❌ Erro ao remover logo: $e',
      );

      if (mounted) {
        mostrarMensagem(
          'Erro ao remover logo: $e',
          erro: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ============================================================
  // SELECIONAR CAPA
  // ============================================================

  Future<void> selecionarCapa() async {
    try {
      final imagem =
          await imagePicker.pickImage(
        source:
            ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1000,
      );

      if (imagem == null) {
        return;
      }

      final bytes =
          await imagem.readAsBytes();

      if (bytes.isEmpty) {
        mostrarMensagem(
          'Não foi possível ler a imagem da capa.',
          erro: true,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        capaSelecionada = imagem;
        capaBytes = bytes;
        capaFoiRemovida = false;
      });
    } catch (e) {
      mostrarMensagem(
        'Erro ao selecionar capa: $e',
        erro: true,
      );
    }
  }

  // ============================================================
  // REMOVER CAPA
  // ============================================================

  void removerCapa() {
    setState(() {
      capaSelecionada = null;
      capaBytes = null;
      capaAtual = '';
      capaFoiRemovida = true;
    });

    mostrarMensagem(
      'A capa será removida ao salvar.',
    );
  }

  // ============================================================
  // SALVAR CAPA
  // ============================================================

  Future<void> salvarCapa() async {
    if (carregando) {
      return;
    }

    final restauranteId =
        await obterIdRestaurante();

    if (restauranteId == null ||
        restauranteId.trim().isEmpty) {
      mostrarMensagem(
        'Restaurante não identificado.',
        erro: true,
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      // ========================================================
      // REMOVER CAPA
      // ========================================================

      if (capaFoiRemovida &&
          capaSelecionada == null) {
        await restaurantService
            .removerCapa(
          restauranteId,
        );

        if (!mounted) return;

        setState(() {
          capaAtual = '';
          capaFoiRemovida = false;
        });

        mostrarMensagem(
          'Capa removida com sucesso!',
        );

        return;
      }

      // ========================================================
      // NENHUMA NOVA CAPA
      // ========================================================

      if (capaSelecionada == null) {
        mostrarMensagem(
          'Escolha uma imagem para a capa.',
          erro: true,
        );
        return;
      }

      // ========================================================
      // UPLOAD
      // ========================================================

      final resposta =
          await restaurantService.uploadCapa(
        restauranteId,
        capaSelecionada!,
      );

      Map<String, dynamic> restaurante =
          {};

      if (resposta['restaurante'] is Map) {
        restaurante =
            Map<String, dynamic>.from(
          resposta['restaurante'],
        );
      }

      String novaCapa =
          (
            restaurante['capa'] ??
            restaurante['capaUrl'] ??
            restaurante['banner'] ??
            restaurante['bannerUrl'] ??
            resposta['capa'] ??
            resposta['capaUrl'] ??
            resposta['banner'] ??
            resposta['bannerUrl'] ??
            ''
          ).toString().trim();

      if (novaCapa.isEmpty) {
        try {
          final atualizado =
              await restaurantService
                  .buscarRestaurante(
            restauranteId,
          );

          novaCapa =
              (
                atualizado['capa'] ??
                atualizado['capaUrl'] ??
                atualizado['banner'] ??
                atualizado['bannerUrl'] ??
                ''
              ).toString().trim();
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        capaAtual = novaCapa;

        capaSelecionada = null;
        capaBytes = null;

        capaFoiRemovida = false;
      });

      mostrarMensagem(
        'Capa atualizada com sucesso!',
      );
    } catch (e) {
      if (mounted) {
        mostrarMensagem(
          'Erro ao atualizar capa: $e',
          erro: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
        ),
        backgroundColor:
            erro
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ============================================================
  // WIDGET LOGO
  // ============================================================

  Widget imagemLogo() {
    // ==========================================================
    // NOVA IMAGEM SELECIONADA
    // ==========================================================

    if (logoBytes != null &&
        logoBytes!.isNotEmpty) {
      return Image.memory(
        logoBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // ==========================================================
    // LOGO ATUAL
    // ==========================================================

    if (logoAtual.trim().isNotEmpty) {
      final valor =
          logoAtual.trim();

      // ========================================================
      // BASE64 ANTIGO
      //
      // Mantido apenas para compatibilidade
      // com logos antigas.
      // ========================================================

      if (valor.startsWith(
        'data:image',
      )) {
        try {
          final partes =
              valor.split(',');

          if (partes.length == 2) {
            final bytes =
                base64Decode(
              partes[1],
            );

            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              width:
                  double.infinity,
              height:
                  double.infinity,
            );
          }
        } catch (_) {}
      }

      // ========================================================
      // URL
      // ========================================================

      final url =
          obterUrlImagem(valor);

      if (url.isNotEmpty) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width:
              double.infinity,
          height:
              double.infinity,
          cacheWidth: 800,
          errorBuilder:
              (
                context,
                error,
                stackTrace,
              ) {
            print(
              '❌ Erro ao carregar logo:',
            );
            print(
              '🌐 URL: $url',
            );
            print(error);

            return const Icon(
              Icons.restaurant,
              size: 60,
              color: Colors.grey,
            );
          },
        );
      }
    }

    // ==========================================================
    // PLACEHOLDER
    // ==========================================================

    return const Icon(
      Icons.restaurant,
      size: 60,
      color: Colors.grey,
    );
  }

  // ============================================================
  // WIDGET CAPA
  // ============================================================

  Widget imagemCapa() {
    if (capaBytes != null &&
        capaBytes!.isNotEmpty) {
      return Image.memory(
        capaBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (capaAtual.trim().isNotEmpty) {
      final url =
          obterUrlImagem(
        capaAtual,
      );

      if (url.isNotEmpty) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder:
              (
                context,
                error,
                stackTrace,
              ) {
            print(
              '❌ Erro ao carregar capa:',
            );
            print(
              '🌐 URL: $url',
            );

            return const Icon(
              Icons.image,
              size: 60,
              color: Colors.grey,
            );
          },
        );
      }
    }

    return const Icon(
      Icons.image,
      size: 60,
      color: Colors.grey,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> sair() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('access_token');
    await prefs.remove('auth_token');

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
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
        title: const Text(
          'Configurações',
        ),
        backgroundColor:
            const Color(0xFFF97316),
        foregroundColor:
            Colors.white,
        elevation: 0,
      ),
      body:
          carregandoDados
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      // ==================================================
                      // LOGO
                      // ==================================================

                      const Text(
                        'Logo do restaurante',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Container(
                        height: 180,
                        width:
                            double.infinity,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color:
                                Colors.grey.shade300,
                          ),
                        ),
                        clipBehavior:
                            Clip.antiAlias,
                        child:
                            imagemLogo(),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  carregando
                                      ? null
                                      : selecionarLogo,
                              icon:
                                  const Icon(
                                Icons
                                    .photo_library,
                              ),
                              label:
                                  const Text(
                                'Escolher logo',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  carregando ||
                                          logoAtual
                                              .isEmpty
                                      ? null
                                      : excluirLogoServidor,
                              icon:
                                  const Icon(
                                Icons
                                    .delete_outline,
                              ),
                              label:
                                  const Text(
                                'Remover',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              carregando
                                  ? null
                                  : salvarLogo,
                          icon:
                              carregando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .cloud_upload,
                                    ),
                          label:
                              Text(
                            carregando
                                ? 'Enviando...'
                                : 'Salvar logo',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFFF97316,
                            ),
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      // ==================================================
                      // CAPA
                      // ==================================================

                      const Text(
                        'Capa do restaurante',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Container(
                        height: 200,
                        width:
                            double.infinity,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                          border:
                              Border.all(
                            color:
                                Colors.grey.shade300,
                          ),
                        ),
                        clipBehavior:
                            Clip.antiAlias,
                        child:
                            imagemCapa(),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  carregando
                                      ? null
                                      : selecionarCapa,
                              icon:
                                  const Icon(
                                Icons
                                    .photo_library,
                              ),
                              label:
                                  const Text(
                                'Escolher capa',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  carregando ||
                                          capaAtual
                                              .isEmpty
                                      ? null
                                      : removerCapa,
                              icon:
                                  const Icon(
                                Icons
                                    .delete_outline,
                              ),
                              label:
                                  const Text(
                                'Remover',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              carregando
                                  ? null
                                  : salvarCapa,
                          icon:
                              const Icon(
                            Icons
                                .cloud_upload,
                          ),
                          label:
                              const Text(
                            'Salvar capa',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFFF97316,
                            ),
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      // ==================================================
                      // SAIR
                      // ==================================================

                      OutlinedButton.icon(
                        onPressed:
                            carregando
                                ? null
                                : sair,
                        icon:
                            const Icon(
                          Icons.logout,
                        ),
                        label:
                            const Text(
                          'Sair',
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              Colors.red,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
    );
  }
}