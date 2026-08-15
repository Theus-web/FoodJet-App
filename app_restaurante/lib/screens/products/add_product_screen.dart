import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  final String restauranteId;

  const AddProductScreen({
    super.key,
    required this.restauranteId,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductService service = ProductService();
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController precoController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();

  File? imagemSelecionada;

  bool disponivel = true;
  bool destaque = false;
  bool salvando = false;

  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  final List<String> categoriasSugeridas = [
    'Hambúrguer',
    'Pizza',
    'Lanches',
    'Porções',
    'Bebidas',
    'Sobremesas',
    'Combos',
    'Pratos',
    'Açaí',
    'Outros',
  ];

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    precoController.dispose();
    categoriaController.dispose();
    super.dispose();
  }

  // ============================================================
  // SELECIONAR IMAGEM
  // ============================================================

  Future<void> selecionarImagem() async {
    if (salvando) return;

    try {
      final XFile? arquivo = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (arquivo == null) return;

      final File file = File(arquivo.path);

      if (!mounted) return;

      setState(() {
        imagemSelecionada = file;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarErro(
        'Não foi possível selecionar a imagem.',
      );
    }
  }

  // ============================================================
  // REMOVER IMAGEM
  // ============================================================

  void removerImagem() {
    if (salvando) return;

    setState(() {
      imagemSelecionada = null;
    });
  }

  // ============================================================
  // SALVAR PRODUTO
  // ============================================================

  Future<void> salvarProduto() async {
    FocusScope.of(context).unfocus();

    final String nome = nomeController.text.trim();
    final String descricao = descricaoController.text.trim();
    final String categoria = categoriaController.text.trim();

    final String precoTexto = precoController.text
        .trim()
        .replaceAll(',', '.');

    if (nome.isEmpty) {
      _mostrarErro(
        'Digite o nome do produto.',
      );
      return;
    }

    if (precoTexto.isEmpty) {
      _mostrarErro(
        'Digite o preço do produto.',
      );
      return;
    }

    final double? preco = double.tryParse(precoTexto);

    if (preco == null || preco <= 0) {
      _mostrarErro(
        'Digite um preço válido.',
      );
      return;
    }

    if (categoria.isEmpty) {
      _mostrarErro(
        'Informe a categoria do produto.',
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      // ========================================================
      // 1. CRIAR PRODUTO
      // ========================================================

      final Map<String, dynamic> dadosProduto = {
        'restauranteId': widget.restauranteId,
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'categoria': categoria,
        'disponivel': disponivel,
        'destaque': destaque,
      };

      final Map<String, dynamic>? produtoCriado =
          await service.criarProdutoComRetorno(
        dadosProduto,
      );

      if (produtoCriado == null) {
        if (!mounted) return;

        setState(() {
          salvando = false;
        });

        _mostrarErro(
          'Não foi possível cadastrar o produto.',
        );

        return;
      }

      // ========================================================
      // 2. PEGAR ID
      // ========================================================

      final dynamic id = produtoCriado['id'];

      if (id == null) {
        if (!mounted) return;

        setState(() {
          salvando = false;
        });

        _mostrarErro(
          'Produto criado, mas o servidor não retornou o ID.',
        );

        return;
      }

      // ========================================================
      // 3. ENVIAR IMAGEM
      // ========================================================

      if (imagemSelecionada != null) {
        final Map<String, dynamic>? imagemEnviada =
            await service.uploadImagem(
          id.toString(),
          imagemSelecionada!,
        );

        if (imagemEnviada == null) {
          if (!mounted) return;

          setState(() {
            salvando = false;
          });

          await _mostrarAvisoImagem();

          return;
        }
      }

      // ========================================================
      // 4. FINALIZAR
      // ========================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produto cadastrado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        salvando = false;
      });

      _mostrarErro(
        'Erro ao cadastrar produto: $e',
      );
    }
  }

  // ============================================================
  // AVISO UPLOAD DA IMAGEM
  // ============================================================

  Future<void> _mostrarAvisoImagem() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Imagem não enviada',
                ),
              ),
            ],
          ),
          content: const Text(
            'O produto foi cadastrado, mas houve um problema ao enviar a imagem.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: laranja,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Continuar',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _mostrarErro(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================================
  // CATEGORIA
  // ============================================================

  void selecionarCategoria(String categoria) {
    if (salvando) return;

    setState(() {
      categoriaController.text = categoria;
    });
  }

  // ============================================================
  // CONFIRMAR SAÍDA
  // ============================================================

  Future<bool> confirmarSaida() async {
    if (nomeController.text.trim().isEmpty &&
        descricaoController.text.trim().isEmpty &&
        precoController.text.trim().isEmpty &&
        categoriaController.text.trim().isEmpty &&
        imagemSelecionada == null) {
      return true;
    }

    final bool? resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Descartar produto?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Você possui informações preenchidas. Deseja sair sem salvar?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Continuar editando',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Sair',
              ),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        bool didPop,
        dynamic result,
      ) async {
        if (didPop || salvando) return;

        final bool sair = await confirmarSaida();

        if (!mounted) return;

        if (sair) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: fundo,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: salvando
                ? null
                : () async {
                    final bool sair = await confirmarSaida();

                    if (!mounted) return;

                    if (sair) {
                      Navigator.pop(context);
                    }
                  },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.black,
            ),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Novo produto',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Adicione um item ao cardápio',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalho(),

                const SizedBox(height: 20),

                _fotoProduto(),

                const SizedBox(height: 20),

                _informacoesBasicas(),

                const SizedBox(height: 16),

                _categoria(),

                const SizedBox(height: 16),

                _descricao(),

                const SizedBox(height: 16),

                _configuracoes(),

                const SizedBox(height: 20),

                _botaoSalvar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _cabecalho() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDD5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_business_rounded,
            color: laranja,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cadastrar produto',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Preencha as informações abaixo.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOTO
  // ============================================================

  Widget _fotoProduto() {
    if (imagemSelecionada != null) {
      return _fotoSelecionada();
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: salvando ? null : selecionarImagem,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_rounded,
                  color: laranja,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Adicionar foto do produto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Escolha uma imagem da galeria',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Selecionar imagem',
                  style: TextStyle(
                    color: laranja,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
  // FOTO SELECIONADA
  // ============================================================

  Widget _fotoSelecionada() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: .05),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              imagemSelecionada!,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: .45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: salvando ? null : removerImagem,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: salvando ? null : selecionarImagem,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          size: 18,
                          color: laranja,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Trocar foto',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMAÇÕES
  // ============================================================

  Widget _informacoesBasicas() {
    return _cardSecao(
      titulo: 'Informações do produto',
      icone: Icons.info_outline_rounded,
      child: Column(
        children: [
          _campo(
            controller: nomeController,
            label: 'Nome do produto',
            hint: 'Ex: X-Bacon Especial',
            icone: Icons.fastfood_rounded,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _campo(
            controller: precoController,
            label: 'Preço',
            hint: '0,00',
            icone: Icons.attach_money_rounded,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIA
  // ============================================================

  Widget _categoria() {
    return _cardSecao(
      titulo: 'Categoria',
      icone: Icons.category_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _campo(
            controller: categoriaController,
            label: 'Categoria do produto',
            hint: 'Ex: Hambúrguer',
            icone: Icons.category_rounded,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          const Text(
            'Sugestões',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: categoriasSugeridas.map(
              (String categoria) {
                final bool selecionada =
                    categoriaController.text.trim().toLowerCase() ==
                    categoria.toLowerCase();

                return ChoiceChip(
                  label: Text(categoria),
                  selected: selecionada,
                  onSelected: salvando
                      ? null
                      : (_) {
                          selecionarCategoria(categoria);
                        },
                  selectedColor: laranja,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: selecionada
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIÇÃO
  // ============================================================

  Widget _descricao() {
    return _cardSecao(
      titulo: 'Descrição',
      icone: Icons.description_outlined,
      child: _campo(
        controller: descricaoController,
        label: 'Descrição do produto',
        hint: 'Descreva os ingredientes e detalhes do produto...',
        icone: Icons.notes_rounded,
        maxLines: 5,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  // ============================================================
  // CONFIGURAÇÕES
  // ============================================================

  Widget _configuracoes() {
    return _cardSecao(
      titulo: 'Configurações',
      icone: Icons.tune_rounded,
      child: Column(
        children: [
          _switchItem(
            titulo: 'Produto disponível',
            descricao:
                'O produto poderá ser comprado pelos clientes.',
            icone: Icons.visibility_rounded,
            valor: disponivel,
            cor: Colors.green,
            onChanged: (bool valor) {
              setState(() {
                disponivel = valor;
              });
            },
          ),
          const Divider(height: 25),
          _switchItem(
            titulo: 'Produto em destaque',
            descricao: 'Destaque este produto no cardápio.',
            icone: Icons.star_rounded,
            valor: destaque,
            cor: Colors.amber.shade700,
            onChanged: (bool valor) {
              setState(() {
                destaque = valor;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SWITCH
  // ============================================================

  Widget _switchItem({
    required String titulo,
    required String descricao,
    required IconData icone,
    required bool valor,
    required Color cor,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icone,
            color: cor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                descricao,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: valor,
          activeThumbColor: cor,
          onChanged: salvando ? null : onChanged,
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _cardSecao({
    required String titulo,
    required IconData icone,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: .04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icone,
                  color: laranja,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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
    required IconData icone,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: !salvando,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icone,
          color: laranja,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: laranja,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO SALVAR
  // ============================================================

  Widget _botaoSalvar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: salvando ? null : salvarProduto,
        icon: salvando
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.check_rounded,
              ),
        label: Text(
          salvando
              ? 'Cadastrando produto...'
              : 'Cadastrar produto',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: laranja,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          disabledForegroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}