import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/restaurant_provider.dart';
import '../../services/restaurant_service.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final ImagePicker imagePicker = ImagePicker();

  final RestaurantService restaurantService = RestaurantService();

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController enderecoController = TextEditingController();

  // ==========================================================
  // LOGO
  // ==========================================================

  XFile? logoSelecionada;
  Uint8List? logoBytes;

  String logoAtual = '';

  bool carregando = false;

  static const Color laranja = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarDados();
    });
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    telefoneController.dispose();
    enderecoController.dispose();

    super.dispose();
  }

  // ==========================================================
  // CARREGAR DADOS DO PROVIDER
  // ==========================================================

  void carregarDados() {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);

    setState(() {
      nomeController.text = provider.nome ?? '';
      telefoneController.text = provider.telefone ?? '';
      logoAtual = provider.imagem ?? '';
    });
  }

  // ==========================================================
  // SELECIONAR LOGO
  // ==========================================================

  Future<void> selecionarLogo() async {
    try {
      final XFile? imagem = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (imagem == null) {
        return;
      }

      final bytes = await imagem.readAsBytes();

      if (bytes.isEmpty) {
        mostrarMensagem('A imagem selecionada está vazia.', erro: true);
        return;
      }

      if (!mounted) return;

      setState(() {
        logoSelecionada = imagem;
        logoBytes = bytes;
      });

      mostrarMensagem(
        'Logo selecionada. Clique em "Salvar alterações" para confirmar.',
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensagem('Não foi possível selecionar a logo.', erro: true);
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

    mostrarMensagem('A logo será removida ao salvar.');
  }

  // ==========================================================
  // CONVERTER LOGO PARA BASE64
  // ==========================================================

  Future<String?> logoBase64() async {
    if (logoSelecionada == null || logoBytes == null) {
      return null;
    }

    String mime = 'image/jpeg';

    final nome = logoSelecionada!.name.toLowerCase();

    if (nome.endsWith('.png')) {
      mime = 'image/png';
    } else if (nome.endsWith('.webp')) {
      mime = 'image/webp';
    } else if (nome.endsWith('.jpg') || nome.endsWith('.jpeg')) {
      mime = 'image/jpeg';
    }

    return 'data:$mime;base64,${base64Encode(logoBytes!)}';
  }

  // ==========================================================
  // MOSTRAR LOGO
  // ==========================================================

  Widget imagemLogo() {
    // --------------------------------------------------------
    // NOVA IMAGEM SELECIONADA
    // --------------------------------------------------------

    if (logoBytes != null && logoBytes!.isNotEmpty) {
      return Image.memory(
        logoBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return placeholderLogo();
        },
      );
    }

    // --------------------------------------------------------
    // IMAGEM SALVA NO PROVIDER / BACKEND
    // --------------------------------------------------------

    if (logoAtual.isNotEmpty) {
      // ------------------------------------------------------
      // BASE64
      // ------------------------------------------------------

      if (logoAtual.startsWith('data:image')) {
        try {
          final partes = logoAtual.split(',');

          if (partes.length == 2) {
            final bytes = base64Decode(partes[1]);

            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return placeholderLogo();
              },
            );
          }
        } catch (_) {
          return placeholderLogo();
        }
      }

      // ------------------------------------------------------
      // URL
      // ------------------------------------------------------

      if (logoAtual.startsWith('http://') || logoAtual.startsWith('https://')) {
        return Image.network(
          logoAtual,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: CircularProgressIndicator(color: laranja, strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return placeholderLogo();
          },
        );
      }
    }

    return placeholderLogo();
  }

  // ==========================================================
  // PLACEHOLDER
  // ==========================================================

  Widget placeholderLogo() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.restaurant, size: 55, color: Colors.grey),
      ),
    );
  }

  // ==========================================================
  // SALVAR ALTERAÇÕES
  // ==========================================================

  Future<void> salvarAlteracoes() async {
    if (carregando) {
      return;
    }

    final provider = Provider.of<RestaurantProvider>(context, listen: false);

    final restauranteId = provider.getRestaurantId();

    if (restauranteId == null || restauranteId.isEmpty) {
      mostrarMensagem('Restaurante não encontrado.', erro: true);
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final novaLogo = await logoBase64();

      final Map<String, dynamic> dados = {
        'nome': nomeController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'descricao': descricaoController.text.trim(),
        'endereco': enderecoController.text.trim(),
      };

      // ------------------------------------------------------
      // SE EXISTIR NOVA LOGO
      // ------------------------------------------------------

      if (novaLogo != null) {
        dados['imagem'] = novaLogo;
      } else {
        // Se o usuário removeu a logo
        if (logoAtual.isEmpty) {
          dados['imagem'] = '';
        }
      }

      // ------------------------------------------------------
      // ATUALIZAR NO BACKEND
      // ------------------------------------------------------

      await restaurantService.atualizarRestaurante(restauranteId, dados);

      // ------------------------------------------------------
      // ATUALIZAR LOGO LOCALMENTE
      // ------------------------------------------------------

      if (novaLogo != null) {
        logoAtual = novaLogo;
      }

      // ------------------------------------------------------
      // ATUALIZAR PROVIDER
      // ------------------------------------------------------

      provider.setRestaurant(
        id: restauranteId,
        nomeRestaurante: nomeController.text.trim(),
        telefoneRestaurante: telefoneController.text.trim(),
        imagemRestaurante: logoAtual,
      );

      setState(() {
        logoSelecionada = null;
        logoBytes = null;
      });

      mostrarMensagem('Dados atualizados com sucesso.');
    } catch (e) {
      mostrarMensagem('Erro ao salvar alterações: $e', erro: true);
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red : Colors.green,
      ),
    );
  }

  // ==========================================================
  // CAMPO
  // ==========================================================

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: laranja, width: 2),
        ),
      ),
    );
  }

  // ==========================================================
  // INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // TÍTULO
            // =================================================
            const Text(
              'Dados do restaurante',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              'Atualize as informações e a logo da sua loja.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 25),

            // =================================================
            // LOGO
            // =================================================
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imagemLogo(),
                  ),

                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: Material(
                      color: laranja,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: selecionarLogo,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: TextButton.icon(
                onPressed: removerLogo,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Remover logo',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // NOME
            // =================================================
            campoTexto(
              label: 'Nome do restaurante',
              controller: nomeController,
            ),

            const SizedBox(height: 15),

            // =================================================
            // DESCRIÇÃO
            // =================================================
            campoTexto(
              label: 'Descrição',
              controller: descricaoController,
              maxLines: 3,
            ),

            const SizedBox(height: 15),

            // =================================================
            // TELEFONE
            // =================================================
            campoTexto(
              label: 'Telefone',
              controller: telefoneController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 15),

            // =================================================
            // ENDEREÇO
            // =================================================
            campoTexto(label: 'Endereço', controller: enderecoController),

            const SizedBox(height: 30),

            // =================================================
            // BOTÃO SALVAR
            // =================================================
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: carregando ? null : salvarAlteracoes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: laranja,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: carregando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Salvar alterações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
