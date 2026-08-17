import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel produto;

  const EditProductScreen({
    super.key,
    required this.produto,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService service = ProductService();

  final _formKey = GlobalKey<FormState>();

  late TextEditingController nomeController;
  late TextEditingController descricaoController;
  late TextEditingController precoController;

  late String categoria;
  late bool disponivel;
  late bool destaque;

  // ============================================================
  // CATEGORIAS DO FOODJET
  // ============================================================

  static const List<String> categorias = [
    'Hambúrguer',
    'Pizza',
    'Lanches',
    'Porções',
    'Bebidas',
    'Sobremesas',
    'Combos',
    'Pratos',
    'Açaí',
    'Japonês',
    'Outros',
  ];

  static const Color laranja = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();

    nomeController = TextEditingController(
      text: widget.produto.nome,
    );

    descricaoController = TextEditingController(
      text: widget.produto.descricao,
    );

    precoController = TextEditingController(
      text: widget.produto.preco.toStringAsFixed(2),
    );

    // ==========================================================
    // CORREÇÃO DO DROPDOWN
    //
    // Se o produto já possui uma categoria válida,
    // usamos ela.
    //
    // Se vier uma categoria antiga que não está na lista,
    // adicionamos temporariamente à lista para evitar
    // o erro do DropdownButton.
    // ==========================================================

    final String categoriaProduto =
        widget.produto.categoria.trim();

    if (categoriaProduto.isEmpty) {
      categoria = categorias.first;
    } else {
      categoria = categoriaProduto;
    }

    disponivel = widget.produto.disponivel;
    destaque = widget.produto.destaque;
  }

  // ============================================================
  // LISTA SEGURA DE CATEGORIAS
  // ============================================================

  List<String> get categoriasDropdown {
    final List<String> lista = [
      ...categorias,
    ];

    // Se existir uma categoria antiga no banco
    // que não está mais na lista padrão,
    // adicionamos ela para o produto continuar editável.
    if (categoria.trim().isNotEmpty &&
        !lista.contains(categoria.trim())) {
      lista.add(categoria.trim());
    }

    // Remove duplicadas
    return lista.toSet().toList();
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<void> salvar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? preco = double.tryParse(
      precoController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe um preço válido.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {
      final sucesso = await service.atualizarProduto(
        widget.produto.id,
        {
          "nome": nomeController.text.trim(),
          "descricao": descricaoController.text.trim(),
          "preco": preco,
          "categoria": categoria,
          "disponivel": disponivel,
          "destaque": destaque,
        },
      );

      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Produto atualizado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro ao atualizar produto.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

        title: const Text(
          "Editar Produto",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Form(
            key: _formKey,

            child: ListView(
              children: [

                // ==================================================
                // NOME
                // ==================================================

                TextFormField(
                  controller: nomeController,

                  textCapitalization:
                      TextCapitalization.words,

                  decoration: InputDecoration(
                    labelText: "Nome do produto",
                    prefixIcon: const Icon(
                      Icons.fastfood_rounded,
                      color: laranja,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: laranja,
                        width: 1.5,
                      ),
                    ),
                  ),

                  validator: (v) {
                    if (v == null ||
                        v.trim().isEmpty) {
                      return "Informe o nome";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // DESCRIÇÃO
                // ==================================================

                TextFormField(
                  controller: descricaoController,

                  textCapitalization:
                      TextCapitalization.sentences,

                  maxLines: 4,

                  decoration: InputDecoration(
                    labelText: "Descrição",
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                      color: laranja,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    alignLabelWithHint: true,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: laranja,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PREÇO
                // ==================================================

                TextFormField(
                  controller: precoController,

                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  decoration: InputDecoration(
                    labelText: "Preço",
                    hintText: "0,00",

                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      color: laranja,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: laranja,
                        width: 1.5,
                      ),
                    ),
                  ),

                  validator: (v) {
                    if (v == null ||
                        v.trim().isEmpty) {
                      return "Informe o preço";
                    }

                    final valor =
                        double.tryParse(
                      v.replaceAll(',', '.'),
                    );

                    if (valor == null ||
                        valor <= 0) {
                      return "Preço inválido";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // CATEGORIA
                // ==================================================

                DropdownButtonFormField<String>(
                  initialValue: categoria,

                  isExpanded: true,

                  decoration: InputDecoration(
                    labelText: "Categoria",

                    prefixIcon: const Icon(
                      Icons.category_rounded,
                      color: laranja,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: laranja,
                        width: 1.5,
                      ),
                    ),
                  ),

                  items: categoriasDropdown
                      .map(
                        (String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        },
                      )
                      .toList(),

                  onChanged: (String? valor) {
                    if (valor == null) return;

                    setState(() {
                      categoria = valor;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // DISPONIBILIDADE
                // ==================================================

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(15),
                  ),

                  child: SwitchListTile(
                    title: const Text(
                      "Produto disponível",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: const Text(
                      "O produto poderá ser comprado pelos clientes.",
                    ),

                    secondary: const Icon(
                      Icons.visibility_rounded,
                      color: Colors.green,
                    ),

                    value: disponivel,

                    activeThumbColor: Colors.green,

                    onChanged: (v) {
                      setState(() {
                        disponivel = v;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // DESTAQUE
                // ==================================================

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(15),
                  ),

                  child: SwitchListTile(
                    title: const Text(
                      "Produto em destaque",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: const Text(
                      "Exibir o produto como destaque.",
                    ),

                    secondary: Icon(
                      Icons.star_rounded,
                      color: Colors.amber.shade700,
                    ),

                    value: destaque,

                    activeThumbColor:
                        Colors.amber.shade700,

                    onChanged: (v) {
                      setState(() {
                        destaque = v;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // BOTÃO SALVAR
                // ==================================================

                SizedBox(
                  height: 55,
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: salvar,

                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                    ),

                    label: const Text(
                      "Salvar alterações",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: laranja,

                      elevation: 2,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
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
    precoController.dispose();

    super.dispose();
  }
}