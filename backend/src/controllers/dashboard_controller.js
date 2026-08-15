const { db } = require("../config/database");

// ============================================================
// DASHBOARD DO RESTAURANTE
// ============================================================

exports.resumo = async (req, res) => {

    try {

        console.log("================================");
        console.log("📊 CARREGANDO DASHBOARD");
        console.log("================================");

        // ====================================================
        // CARREGAR BANCO
        // ====================================================

        await db.read();

        db.data ||= {};

        db.data.pedidos ||= [];
        db.data.restaurantes ||= [];
        db.data.produtos ||= [];
        db.data.usuarios ||= [];

        const pedidos = db.data.pedidos;
        const restaurantes = db.data.restaurantes;
        const produtos = db.data.produtos;

        // ====================================================
        // IDENTIFICAR RESTAURANTE
        // ====================================================

        const restauranteId =
            req.usuario?.restauranteId ||
            req.params?.restauranteId ||
            req.query?.restauranteId;

        console.log(
            "🏪 RESTAURANTE ID:",
            restauranteId
        );

        // ====================================================
        // FILTRAR PEDIDOS DO RESTAURANTE
        // ====================================================

        let pedidosRestaurante = pedidos;

        if (restauranteId) {

            pedidosRestaurante =
                pedidos.filter(pedido =>

                    String(pedido.restauranteId) ===
                    String(restauranteId)

                );

        }

        console.log(
            "📦 PEDIDOS ENCONTRADOS:",
            pedidosRestaurante.length
        );

        // ====================================================
        // DATA DE HOJE
        // ====================================================

        const agora = new Date();

        const inicioHoje =
            new Date(
                agora.getFullYear(),
                agora.getMonth(),
                agora.getDate(),
                0,
                0,
                0,
                0
            );

        const fimHoje =
            new Date(
                agora.getFullYear(),
                agora.getMonth(),
                agora.getDate(),
                23,
                59,
                59,
                999
            );

        // ====================================================
        // PEDIDOS DE HOJE
        // ====================================================

        const pedidosHoje =
            pedidosRestaurante.filter(pedido => {

                const dataPedido =
                    pedido.criadoEm ||
                    pedido.atualizadoEm;

                if (!dataPedido) {
                    return false;
                }

                const data =
                    new Date(dataPedido);

                return (
                    !isNaN(data.getTime()) &&
                    data >= inicioHoje &&
                    data <= fimHoje
                );

            });

        // ====================================================
        // VENDAS DE HOJE
        // ====================================================

        const vendasHoje =
            pedidosHoje.reduce(
                (total, pedido) => {

                    const status =
                        String(
                            pedido.status || ""
                        ).toUpperCase();

                    // Pedidos cancelados não entram
                    if (status === "CANCELADO") {
                        return total;
                    }

                    return (
                        total +
                        Number(
                            pedido.total || 0
                        )
                    );

                },
                0
            );

        // ====================================================
        // PEDIDOS PENDENTES
        // ====================================================

        const statusPendentes = [

            "AGUARDANDO",

            "AGUARDANDO_RESTAURANTE",

            "ACEITO"

        ];

        const pedidosPendentes =
            pedidosRestaurante.filter(
                pedido =>
                    statusPendentes.includes(
                        String(
                            pedido.status || ""
                        ).toUpperCase()
                    )
            ).length;

        // ====================================================
        // PEDIDOS EM PREPARAÇÃO
        // ====================================================

        const statusPreparacao = [

            "EM_PREPARO",

            "PREPARANDO",

            "PREPARO"

        ];

        const pedidosEmPreparo =
            pedidosRestaurante.filter(
                pedido =>
                    statusPreparacao.includes(
                        String(
                            pedido.status || ""
                        ).toUpperCase()
                    )
            ).length;

        // ====================================================
        // PEDIDOS PRONTOS
        // ====================================================

        const pedidosProntos =
            pedidosRestaurante.filter(
                pedido =>
                    String(
                        pedido.status || ""
                    ).toUpperCase() === "PRONTO"
            ).length;

        // ====================================================
        // PEDIDOS EM ENTREGA
        // ====================================================

        const pedidosEmEntrega =
            pedidosRestaurante.filter(
                pedido => {

                    const status =
                        String(
                            pedido.status || ""
                        ).toUpperCase();

                    return [

                        "EM_ENTREGA",

                        "SAIU_PARA_ENTREGA"

                    ].includes(status);

                }
            ).length;

        // ====================================================
        // PEDIDOS CONCLUÍDOS
        // ====================================================

        const pedidosConcluidos =
            pedidosRestaurante.filter(
                pedido => {

                    const status =
                        String(
                            pedido.status || ""
                        ).toUpperCase();

                    return [

                        "CONCLUIDO",

                        "CONCLUÍDO",

                        "ENTREGUE"

                    ].includes(status);

                }
            ).length;

        // ====================================================
        // PEDIDOS CANCELADOS
        // ====================================================

        const pedidosCancelados =
            pedidosRestaurante.filter(
                pedido =>
                    String(
                        pedido.status || ""
                    ).toUpperCase() ===
                    "CANCELADO"
            ).length;

        // ====================================================
        // VENDAS TOTAIS
        // ====================================================

        const vendasTotais =
            pedidosRestaurante.reduce(
                (total, pedido) => {

                    const status =
                        String(
                            pedido.status || ""
                        ).toUpperCase();

                    if (status === "CANCELADO") {
                        return total;
                    }

                    return (
                        total +
                        Number(
                            pedido.total || 0
                        )
                    );

                },
                0
            );

        // ====================================================
        // PRODUTOS DO RESTAURANTE
        // ====================================================

        let produtosRestaurante =
            produtos;

        if (restauranteId) {

            produtosRestaurante =
                produtos.filter(produto =>

                    String(
                        produto.restauranteId
                    ) ===
                    String(restauranteId)

                );

        }

        const produtosAtivos =
            produtosRestaurante.filter(
                produto =>
                    produto.disponivel !== false
            ).length;

        // ====================================================
        // RESTAURANTE
        // ====================================================

        let restaurante = null;

        if (restauranteId) {

            restaurante =
                restaurantes.find(
                    item =>
                        String(item.id) ===
                        String(restauranteId)
                ) || null;

        }

        // ====================================================
        // RESPOSTA
        // ====================================================

        const resposta = {

            sucesso: true,

            restaurante: restaurante
                ? {
                    id: restaurante.id,
                    nome: restaurante.nome,
                    categoria:
                        restaurante.categoria,
                    status:
                        restaurante.status,
                    online:
                        restaurante.online,
                    aberto:
                        restaurante.aberto
                }
                : null,

            vendasHoje:
                Number(
                    vendasHoje.toFixed(2)
                ),

            vendasTotais:
                Number(
                    vendasTotais.toFixed(2)
                ),

            pedidosHoje:
                pedidosHoje.length,

            pedidosPendentes,

            pedidosEmPreparo,

            pedidosProntos,

            pedidosEmEntrega,

            pedidosConcluidos,

            pedidosCancelados,

            totalPedidos:
                pedidosRestaurante.length,

            totalProdutos:
                produtosRestaurante.length,

            produtosAtivos

        };

        console.log(
            "📊 DASHBOARD:",
            resposta
        );

        return res.status(200).json(
            resposta
        );

    } catch (error) {

        console.error(
            "================================"
        );

        console.error(
            "❌ ERRO API DASHBOARD:"
        );

        console.error(
            error
        );

        console.error(
            "================================"
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao carregar dashboard",

            detalhe:
                error.message

        });

    }

};