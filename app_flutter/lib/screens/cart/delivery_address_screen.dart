
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

  // ==================================================
  // BUSCAR CEP
  // ==================================================

  Future<void> buscarCep() async {
    final cep =
        cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

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

      if (!mounted) {
        return;
      }

      if (response.statusCode != 200) {
        _mensagem(
          'Não foi possível consultar o CEP.',
        );
        return;
      }

      final dados =
          jsonDecode(response.body);

      if (dados['erro'] == true) {
        _mensagem(
          'CEP não encontrado. Verifique o número informado.',
        );

        ruaController.clear();
        bairroController.clear();
        cidadeController.clear();
        estadoController.clear();

        return;
      }

      setState(() {
        ruaController.text =
            dados['logradouro'] ?? '';

        bairroController.text =
            dados['bairro'] ?? '';

        cidadeController.text =
            dados['localidade'] ?? '';

        estadoController.text =
            dados['uf'] ?? '';
      });

      _mensagem(
        'Endereço encontrado com sucesso!',
      );
    } catch (error) {
      debugPrint(
        'ERRO AO BUSCAR CEP: $error',
      );

      if (!mounted) {
        return;
      }

      _mensagem(
        'Erro ao consultar o CEP. Verifique sua conexão.',
      );
    } finally {
      if (mounted) {
        setState(() {
          buscandoCep = false;
        });
      }
    }
  }

  // ==================================================
  // CONTINUAR PARA PAGAMENTO
  // ==================================================

  void continuar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final endereco = <String, String>{
      'cep': cepController.text.trim(),
      'rua': ruaController.text.trim(),
      'numero': numeroController.text.trim(),
      'bairro': bairroController.text.trim(),
      'complemento':
          complementoController.text.trim(),
      'cidade': cidadeController.text.trim(),
      'estado': estadoController.text.trim(),
    };

    debugPrint(
      '📍 ENDEREÇO INFORMADO: $endereco',
    );

    debugPrint(
      '🛒 ITENS DO CARRINHO: ${widget.itens}',
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

  // ==================================================
  // CAMPO DE TEXTO
  // ==================================================

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    bool obrigatorio = true,
    TextInputType? keyboardType,
    bool somenteLeitura = false,
    Widget? prefixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 15),

      child: TextFormField(
        controller: controller,

        keyboardType: keyboardType,

        readOnly: somenteLeitura,

        onTap: onTap,

        decoration: InputDecoration(
          labelText: label,

          prefixIcon: prefixIcon,

          filled: true,

          fillColor: somenteLeitura
              ? Colors.grey.shade100
              : Colors.white,

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide:
                const BorderSide(
              color: Colors.black12,
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

  // ==================================================
  // MÁSCARA DO CEP
  // ==================================================

  String formatarCep(String valor) {
    final numeros =
        valor.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (numeros.length <= 5) {
      return numeros;
    }

    return '${numeros.substring(0, 5)}-${numeros.substring(5, numeros.length > 8 ? 8 : numeros.length)}';
  }

  // ==================================================
  // CAMPO CEP
  // ==================================================

  Widget campoCep() {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 15),

      child: TextFormField(
        controller: cepController,

        keyboardType:
            TextInputType.number,

        maxLength: 9,

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
                  padding:
                      EdgeInsets.all(12),

                  child:
                      SizedBox(
                    width: 20,
                    height: 20,

                    child:
                        CircularProgressIndicator(
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

                  tooltip:
                      'Buscar CEP',

                  onPressed:
                      buscarCep,
                ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),

            borderSide:
                const BorderSide(
              color: Colors.black12,
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

        onChanged: (valor) {
          final formatado =
              formatarCep(valor);

          if (formatado !=
              cepController.text) {
            cepController.value =
                TextEditingValue(
              text: formatado,

              selection:
                  TextSelection.collapsed(
                offset:
                    formatado.length,
              ),
            );
          }

          final cep =
              formatado.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

          if (cep.length == 8 &&
              !buscandoCep) {
            buscarCep();
          }
        },

        validator: (value) {
          final cep =
              value?.replaceAll(
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

  // ==================================================
  // MENSAGEM
  // ==================================================

  void _mensagem(String mensagem) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),

        duration:
            const Duration(seconds: 3),

        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            Colors.black87,

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: laranja,

        foregroundColor:
            Colors.white,

        elevation: 0,

        title: const Text(
          'Endereço de Entrega',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // TÍTULO
              // ==================================================

              const Text(
                'Onde devemos entregar seu pedido?',

                style: TextStyle(
                  color:
                      Colors.black,

                  fontSize: 22,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Digite seu CEP e encontraremos automaticamente seu endereço.',

                style: TextStyle(
                  color:
                      Colors.grey,

                  fontSize: 15,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // CEP
              // ==================================================

              campoCep(),

              // ==================================================
              // RUA
              // ==================================================

              campoTexto(
                label: 'Rua',
                controller:
                    ruaController,

                somenteLeitura:
                    buscandoCep,

                prefixIcon:
                    const Icon(
                  Icons
                      .signpost_outlined,

                  color:
                      laranja,
                ),
              ),

              // ==================================================
              // NÚMERO
              // ==================================================

              campoTexto(
                label: 'Número',

                controller:
                    numeroController,

                keyboardType:
                    TextInputType
                        .number,

                prefixIcon:
                    const Icon(
                  Icons
                      .numbers_outlined,

                  color:
                      laranja,
                ),
              ),

              // ==================================================
              // BAIRRO
              // ==================================================

              campoTexto(
                label: 'Bairro',

                controller:
                    bairroController,

                somenteLeitura:
                    buscandoCep,

                prefixIcon:
                    const Icon(
                  Icons
                      .location_city_outlined,

                  color:
                      laranja,
                ),
              ),

              // ==================================================
              // COMPLEMENTO
              // ==================================================

              campoTexto(
                label:
                    'Complemento',

                controller:
                    complementoController,

                obrigatorio:
                    false,

                prefixIcon:
                    const Icon(
                  Icons
                      .home_work_outlined,

                  color:
                      laranja,
                ),
              ),

              // ==================================================
              // CIDADE
              // ==================================================

              campoTexto(
                label:
                    'Cidade',

                controller:
                    cidadeController,

                somenteLeitura:
                    buscandoCep,

                prefixIcon:
                    const Icon(
                  Icons
                      .location_city,

                  color:
                      laranja,
                ),
              ),

              // ==================================================
              // ESTADO
              // ==================================================

              campoTexto(
                label:
                    'Estado',

                controller:
                    estadoController,

                somenteLeitura:
                    buscandoCep,

                prefixIcon:
                    const Icon(
                  Icons
                      .map_outlined,

                  color:
                      laranja,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // BOTÃO CONTINUAR
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      buscandoCep
                          ? null
                          : continuar,

                  icon:
                      const Icon(
                    Icons
                        .arrow_forward,
                  ),

                  label:
                      const Text(
                    'CONTINUAR',

                    style:
                        TextStyle(
                      fontSize:
                          16,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        laranja,

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        Colors.orange
                            .shade200,

                    disabledForegroundColor:
                        Colors.white,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 16,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // AVISO
              // ==================================================

              Center(
                child: Text(
                  'Seu endereço será utilizado apenas para realizar a entrega.',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        Colors.grey
                            .shade600,

                    fontSize:
                        12,
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

