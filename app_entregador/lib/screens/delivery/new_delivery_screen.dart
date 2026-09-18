import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/pedido.dart';
import '../../services/delivery_service.dart';

class NewDeliveryScreen extends StatefulWidget {
  final Pedido pedido;

  const NewDeliveryScreen({
    super.key,
    required this.pedido,
  });

  @override
  State<NewDeliveryScreen> createState() =>
      _NewDeliveryScreenState();
}

class _NewDeliveryScreenState
    extends State<NewDeliveryScreen> {
  bool _loading = false;

  Pedido get pedido => widget.pedido;

  Future<void> _updateStatus(String status) async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      await DeliveryService.updateStatus(
        pedido.id,
        status,
      );

      if (!mounted) return;

      String mensagem;

      switch (status) {
        case 'CHEGUEI_RESTAURANTE':
          mensagem = 'Chegada ao restaurante registrada.';
          break;

        case 'EM_ENTREGA':
          mensagem = 'Entrega iniciada.';
          break;

        case 'ENTREGUE':
          mensagem = 'Entrega finalizada com sucesso.';
          break;

        default:
          mensagem = 'Status atualizado.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (status == 'ENTREGUE') {
        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: FoodJetColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _pedidoStatus() {
    final dynamic value = pedido.status;

    return _text(value).toUpperCase();
  }

  String _nomeRestaurante() {
    try {
      final dynamic restaurante =
          (pedido as dynamic).restaurante;

      if (restaurante != null) {
        if (restaurante is Map) {
          return _text(
            restaurante['nome'] ??
                restaurante['name'] ??
                'Restaurante',
          );
        }
      }
    } catch (_) {}

    try {
      final dynamic nome =
          (pedido as dynamic).restauranteNome;

      if (nome != null && _text(nome).isNotEmpty) {
        return _text(nome);
      }
    } catch (_) {}

    return 'Restaurante';
  }

  String _enderecoRestaurante() {
    try {
      final dynamic endereco =
          (pedido as dynamic).enderecoRestaurante;

      if (endereco != null &&
          _text(endereco).isNotEmpty) {
        return _text(endereco);
      }
    } catch (_) {}

    try {
      final dynamic restaurante =
          (pedido as dynamic).restaurante;

      if (restaurante is Map) {
        final value =
            restaurante['endereco'] ??
            restaurante['endereco_completo'] ??
            restaurante['address'];

        if (value != null &&
            value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    } catch (_) {}

    return 'Endereço do restaurante';
  }

  String _enderecoEntrega() {
    try {
      final dynamic endereco =
          (pedido as dynamic).endereco;

      if (endereco != null) {
        if (endereco is Map) {
          final rua =
              endereco['rua'] ??
              endereco['logradouro'] ??
              '';

          final numero =
              endereco['numero'] ?? '';

          final bairro =
              endereco['bairro'] ?? '';

          final cidade =
              endereco['cidade'] ?? '';

          final partes = [
            rua,
            numero,
            bairro,
            cidade,
          ]
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();

          if (partes.isNotEmpty) {
            return partes.join(', ');
          }
        }

        if (_text(endereco).isNotEmpty) {
          return _text(endereco);
        }
      }
    } catch (_) {}

    try {
      final dynamic enderecoEntrega =
          (pedido as dynamic).enderecoEntrega;

      if (enderecoEntrega != null &&
          _text(enderecoEntrega).isNotEmpty) {
        return _text(enderecoEntrega);
      }
    } catch (_) {}

    return 'Endereço de entrega';
  }

  String _statusTitulo() {
    switch (_pedidoStatus()) {
      case 'AGUARDANDO_RESTAURANTE':
      case 'ACEITO':
      case 'PREPARANDO':
      case 'PRONTO':
        return 'Aguardando entrega';

      case 'EM_ENTREGA':
        return 'Em entrega';

      case 'ENTREGUE':
      case 'FINALIZADO':
        return 'Entrega concluída';

      default:
        return 'Nova entrega';
    }
  }

  Widget _statusCard() {
    final status = _pedidoStatus();

    IconData icon = Icons.delivery_dining;
    String titulo = 'Nova entrega';
    String descricao =
        'Confira os dados do pedido e siga as etapas.';

    if (status == 'CHEGUEI_RESTAURANTE') {
      icon = Icons.storefront;
      titulo = 'No restaurante';
      descricao =
          'Você chegou ao restaurante. Aguarde a retirada do pedido.';
    } else if (status == 'EM_ENTREGA') {
      icon = Icons.navigation;
      titulo = 'Pedido em entrega';
      descricao =
          'Siga para o endereço do cliente.';
    } else if (status == 'ENTREGUE' ||
        status == 'FINALIZADO') {
      icon = Icons.check_circle;
      titulo = 'Entrega concluída';
      descricao =
          'Este pedido foi finalizado.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FoodJetColors.dark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: FoodJetColors.orange.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: FoodJetColors.orange,
              size: 29,
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard({
    required IconData icon,
    required String title,
    required String address,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FoodJetColors.orange.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: FoodJetColors.orange,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FoodJetColors.gray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: FoodJetColors.gray,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: FoodJetColors.gray,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool primary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          _loading ? 'Atualizando...' : label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? FoodJetColors.orange
              : Colors.white,
          foregroundColor: primary
              ? Colors.white
              : FoodJetColors.dark,
          disabledBackgroundColor:
              FoodJetColors.gray.withValues(
            alpha: 0.25,
          ),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  Widget _buildAction() {
    final status = _pedidoStatus();

    if (status == 'ENTREGUE' ||
        status == 'FINALIZADO') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FoodJetColors.green.withValues(
            alpha: 0.12,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: FoodJetColors.green,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Entrega finalizada com sucesso.',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'EM_ENTREGA') {
      return _actionButton(
        label: 'FINALIZAR ENTREGA',
        icon: Icons.check_circle_outline,
        onPressed: () {
          _updateStatus('ENTREGUE');
        },
      );
    }

    if (status == 'CHEGUEI_RESTAURANTE') {
      return _actionButton(
        label: 'INICIAR ENTREGA',
        icon: Icons.navigation_outlined,
        onPressed: () {
          _updateStatus('EM_ENTREGA');
        },
      );
    }

    return _actionButton(
      label: 'CHEGUEI AO RESTAURANTE',
      icon: Icons.storefront,
      onPressed: () {
        _updateStatus('CHEGUEI_RESTAURANTE');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrega',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _statusCard(),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _nomeRestaurante(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                _infoRow(
                  Icons.receipt_long,
                  'Pedido',
                  '#${pedido.id}',
                ),
                _infoRow(
                  Icons.payments_outlined,
                  'Status',
                  _statusTitulo(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _locationCard(
            icon: Icons.storefront,
            title: 'RETIRADA',
            address: _enderecoRestaurante(),
          ),

          const SizedBox(height: 10),

          _locationCard(
            icon: Icons.location_on,
            title: 'ENTREGA',
            address: _enderecoEntrega(),
          ),

          const SizedBox(height: 20),

          const Text(
            'Ações da entrega',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 10),

          _buildAction(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}