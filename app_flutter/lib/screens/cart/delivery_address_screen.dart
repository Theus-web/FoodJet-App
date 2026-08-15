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
  final _formKey = GlobalKey<FormState>();

  static const Color laranja = Color(0xFFF97316);
  static const Color fundo = Color(0xFFF7F7F8);

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

      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode != 200) {
        _mensagem(
          'Não foi possível consultar o CEP.',
          erro: true,
        );
        return;
      }

      final dados = jsonDecode(response.body);

      if (dados['erro'] == true) {
        _mensagem(
          'CEP não encontrado. Verifique o número informado.',
          erro: true,
        );

        ruaController.clear();
        bairroController.clear();
        cidadeController.clear();
        estadoController.clear();

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
        'Endereço encontrado!',
      );
    } catch (error) {
      debugPrint(
        'ERRO AO BUSCAR CEP: $error',
      );

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
    if (!_formKey.currentState!.validate()) {
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

    debugPrint(
      '📍 ENDEREÇO INFORMADO: $endereco',
    );

    debugPrint(
      '🛒 ITENS: ${widget.itens}',
    );

    debugPrint(
      '💰 SUBTOTAL: ${widget.subtotal}',
    );

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
  // FORMATAR CEP
  // ============================================================

  String formatarCep(String valor) {
    final numeros = valor.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (numeros.length <= 5) {
      return numeros;
    }

    return '${numeros.substring(0, 5)}-${numeros.substring(
      5,
      numeros.length > 8 ? 8 : numeros.length,
    )}';
  }

  // ============================================================
  // CAMPO CEP
  // ============================================================

  Widget campoCep() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: cepController,
        keyboardType: TextInputType.number,
        maxLength: 9,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: 'CEP',
          hintText: '00000-000',
          counterText: '',
          prefixIcon: const Icon(
            Icons.location_on_rounded,
            color: laranja,
          ),
          suffixIcon: buscandoCep
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: laranja,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: buscarCep,
                  tooltip: 'Buscar CEP',
                  icon: const Icon(
                    Icons.search_rounded,
                    color: laranja,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFE7E7E7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: laranja,
              width: 1.8,
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
  // CAMPO
  // ============================================================

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    bool obrigatorio = true,
    TextInputType? keyboardType,
    bool somenteLeitura = false,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: somenteLeitura,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: somenteLeitura
                ? Colors.grey
                : laranja,
          ),
          filled: true,
          fillColor: somenteLeitura
              ? const Color(0xFFF0F0F0)
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Color(0xFFE7E7E7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: laranja,
              width: 1.8,
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
  // MENSAGEM
  // ============================================================

  void _mensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              erro
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(mensagem),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            erro ? Colors.redAccent : laranja,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget resumoPedido() {
    final quantidade = widget.itens.fold<int>(
      0,
      (total, item) => total + item.quantidade,
    );

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: laranja.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: laranja,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo do pedido',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantidade ${quantidade == 1 ? 'item' : 'itens'} no carrinho',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${widget.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: laranja,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        centerTitle: false,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço de entrega',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Para onde vamos enviar?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            20,
            18,
            35,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // CABEÇALHO
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      laranja,
                      Colors.orange.shade400,
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
                      blurRadius: 15,
                      offset:
                          const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .location_on_rounded,
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
                            'Onde devemos entregar?',
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Informe seu endereço para continuar o pedido.',
                            style: TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // RESUMO PEDIDO
              // ==================================================

              resumoPedido(),

              const SizedBox(height: 25),

              const Text(
                'Seu endereço',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Digite seu CEP e confirme os dados da entrega.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CEP
              // ==================================================

              campoCep(),

              // ==================================================
              // RUA
              // ==================================================

              campoTexto(
                label: 'Rua',
                controller: ruaController,
                somenteLeitura: buscandoCep,
                icon:
                    Icons.signpost_rounded,
              ),

              // ==================================================
              // NÚMERO
              // ==================================================

              campoTexto(
                label: 'Número',
                controller:
                    numeroController,
                keyboardType:
                    TextInputType.number,
                icon:
                    Icons.numbers_rounded,
              ),

              // ==================================================
              // BAIRRO
              // ==================================================

              campoTexto(
                label: 'Bairro',
                controller:
                    bairroController,
                somenteLeitura: buscandoCep,
                icon:
                    Icons.location_city_rounded,
              ),

              // ==================================================
              // COMPLEMENTO
              // ==================================================

              campoTexto(
                label: 'Complemento',
                controller:
                    complementoController,
                obrigatorio: false,
                icon:
                    Icons.home_work_rounded,
              ),

              // ==================================================
              // CIDADE
              // ==================================================

              campoTexto(
                label: 'Cidade',
                controller:
                    cidadeController,
                somenteLeitura: buscandoCep,
                icon:
                    Icons.location_city_rounded,
              ),

              // ==================================================
              // ESTADO
              // ==================================================

              campoTexto(
                label: 'Estado',
                controller:
                    estadoController,
                somenteLeitura: buscandoCep,
                icon:
                    Icons.map_rounded,
              ),

              const SizedBox(height: 8),

              // ==================================================
              // BOTÃO
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      buscandoCep
                          ? null
                          : continuar,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    disabledBackgroundColor:
                        Colors.orange.shade200,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Text(
                        'CONTINUAR PARA PAGAMENTO',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 30,
                        height: 30,
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.18,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // SEGURANÇA
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .lock_outline_rounded,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Seu endereço será utilizado somente para realizar a entrega.',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 11.5,
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