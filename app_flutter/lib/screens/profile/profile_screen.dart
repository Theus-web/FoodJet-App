import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login/login_screen.dart';
import '../favorites/favorites_screen.dart';
import '../orders/order_history_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const ProfileScreen({
    super.key,
    required this.usuario,
  });

  static const Color laranja = Color(0xFFF97316);
  static const Color vermelho = Color(0xFFDC2626);

  // ============================================================
  // ENCERRAR CONTA
  // ============================================================

  Future<void> _encerrarConta(
    BuildContext context,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            10,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            10,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            5,
            18,
            18,
          ),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: vermelho.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: vermelho,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Encerrar conta?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Essa ação encerra sua sessão no aplicativo e remove os dados locais da conta neste dispositivo.\n\n'
            'A exclusão definitiva da conta e dos dados armazenados no servidor precisa ser realizada pelo sistema do FoodJet.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black54,
            ),
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
                'Cancelar',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
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
                backgroundColor: vermelho,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Encerrar conta',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmado != true) {
      return;
    }

    await _limparDadosLocais(context);
  }

  // ============================================================
  // LIMPAR DADOS LOCAIS
  // ============================================================

  Future<void> _limparDadosLocais(
    BuildContext context,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      const chavesSessao = [
        'token',
        'accessToken',
        'refreshToken',
        'usuario',
        'usuarioLogado',
        'user',
        'userId',
        'clienteId',
        'restauranteSelecionadoId',
        'restauranteId',
      ];

      for (final chave in chavesSessao) {
        await prefs.remove(chave);
      }

      await prefs.remove(
        'foodjet_favoritos',
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'ERRO AO ENCERRAR CONTA: $e',
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível encerrar a conta neste momento.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final String nome =
        usuario['nome']?.toString().trim().isNotEmpty == true
            ? usuario['nome'].toString()
            : 'Usuário';

    final String email =
        usuario['email']?.toString().trim().isNotEmpty == true
            ? usuario['email'].toString()
            : 'E-mail não informado';

    final String telefone =
        usuario['telefone']?.toString().trim().isNotEmpty == true
            ? usuario['telefone'].toString()
            : 'Telefone não informado';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ========================================================
      // APP BAR
      // ========================================================

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

      // ========================================================
      // CONTEÚDO
      // ========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),

            // ==================================================
            // FOTO
            // ==================================================

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

            // ==================================================
            // NOME
            // ==================================================

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

            // ==================================================
            // EMAIL
            // ==================================================

            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // DADOS PESSOAIS
            // ==================================================

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

            // ==================================================
            // FAVORITOS
            // ==================================================

            _itemPerfil(
              context,
              Icons.favorite_border_rounded,
              'Meus favoritos',
              'Restaurantes favoritos',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FavoritesScreen(),
                  ),
                );
              },
            ),

            // ==================================================
            // PEDIDOS
            // ==================================================

            _itemPerfil(
              context,
              Icons.receipt_long_outlined,
              'Meus pedidos',
              'Consultar histórico de pedidos',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const OrderHistoryScreen(),
                  ),
                );
              },
            ),

            // ==================================================
            // CONFIGURAÇÕES
            // ==================================================

            _itemPerfil(
              context,
              Icons.settings_outlined,
              'Configurações',
              'Preferências do aplicativo',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      usuario: usuario,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // SAIR DA CONTA
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _mostrarDialogoSair(context);
                },
                icon: const Icon(
                  Icons.logout_rounded,
                ),
                label: const Text(
                  'Sair da conta',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
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

            const SizedBox(height: 14),

            // ==================================================
            // ENCERRAR CONTA
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  _encerrarConta(context);
                },
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: vermelho,
                ),
                label: const Text(
                  'Encerrar minha conta',
                  style: TextStyle(
                    color: vermelho,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
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

            const SizedBox(height: 20),

            // ==================================================
            // AVISO
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.05,
                ),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.red.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O encerramento da conta é uma ação importante. Certifique-se de que realmente deseja sair do FoodJet.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIÁLOGO SAIR
  // ============================================================

  void _mostrarDialogoSair(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Sair da conta?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Você deseja realmente sair da sua conta?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: laranja,
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
  }

  // ============================================================
  // DADOS PESSOAIS
  // ============================================================

  static void _mostrarDadosPessoais(
    BuildContext context,
    String nome,
    String email,
    String telefone,
  ) {
    showModalBottomSheet(
      context: context,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  fontWeight: FontWeight.bold,
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
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: laranja,
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
                  child: const Text(
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

  // ============================================================
  // LINHA DE DADO
  // ============================================================

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
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icone,
            color: laranja,
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                valor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ITEM DO PERFIL
  // ============================================================

  static Widget _itemPerfil(
    BuildContext context,
    IconData icone,
    String titulo,
    String subtitulo,
    VoidCallback aoClicar,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: aoClicar,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),
        leading: Container(
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
          child: Icon(
            icone,
            color: laranja,
          ),
        ),
        title: Text(
          titulo,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style:
              const TextStyle(
            color: Colors.grey,
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