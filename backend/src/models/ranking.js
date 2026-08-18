const { db } = require("../config/database");

const Ranking = {

    async calcular() {

        if (!db.data.restaurantes) {
            return [];
        }

        if (!db.data.pedidos) {
            return [];
        }

        const restaurantes =
            db.data.restaurantes;

        const pedidos =
            db.data.pedidos;

        const ranking = restaurantes.map(
            restaurante => {

                const restauranteId =
                    (
                        restaurante.id ??
                        restaurante._id
                    ).toString();

                const pedidosRestaurante =
                    pedidos.filter(pedido => {

                        const id =
                            pedido.restauranteId ??
                            pedido.restaurantId;

                        return id &&
                            id.toString() ===
                            restauranteId;

                    });

                const pedidosConcluidos =
                    pedidosRestaurante.filter(
                        pedido =>
                            String(
                                pedido.status || ""
                            ).toUpperCase() ===
                            "ENTREGUE"
                    );

                let vendas = 0;

                pedidosConcluidos.forEach(
                    pedido => {

                        const total =
                            Number(
                                pedido.totalPedido ??
                                pedido.total ??
                                pedido.valorTotal ??
                                0
                            );

                        vendas += total;
                    }
                );

                const quantidadePedidos =
                    pedidosConcluidos.length;

                const avaliacao =
                    Number(
                        restaurante.avaliacao ??
                        restaurante.nota ??
                        restaurante.rating ??
                        0
                    );

                // ==========================================
                // PONTUAÇÃO FOODJET
                // ==========================================

                const pontosVendas =
                    vendas * 0.5;

                const pontosPedidos =
                    quantidadePedidos * 10;

                const pontosAvaliacao =
                    avaliacao * 100;

                const pontuacao =
                    pontosVendas +
                    pontosPedidos +
                    pontosAvaliacao;

                return {

                    restauranteId,

                    nome:
                        restaurante.nome ??
                        restaurante.nomeRestaurante ??
                        "Restaurante",

                    imagem:
                        restaurante.imagem ??
                        restaurante.logo ??
                        "",

                    avaliacao,

                    vendas:
                        Number(
                            vendas.toFixed(2)
                        ),

                    pedidos:
                        quantidadePedidos,

                    pontuacao:
                        Number(
                            pontuacao.toFixed(2)
                        )
                };
            }
        );

        ranking.sort(
            (a, b) =>
                b.pontuacao -
                a.pontuacao
        );

        ranking.forEach(
            (restaurante, index) => {

                restaurante.posicao =
                    index + 1;

                restaurante.titulo =
                    index === 0
                        ? "TOP 1 FOODJET"
                        : index === 1
                            ? "TOP 2 FOODJET"
                            : index === 2
                                ? "TOP 3 FOODJET"
                                : null;
            }
        );

        return ranking;
    }
};

module.exports = Ranking;