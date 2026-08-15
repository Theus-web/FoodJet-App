import 'package:flutter/material.dart';

import '../login/login_screen.dart';
import '../favorites/favorites_screen.dart';
import '../orders/order_history_screen.dart';
import '../address/my_addresses_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const ProfileScreen({
    super.key,
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    const Color laranja = Color(0xFFF97316);

    // ==============================
    // DADOS REAIS DO USUÁRIO
    // ==============================

    final String nome =
        usuario['nome']?.toString() ?? 'Usuário';

    final String email =
        usuario['email']?.toString() ??
        'E-mail não informado';

    final String telefone =
        usuario['telefone']?.toString() ??
        'Telefone não informado';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ==============================
      // APP BAR
      // ==============================

      appBar: AppBar(
        backgroundColor: laranja,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Meu Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ==============================
      // CONTEÚDO
      // ==============================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 15),

            // ==============================
            // FOTO DO USUÁRIO
            // ==============================

            Container(
              width: 100,
              height: 100,

              decoration: const BoxDecoration(
                color: laranja,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            // ==============================
            // NOME
            // ==============================

            Text(
              nome,

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 5),

            // ==============================
            // E-MAIL
            // ==============================

            Text(
              email,

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // ==============================
            // DADOS PESSOAIS
            // ==============================

            _itemPerfil(
              context,
              Icons.person_outline,
              'Dados pessoais',
              'Nome, e-mail e telefone',
              () {
                _mostrarDadosPessoais(
                  context,
                  nome,
                  email,
                  telefone,
                );
              },
            ),

            // ==============================
            // MEUS ENDEREÇOS
            // ==============================

            _itemPerfil(
              context,
              Icons.location_on_outlined,
              'Meus endereços',
              'Gerenciar endereços de entrega',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const MyAddressesScreen(),
                  ),
                );
              },
            ),

            // ==============================
            // MEUS FAVORITOS
            // ==============================

            _itemPerfil(
              context,
              Icons.favorite_border,
              'Meus favoritos',
              'Restaurantes favoritos',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FavoritesScreen(),
                  ),
                );
              },
            ),

            // ==============================
            // MEUS PEDIDOS
            // ==============================

            _itemPerfil(
              context,
              Icons.receipt_long_outlined,
              'Meus pedidos',
              'Consultar histórico de pedidos',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const OrderHistoryScreen(),
                  ),
                );
              },
            ),

            // ==============================
            // CONFIGURAÇÕES
            // ==============================

           _itemPerfil(
  context,
  Icons.settings_outlined,
  'Configurações',
  'Preferências do aplicativo',
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          usuario: usuario,
        ),
      ),
    );
  },
),

            const SizedBox(height: 20),

            // ==============================
            // SAIR DA CONTA
            // ==============================

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,

                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text(
                          'Sair da conta?',
                        ),

                        content: const Text(
                          'Você deseja realmente sair da sua conta?',
                        ),

                        actions: [

                          // CANCELAR
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },

                            child: const Text(
                              'Cancelar',
                            ),
                          ),

                          // SAIR
                          ElevatedButton(
                            onPressed: () {
                              // Fecha o diálogo
                              Navigator.pop(
                                dialogContext,
                              );

                              // Volta para o login
                              // removendo todas as telas anteriores
                              Navigator.pushAndRemoveUntil(
                                context,

                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginScreen(),
                                ),

                                (route) => false,
                              );
                            },

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  laranja,

                              foregroundColor:
                                  Colors.white,
                            ),

                            child: const Text(
                              'Sair',
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },

                icon: const Icon(
                  Icons.logout,
                ),

                label: const Text(
                  'Sair da conta',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red,

                  side:
                      const BorderSide(
                    color: Colors.red,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
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
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // DADOS PESSOAIS
  // ==================================================

  static void _mostrarDadosPessoais(
    BuildContext context,
    String nome,
    String email,
    String telefone,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          Colors.white,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Center(
                child: Icon(
                  Icons.drag_handle,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Dados pessoais',

                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              _linhaDado(
                Icons.person_outline,
                'Nome',
                nome,
              ),

              const SizedBox(height: 15),

              _linhaDado(
                Icons.email_outlined,
                'E-mail',
                email,
              ),

              const SizedBox(height: 15),

              _linhaDado(
                Icons.phone_outlined,
                'Telefone',
                telefone,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width:
                    double.infinity,

                child:
                    ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
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
                        const EdgeInsets.symmetric(
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
                    'Fechar',
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ==================================================
  // LINHA DE DADO
  // ==================================================

  static Widget _linhaDado(
    IconData icone,
    String titulo,
    String valor,
  ) {
    return Row(
      children: [

        Container(
          width: 45,
          height: 45,

          decoration:
              BoxDecoration(
            color:
                Colors.orange.shade50,

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child:
              Icon(
            icone,

            color:
                const Color(
              0xFFF97316,
            ),
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                titulo,

                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                valor,

                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================================================
  // ITEM DO PERFIL
  // ==================================================

  static Widget _itemPerfil(
    BuildContext context,
    IconData icone,
    String titulo,
    String subtitulo,
    VoidCallback aoClicar,
  ) {
    const Color laranja =
        Color(0xFFF97316);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),

      child:
          ListTile(
        onTap:
            aoClicar,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),

        leading:
            Container(
          width: 45,
          height: 45,

          decoration:
              BoxDecoration(
            color:
                Colors.orange.shade50,

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child:
              Icon(
            icone,
            color:
                laranja,
          ),
        ),

        title:
            Text(
          titulo,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,

            color:
                Colors.black,
          ),
        ),

        subtitle:
            Text(
          subtitulo,

          style:
              const TextStyle(
            color:
                Colors.grey,
          ),
        ),

        trailing:
            const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}