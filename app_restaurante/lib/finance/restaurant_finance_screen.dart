import 'package:flutter/material.dart';

import '../services/finance_service.dart';


class RestaurantFinanceScreen
    extends StatefulWidget {

  final String restauranteId;

  const RestaurantFinanceScreen({

    super.key,

    required this.restauranteId,

  });


  @override
  State<RestaurantFinanceScreen> createState() =>
      _RestaurantFinanceScreenState();
}


class _RestaurantFinanceScreenState
    extends State<RestaurantFinanceScreen> {

  final FinanceService _service =
      FinanceService();


  bool carregando = true;


  Map<String, dynamic>? dados;


  @override
  void initState() {

    super.initState();

    carregarFinanceiro();

  }


  // =====================================================
  // CARREGAR
  // =====================================================

  Future<void> carregarFinanceiro() async {

    setState(() {

      carregando = true;

    });


    try {

      final resultado =
          await _service.buscarResumo(
        widget.restauranteId,
      );


      if (!mounted) return;


      setState(() {

        dados = resultado;

        carregando = false;

      });


    } catch (e) {

      if (!mounted) return;


      setState(() {

        carregando = false;

      });


      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(
            "Erro ao carregar ganhos: $e",
          ),

        ),

      );

    }

  }


  // =====================================================
  // FORMATAR VALOR
  // =====================================================

  String dinheiro(dynamic valor) {

    final numero =
        double.tryParse(
          valor.toString(),
        ) ??
        0.0;


    return "R\$ ${numero.toStringAsFixed(2)}";
  }


  // =====================================================
  // SAQUE
  // =====================================================

  Future<void> abrirSaque() async {

    final valorController =
        TextEditingController();


    final chaveController =
        TextEditingController();


    String metodo = "PIX";


    await showDialog(

      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (
            context,
            setDialogState,
          ) {

            return AlertDialog(

              title:
                  const Text(
                "Solicitar saque",
              ),


              content:

                  SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    Text(

                      "Saldo disponível: "
                      "${dinheiro(
                        dados?["saldoDisponivel"],
                      )}",

                    ),


                    const SizedBox(
                      height: 20,
                    ),


                    TextField(

                      controller:
                          valorController,

                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Valor do saque",

                        prefixText:
                            "R\$ ",

                        border:
                            OutlineInputBorder(),

                      ),

                    ),


                    const SizedBox(
                      height: 15,
                    ),


                    DropdownButtonFormField<String>(

                      value: metodo,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Método",

                        border:
                            OutlineInputBorder(),

                      ),

                      items: const [

                        DropdownMenuItem(

                          value: "PIX",

                          child:
                              Text("PIX"),

                        ),

                        DropdownMenuItem(

                          value: "TRANSFERENCIA",

                          child:
                              Text(
                            "Transferência",
                          ),

                        ),

                      ],


                      onChanged: (valor) {

                        if (valor == null) {
                          return;
                        }

                        setDialogState(() {

                          metodo = valor;

                        });

                      },

                    ),


                    const SizedBox(
                      height: 15,
                    ),


                    TextField(

                      controller:
                          chaveController,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Chave PIX / Conta",

                        border:
                            OutlineInputBorder(),

                      ),

                    ),

                  ],

                ),

              ),


              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(context);

                  },

                  child:
                      const Text(
                    "Cancelar",
                  ),

                ),


                ElevatedButton(

                  onPressed: () async {

                    final valor =
                        double.tryParse(
                      valorController.text
                          .replaceAll(
                            ",",
                            ".",
                          ),
                    );


                    if (valor == null ||
                        valor <= 0) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(

                        const SnackBar(

                          content:
                              Text(
                            "Digite um valor válido",
                          ),

                        ),

                      );

                      return;

                    }


                    if (
                        chaveController
                            .text
                            .trim()
                            .isEmpty) {

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(

                        const SnackBar(

                          content:
                              Text(
                            "Informe a chave PIX ou conta",
                          ),

                        ),

                      );

                      return;

                    }


                    try {

                      await _service.solicitarSaque(

                        restauranteId:
                            widget.restauranteId,

                        valor:
                            valor,

                        metodo:
                            metodo,

                        chave:
                            chaveController.text
                                .trim(),

                      );


                      if (!mounted) {
                        return;
                      }


                      Navigator.pop(
                        context,
                      );


                      await carregarFinanceiro();


                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(

                        const SnackBar(

                          content:
                              Text(
                            "Saque solicitado com sucesso!",
                          ),

                        ),

                      );


                    } catch (e) {

                      if (!mounted) {
                        return;
                      }


                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(

                        SnackBar(

                          content:
                              Text(
                            "$e",
                          ),

                        ),

                      );

                    }

                  },

                  child:
                      const Text(
                    "Solicitar",
                  ),

                ),

              ],

            );

          },

        );

      },

    );

  }


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(0xfff5f5f5),


      appBar: AppBar(

        title:
            const Text(
          "Ganhos",
        ),

        backgroundColor:
            Colors.white,

        foregroundColor:
            Colors.black,

        elevation: 0,

        actions: [

          IconButton(

            onPressed:
                carregarFinanceiro,

            icon:
                const Icon(
              Icons.refresh,
            ),

          ),

        ],

      ),


      body:

          carregando

              ? const Center(

                  child:
                      CircularProgressIndicator(),

                )

              : RefreshIndicator(

                  onRefresh:
                      carregarFinanceiro,

                  child:
                      SingleChildScrollView(

                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.all(16),

                    child:
                        Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        _saldoCard(),


                        const SizedBox(
                          height: 20,
                        ),


                        const Text(

                          "Resumo financeiro",

                          style:
                              TextStyle(

                            fontSize: 21,

                            fontWeight:
                                FontWeight.bold,

                          ),

                        ),


                        const SizedBox(
                          height: 12,
                        ),


                        Row(

                          children: [

                            _card(

                              "Faturamento",

                              dinheiro(
                                dados?[
                                  "faturamentoTotal"
                                ],
                              ),

                              Icons
                                  .account_balance_wallet,

                            ),


                            _card(

                              "Repassado",

                              dinheiro(
                                dados?[
                                  "totalRepassado"
                                ],
                              ),

                              Icons
                                  .check_circle,

                            ),

                          ],

                        ),


                        Row(

                          children: [

                            _card(

                              "Pendente",

                              dinheiro(
                                dados?[
                                  "totalPendente"
                                ],
                              ),

                              Icons
                                  .schedule,

                            ),


                            _card(

                              "Pedidos",

                              "${dados?[
                                "pedidosConcluidos"
                              ] ?? 0}",

                              Icons
                                  .shopping_bag,

                            ),

                          ],

                        ),


                        const SizedBox(
                          height: 10,
                        ),


                        _ticketCard(),


                        const SizedBox(
                          height: 25,
                        ),


                        SizedBox(

                          width:
                              double.infinity,

                          height: 55,

                          child:
                              ElevatedButton.icon(

                            onPressed:
                                abrirSaque,

                            icon:
                                const Icon(
                              Icons.payments,
                            ),

                            label:
                                const Text(
                              "Solicitar saque / repasse",
                            ),

                            style:
                                ElevatedButton.styleFrom(

                              backgroundColor:
                                  const Color(
                                0xFFF97316,
                              ),

                              foregroundColor:
                                  Colors.white,

                              shape:
                                  RoundedRectangleBorder(

                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),

                              ),

                            ),

                          ),

                        ),


                        const SizedBox(
                          height: 30,
                        ),


                        const Text(

                          "Histórico de repasses",

                          style:
                              TextStyle(

                            fontSize: 21,

                            fontWeight:
                                FontWeight.bold,

                          ),

                        ),


                        const SizedBox(
                          height: 12,
                        ),


                        _historico(),

                      ],

                    ),

                  ),

                ),

    );

  }


  // =====================================================
  // SALDO
  // =====================================================

  Widget _saldoCard() {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(24),

      decoration:
          BoxDecoration(

        gradient:
            const LinearGradient(

          colors: [

            Color(0xFFF97316),

            Color(0xFFFF9A56),

          ],

        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),

      ),

      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "Saldo disponível",

            style:
                TextStyle(

              color:
                  Colors.white70,

              fontSize: 15,

            ),

          ),


          const SizedBox(
            height: 8,
          ),


          Text(

            dinheiro(
              dados?[
                "saldoDisponivel"
              ],
            ),

            style:
                const TextStyle(

              color:
                  Colors.white,

              fontSize: 32,

              fontWeight:
                  FontWeight.bold,

            ),

          ),


          const SizedBox(
            height: 8,
          ),


          const Text(

            "Disponível para saque",

            style:
                TextStyle(

              color:
                  Colors.white70,

            ),

          ),

        ],

      ),

    );

  }


  // =====================================================
  // CARD
  // =====================================================

  Widget _card(

    String titulo,

    String valor,

    IconData icone,

  ) {

    return Expanded(

      child:
          Container(

        margin:
            const EdgeInsets.all(6),

        padding:
            const EdgeInsets.all(18),

        decoration:
            BoxDecoration(

          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            20,
          ),

        ),

        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Icon(

              icone,

              color:
                  const Color(
                0xFFF97316,
              ),

            ),


            const SizedBox(
              height: 12,
            ),


            Text(

              valor,

              style:
                  const TextStyle(

                fontSize: 18,

                fontWeight:
                    FontWeight.bold,

              ),

            ),


            const SizedBox(
              height: 4,
            ),


            Text(

              titulo,

              style:
                  const TextStyle(

                color:
                    Colors.grey,

                fontSize: 13,

              ),

            ),

          ],

        ),

      ),

    );

  }


  // =====================================================
  // TICKET MÉDIO
  // =====================================================

  Widget _ticketCard() {

    return Container(

      width:
          double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

      ),

      child:
          Row(

        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [

          const Text(

            "Ticket médio",

            style:
                TextStyle(

              fontSize: 17,

              fontWeight:
                  FontWeight.bold,

            ),

          ),


          Text(

            dinheiro(
              dados?[
                "ticketMedio"
              ],
            ),

            style:
                const TextStyle(

              color:
                  Color(0xFFF97316),

              fontSize: 18,

              fontWeight:
                  FontWeight.bold,

            ),

          ),

        ],

      ),

    );

  }


  // =====================================================
  // HISTÓRICO
  // =====================================================

  Widget _historico() {

    final lista =
        dados?["historico"];


    if (lista == null ||
        lista is! List ||
        lista.isEmpty) {

      return Container(

        width:
            double.infinity,

        padding:
            const EdgeInsets.all(25),

        decoration:
            BoxDecoration(

          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            20,
          ),

        ),

        child:
            const Column(

          children: [

            Icon(

              Icons.receipt_long,

              size: 50,

              color:
                  Colors.grey,

            ),


            SizedBox(
              height: 10,
            ),


            Text(
              "Nenhum repasse ainda",
            ),

          ],

        ),

      );

    }


    return Column(

      children:

          lista.map<Widget>(

        (item) {

          final valor =
              item["valor"];


          final status =
              item["status"] ??
                  "PENDENTE";


          final statusPago =
              status == "PAGO";


          return Container(

            margin:
                const EdgeInsets.only(
              bottom: 10,
            ),

            padding:
                const EdgeInsets.all(
              16,
            ),

            decoration:
                BoxDecoration(

              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

            ),

            child:
                Row(

              children: [

                CircleAvatar(

                  backgroundColor:
                      statusPago

                          ? Colors.green
                              .withValues(
                            alpha: 0.12,
                          )

                          : Colors.orange
                              .withValues(
                            alpha: 0.12,
                          ),

                  child:
                      Icon(

                    statusPago
                        ? Icons
                            .check_circle
                        : Icons.schedule,

                    color:
                        statusPago
                            ? Colors.green
                            : Colors.orange,

                  ),

                ),


                const SizedBox(
                  width: 14,
                ),


                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(

                        "Repasse",

                        style:
                            const TextStyle(

                          fontWeight:
                              FontWeight.bold,

                        ),

                      ),


                      const SizedBox(
                        height: 5,
                      ),


                      Text(

                        "${item["metodo"] ?? "PIX"}",

                        style:
                            const TextStyle(

                          color:
                              Colors.grey,

                        ),

                      ),

                    ],

                  ),

                ),


                Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.end,

                  children: [

                    Text(

                      dinheiro(
                        valor,
                      ),

                      style:
                          const TextStyle(

                        fontWeight:
                            FontWeight.bold,

                        color:
                            Color(
                          0xFFF97316,
                        ),

                      ),

                    ),


                    const SizedBox(
                      height: 4,
                    ),


                    Text(

                      status,

                      style:
                          TextStyle(

                        fontSize: 12,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            statusPago
                                ? Colors.green
                                : Colors.orange,

                      ),

                    ),

                  ],

                ),

              ],

            ),

          );

        },

      ).toList(),

    );

  }

}