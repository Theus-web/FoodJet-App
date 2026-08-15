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
      text: widget.produto.preco.toString(),
    );

    categoria = widget.produto.categoria;
    disponivel = widget.produto.disponivel;
    destaque = widget.produto.destaque;
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final sucesso = await service.atualizarProduto(
        widget.produto.id,
        {
          "nome": nomeController.text.trim(),
          "descricao": descricaoController.text.trim(),
          "preco": double.tryParse(
                precoController.text.replaceAll(",", "."),
              ) ??
              0,
          "categoria": categoria,
          "disponivel": disponivel,
          "destaque": destaque,
        },
      );

      if (!mounted) return;

      if (sucesso) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao atualizar produto."),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Produto"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome",
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Informe o nome";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  labelText: "Descrição",
                ),
              ),
              TextFormField(
                controller: precoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Preço",
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: categoria,
                decoration: const InputDecoration(
                  labelText: "Categoria",
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Lanches",
                    child: Text("Lanches"),
                  ),
                  DropdownMenuItem(
                    value: "Pizzas",
                    child: Text("Pizzas"),
                  ),
                  DropdownMenuItem(
                    value: "Bebidas",
                    child: Text("Bebidas"),
                  ),
                  DropdownMenuItem(
                    value: "Doces",
                    child: Text("Doces"),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;

                  setState(() {
                    categoria = v;
                  });
                },
              ),
              SwitchListTile(
                title: const Text("Disponível"),
                value: disponivel,
                onChanged: (v) {
                  setState(() {
                    disponivel = v;
                  });
                },
              ),
              SwitchListTile(
                title: const Text("Produto destaque"),
                value: destaque,
                onChanged: (v) {
                  setState(() {
                    destaque = v;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                ),
                onPressed: salvar,
                child: const Text(
                  "Salvar alterações",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    precoController.dispose();
    super.dispose();
  }
}