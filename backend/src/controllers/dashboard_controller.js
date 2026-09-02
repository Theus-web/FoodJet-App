const { pool } = require("../config/database");

// ============================================================
// DASHBOARD DO RESTAURANTE
// ============================================================

exports.resumo = async (req, res) => {

    try {

        console.log("================================");
        console.log("📊 CARREGANDO DASHBOARD");
        console.log("================================");

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
        // CONSULTAS BASE
        // ====================================================

        let pedidosQuery;
        let produtosQuery;
        let restauranteQuery;

        if (restauranteId) {

            pedidosQuery = pool.query(
                `
                SELECT
                    id,
                    restaurante_id,
                    total,
                    status,
                    criado_em,
                    atualizado_em,
                    dados
                FROM pedidos
                WHERE restaurante_id = $1
                ORDER BY criado_em DESC
                `,
                [String(restauranteId)]
            );

            produtosQuery = pool.query(
                `
                SELECT
                    id,
                    restaurante_id,
                    nome,
                    disponivel,
                    criado_em,
                    atualizado_em,
                    dados
                FROM produtos
                WHERE restaurante_id = $1
                ORDER BY criado_em DESC
                `,
                [String(restauranteId)]
            );

            restauranteQuery = pool.query(
                `
                SELECT
                    id,
                    nome,
                    categoria,
                    status,
                    online,
                    aberto,
                    criado_em,
                    atualizado_em,
                    dados
                FROM restaurantes
                WHERE id = $1
                LIMIT 1
                `,
                [String(restauranteId)]
            );

        } else {

            pedidosQuery = pool.query(
                `
                SELECT
                    id,
                    restaurante_id,
                    total,
                    status,
                    criado_em,
                    atualizado_em,
                    dados
                FROM pedidos
                ORDER BY criado_em DESC
                `
            );

            produtosQuery = pool.query(
                `
                SELECT
                    id,
                    restaurante_id,
                    nome,
                    disponivel,
                    criado_em,
                    atualizado_em,
                    dados
                FROM produtos
                ORDER BY criado_em DESC
                `
            );

            restauranteQuery = Promise.resolve({
                rows: []
            });
        }

        const [
            pedidosResultado,
            produtosResultado,
            restauranteResultado
        ] = await Promise.all([
            pedidosQuery,
            produtosQuery,
            restauranteQuery
        ]);

        // ====================================================
        // CONVERTER PEDIDOS
        // ====================================================

        const pedidos =
            pedidosResultado.rows.map(row => {

                const dados =
                    row.dados &&
                    typeof row.dados === "object"
                        ? row.dados
                        : {};

                return {
                    ...dados,

                    id: row.id,

                    restauranteId:
                        row.restaurante_id,

                    total:
                        Number(row.total || 0),

                    status:
                        row.status,

                    criadoEm:
                        row.criado_em
                            ? new Date(
                                row.criado_em
                            ).toISOString()
                            : dados.criadoEm,

                    atualizadoEm:
                        row.atualizado_em
                            ? new Date(
                                row.atualizado_em
                            ).toISOString()
                            : dados.atualizadoEm
                };

            });

        // ====================================================
        // CONVERTER PRODUTOS
        // ====================================================

        const produtos =
            produtosResultado.rows.map(row => {

                const dados =
                    row.dados &&
                    typeof row.dados === "object"
                        ? row.dados
                        : {};

                return {
                    ...dados,

                    id: row.id,

                    restauranteId:
                        row.restaurante_id,

                    nome:
                        row.nome,

                    disponivel:
                        row.disponivel !== false,

                    criadoEm:
                        row.criado_em
                            ? new Date(
                                row.criado_em
                            ).toISOString()
                            : dados.criadoEm,

                    atualizadoEm:
                        row.atualizado_em
                            ? new Date(
                                row.atualizado_em
                            ).toISOString()
                            : dados.atualizadoEm
                };

            });

        // ====================================================
        // CONVERTER RESTAURANTE
        // ====================================================

        let restaurante = null;

        if (
            restauranteResultado.rows.length > 0
        ) {

            const row =
                restauranteResultado.rows[0];

            const dados =
                row.dados &&
                typeof row.dados === "object"
                    ? row.dados
                    : {};

            restaurante = {
                ...dados,

                id: row.id,
                nome: row.nome,
                categoria: row.categoria,
                status: row.status,
                online: row.online,
                aberto: row.aberto,

                criadoEm:
                    row.criado_em
                        ? new Date(
                            row.criado_em
                        ).toISOString()
                        : dados.criadoEm,

                atualizadoEm:
                    row.atualizado_em
                        ? new Date(
                            row.atualizado_em
                        ).toISOString()
                        : dados.atualizadoEm
            };
        }

        console.log(
            "📦 PEDIDOS ENCONTRADOS:",
            pedidos.length
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
            pedidos.filter(pedido => {

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
                    if (
                        status === "CANCELADO"
                    ) {
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
            pedidos.filter(
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
            pedidos.filter(
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
            pedidos.filter(
                pedido =>
                    String(
                        pedido.status || ""
                    ).toUpperCase() === "PRONTO"
            ).length;

        // ====================================================
        // PEDIDOS EM ENTREGA
        // ====================================================

        const pedidosEmEntrega =
            pedidos.filter(
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
            pedidos.filter(
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
            pedidos.filter(
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
            pedidos.reduce(
                (total, pedido) => {

                    const status =
                        String(
                            pedido.status || ""
                        ).toUpperCase();

                    if (
                        status === "CANCELADO"
                    ) {
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
        // PRODUTOS ATIVOS
        // ====================================================

        const produtosAtivos =
            produtos.filter(
                produto =>
                    produto.disponivel !== false
            ).length;

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
                pedidos.length,

            totalProdutos:
                produtos.length,

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

        console.error(error);

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