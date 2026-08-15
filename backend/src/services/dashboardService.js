const db = require("../config/database");

class DashboardService {
  static async obterDashboard(restauranteId) {
    await db.read();

    const pedidos = db.data.pedidos || [];
    const produtos = db.data.produtos || [];
    const avaliacoes = db.data.avaliacoes || [];

    const pedidosRestaurante = pedidos.filter(
      (p) => p.restauranteId === restauranteId
    );

    const produtosRestaurante = produtos.filter(
      (p) => p.restauranteId === restauranteId
    );

    // Data de hoje
    const hoje = new Date().toISOString().substring(0, 10);

    const pedidosHoje = pedidosRestaurante.filter((p) => {
      if (!p.createdAt) return false;
      return p.createdAt.substring(0, 10) === hoje;
    });

    const vendasHoje = pedidosHoje
      .filter((p) => p.status === "CONCLUIDO")
      .reduce((total, pedido) => total + Number(pedido.total || 0), 0);

    const pendentes = pedidosRestaurante.filter(
      (p) => p.status === "AGUARDANDO"
    ).length;

    const preparando = pedidosRestaurante.filter(
      (p) => p.status === "PREPARANDO"
    ).length;

    const entrega = pedidosRestaurante.filter(
      (p) => p.status === "SAIU_PARA_ENTREGA"
    ).length;

    const concluidos = pedidosRestaurante.filter(
      (p) => p.status === "CONCLUIDO"
    ).length;

    const ticketMedio =
      concluidos > 0
        ? vendasHoje / concluidos
        : 0;

    const avaliacoesRestaurante = avaliacoes.filter(
      (a) => a.restauranteId === restauranteId
    );

    const avaliacao =
      avaliacoesRestaurante.length > 0
        ? avaliacoesRestaurante.reduce(
            (soma, item) => soma + Number(item.nota || 0),
            0
          ) / avaliacoesRestaurante.length
        : 5;

    return {
      pedidosHoje: pedidosHoje.length,
      vendasHoje,
      produtos: produtosRestaurante.length,
      avaliacao: Number(avaliacao.toFixed(1)),
      pendentes,
      preparando,
      entrega,
      concluidos,
      ticketMedio: Number(ticketMedio.toFixed(2)),
      ultimosPedidos: pedidosRestaurante
        .sort((a, b) => b.id - a.id)
        .slice(0, 5),
    };
  }
}

module.exports = DashboardService;