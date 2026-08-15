
import 'package:flutter/material.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({
    super.key,
  });

  @override
  State<MyAddressesScreen> createState() =>
      _MyAddressesScreenState();
}

class _MyAddressesScreenState
    extends State<MyAddressesScreen> {
  final List<Map<String, String>> enderecos = [];

  @override
  Widget build(BuildContext context) {
    const Color laranja = Color(0xFFF97316);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Meus endereços',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: enderecos.isEmpty
          ? _telaSemEndereco()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: enderecos.length,
              itemBuilder: (context, index) {
                final endereco = enderecos[index];

                return _cardEndereco(
                  endereco,
                  index,
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: laranja,
        foregroundColor: Colors.white,

        onPressed: _adicionarEndereco,

        icon: const Icon(
          Icons.add_location_alt_outlined,
        ),

        label: const Text(
          'Adicionar endereço',
        ),
      ),
    );
  }

  Widget _telaSemEndereco() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 90,
              height: 90,

              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.location_on_outlined,
                size: 50,
                color: Color(0xFFF97316),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nenhum endereço cadastrado',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Adicione um endereço para facilitar suas próximas entregas.',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: _adicionarEndereco,

              icon: const Icon(
                Icons.add_location_alt_outlined,
              ),

              label: const Text(
                'Adicionar endereço',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFF97316),

                foregroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 14,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardEndereco(
    Map<String, String> endereco,
    int index,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 15),

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 45,
            height: 45,

            decoration: BoxDecoration(
              color: Colors.orange.shade50,

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFFF97316),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  endereco['nome'] ??
                      'Endereço',

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  endereco['endereco'] ??
                      '',

                  style:
                      const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (valor) {
              if (valor == 'excluir') {
                setState(() {
                  enderecos.removeAt(index);
                });
              }
            },

            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'excluir',
                  child: Text(
                    'Excluir',
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  void _adicionarEndereco() {
    final nomeController =
        TextEditingController();

    final enderecoController =
        TextEditingController();

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.white,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                    24,
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Adicionar endereço',

                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller:
                    nomeController,

                decoration:
                    InputDecoration(
                  labelText:
                      'Nome do endereço',

                  hintText:
                      'Ex.: Casa',

                  prefixIcon:
                      const Icon(
                    Icons.home_outlined,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    enderecoController,

                maxLines: 3,

                decoration:
                    InputDecoration(
                  labelText:
                      'Endereço completo',

                  hintText:
                      'Rua, número, bairro, cidade',

                  prefixIcon:
                      const Icon(
                    Icons.location_on_outlined,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width:
                    double.infinity,

                child:
                    ElevatedButton(
                  onPressed: () {
                    if (nomeController
                            .text
                            .trim()
                            .isEmpty ||
                        enderecoController
                            .text
                            .trim()
                            .isEmpty) {
                      return;
                    }

                    setState(() {
                      enderecos.add({
                        'nome':
                            nomeController
                                .text
                                .trim(),

                        'endereco':
                            enderecoController
                                .text
                                .trim(),
                      });
                    });

                    Navigator.pop(context);
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFF97316,
                    ),

                    foregroundColor:
                        Colors.white,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 15,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Salvar endereço',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

