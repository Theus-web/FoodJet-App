import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'payment_screen.dart';
import 'cart_screen.dart';

class DeliveryAddressScreen extends StatefulWidget {
  final List<CartItem> itens;
  final double subtotal;

  const DeliveryAddressScreen({
    super.key,
    required this.itens,
    required this.subtotal,
  });

  @override
  State<DeliveryAddressScreen> createState() =>
      _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState
    extends State<DeliveryAddressScreen> {
  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF5F5F5);

  final _formKey = GlobalKey<FormState>();

  final cepController = TextEditingController();
  final ruaController = TextEditingController();
  final numeroController = TextEditingController();
  final bairroController = TextEditingController();
  final complementoController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();

  bool buscandoCep = false;

  @override
  void dispose() {
    cepController.dispose();
    ruaController.dispose();
    numeroController.dispose();
    bairroController.dispose();
    complementoController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUSCAR CEP
  // ============================================================

  Future<void> buscarCep() async {
    final cep = cepController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cep.length != 8) {
      _mensagem('Digite um CEP válido.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      buscandoCep = true;
    });

    try {
      final url = Uri.parse(
        'https://viacep.com.br/ws/$cep/json/',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
          );

      if (!mounted) return;

      if (response.statusCode != 200) {
        _mensagem(
          'Não foi possível consultar o CEP.',
          erro: true,
        );
        return;
      }

      final dados = jsonDecode(response.body);

      if (dados is! Map<String, dynamic>) {
        _mensagem(
          'Resposta inválida do serviço de CEP.',
          erro: true,
        );
        return;
      }

      if (dados['erro'] == true) {
        ruaController.clear();
        bairroController.clear();
        cidadeController.clear();
        estadoController.clear();

        _mensagem(
          'CEP não encontrado. Verifique o número informado.',
          erro: true,
        );

        return;
      }

      setState(() {
        ruaController.text =
            dados['logradouro']?.toString() ?? '';

        bairroController.text =
            dados['bairro']?.toString() ?? '';

        cidadeController.text =
            dados['localidade']?.toString() ?? '';

        estadoController.text =
            dados['uf']?.toString() ?? '';
      });

      _mensagem(
        'Endereço encontrado com sucesso!',
      );
    } catch (e) {
      debugPrint('ERRO AO BUSCAR CEP: $e');

      if (!mounted) return;

      _mensagem(
        'Erro ao consultar o CEP. Verifique sua conexão.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          buscandoCep = false;
        });
      }
    }
  }

  // ============================================================
  // CONTINUAR
  // ============================================================

  void continuar() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.itens.isEmpty) {
      _mensagem(
        'Seu carrinho está vazio.',
        erro: true,
      );
      return;
    }

    final endereco = <String, String>{
      'cep': cepController.text.trim(),
      'rua': ruaController.text.trim(),
      'numero': numeroController.text.trim(),
      'bairro': bairroController.text.trim(),
      'complemento': complementoController.text.trim(),
      'cidade': cidadeController.text.trim(),
      'estado': estadoController.text.trim(),
    };

    debugPrint('========================================');
    debugPrint('📍 ENDEREÇO DE ENTREGA');
    debugPrint('$endereco');
    debugPrint('🛒 ITENS: ${widget.itens.length}');
    debugPrint('💰 SUBTOTAL: ${widget.subtotal}');
    debugPrint('========================================');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          endereco: endereco,
          itens: widget.itens,
          subtotal: widget.subtotal,
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO
  // ============================================================

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    bool obrigatorio = true,
    TextInputType? keyboardType,
    bool somenteLeitura = false,
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: somenteLeitura,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
          filled: true,
          fillColor:
              somenteLeitura ? Colors.grey.shade100 : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.black12,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: laranja,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
        ),
        validator: obrigatorio
            ? (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Informe $label';
                }

                return null;
              }
            : null,
      ),
    );
  }

  // ============================================================
  // CEP
  // ============================================================

  String formatarCep(String valor) {
    final numeros = valor.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (numeros.length <= 5) {
      return numeros;
    }

    final parte1 = numeros.substring(0, 5);
    final parte2 = numeros.substring(
      5,
      numeros.length > 8 ? 8 : numeros.length,
    );

    return '$parte1-$parte2';
  }

  Widget campoCep() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: cepController,
        keyboardType: TextInputType.number,
        maxLength: 9,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'CEP',
          hintText: '00000-000',
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(
            Icons.location_on_outlined,
            color: laranja,
          ),
          suffixIcon: buscandoCep
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: laranja,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: laranja,
                  ),
                  tooltip: 'Buscar CEP',
                  onPressed: buscarCep,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.black12,
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
        onChanged: (valor) {
          final formatado = formatarCep(valor);

          if (formatado != cepController.text) {
            cepController.value = TextEditingValue(
              text: formatado,
              selection: TextSelection.collapsed(
                offset: formatado.length,
              ),
            );
          }

          final cep = formatado.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

          if (cep.length == 8 && !buscandoCep) {
            buscarCep();
          }
        },
        validator: (value) {
          final cep = value?.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              ) ??
              '';

          if (cep.isEmpty) {
            return 'Informe o CEP';
          }

          if (cep.length != 8) {
            return 'Informe um CEP válido';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            erro ? Colors.red.shade700 : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Endereço de Entrega',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Onde devemos entregar seu pedido?',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Digite seu CEP e encontraremos automaticamente seu endereço.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 25),

              campoCep(),

              campoTexto(
                label: 'Rua',
                controller: ruaController,
                somenteLeitura: buscandoCep,
                prefixIcon: const Icon(
                  Icons.signpost_outlined,
                  color: laranja,
                ),
              ),

              campoTexto(
                label: 'Número',
                controller: numeroController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.numbers_outlined,
                  color: laranja,
                ),
              ),

              campoTexto(
                label: 'Bairro',
                controller: bairroController,
                somenteLeitura: buscandoCep,
                prefixIcon: const Icon(
                  Icons.location_city_outlined,
                  color: laranja,
                ),
              ),

              campoTexto(
                label: 'Complemento',
                controller: complementoController,
                obrigatorio: false,
                prefixIcon: const Icon(
                  Icons.home_work_outlined,
                  color: laranja,
                ),
              ),

              campoTexto(
                label: 'Cidade',
                controller: cidadeController,
                somenteLeitura: buscandoCep,
                prefixIcon: const Icon(
                  Icons.location_city,
                  color: laranja,
                ),
              ),

              campoTexto(
                label: 'Estado',
                controller: estadoController,
                somenteLeitura: buscandoCep,
                prefixIcon: const Icon(
                  Icons.map_outlined,
                  color: laranja,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      buscandoCep ? null : continuar,
                  icon: const Icon(
                    Icons.arrow_forward,
                  ),
                  label: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.orange.shade200,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  'Seu endereço será utilizado apenas para realizar a entrega.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}