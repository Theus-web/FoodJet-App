
const Delivery = require("../models/delivery");
const Order = require("../models/order");
const Wallet = require("../models/wallet");
const { pool } = require("../config/database");

// ============================================================
// FOODJET - CONTROLLER DE ENTREGADORES
// ============================================================
//
// Rotas:
//
// POST   /delivery
// GET    /delivery
// GET    /delivery/available/orders
// GET    /delivery/:id/orders
// PUT    /delivery/:id/status
// PUT    /delivery/:id/orders/:orderId/accept
// PUT    /delivery/orders/:orderId/arrived
// PUT    /delivery/orders/:orderId/start
// PUT    /delivery/orders/:orderId/finish
//
// ============================================================


// ============================================================
// CADASTRAR ENTREGADOR
// ============================================================

exports.create = async (req, res) => {
    try {

        const {
            id,
            nome,
            telefone,
            email,
            cpf,
            veiculo,
            placa
        } = req.body;

        if (!nome || !telefone) {

            return res.status(400).json({
                sucesso: false,
                mensagem:
                    "Nome e telefone são obrigatórios."
            });
        }

        // ----------------------------------------------------
        // ID
        // ----------------------------------------------------

        const entregadorId =
            id
                ? String(id).trim()
                : Date.now().toString();

        const entregador = {

            id: entregadorId,

            nome:
                String(nome).trim(),

            telefone:
                String(telefone).trim(),

            email:
                email
                    ? String(email).trim().toLowerCase()
                    : null,

            cpf:
                cpf
                    ? String(cpf).trim()
                    : null,

            veiculo:
                veiculo
                    ? String(veiculo).trim()
                    : null,

            placa:
                placa
                    ? String(placa).trim().toUpperCase()
                    : null,

            online: false,

            status: "OFFLINE",

            criadoEm:
                new Date().toISOString(),

            atualizadoEm:
                new Date().toISOString()
        };

        // ----------------------------------------------------
        // CRIAR ENTREGADOR
        // ----------------------------------------------------

        const criado =
            await Delivery.criar(entregador);

        // ----------------------------------------------------
        // GARANTIR CARTEIRA
        // ----------------------------------------------------

        const carteira =
            await Wallet.garantir(
                criado.id
            );

        console.log("");
        console.log("==========================================");
        console.log("🛵 FOODJET - ENTREGADOR CADASTRADO");
        console.log("==========================================");

        console.log(
            "🆔 ID:",
            criado.id
        );

        console.log(
            "👤 NOME:",
            criado.nome
        );

        console.log(
            "📧 EMAIL:",
            criado.email
        );

        console.log(
            "📱 TELEFONE:",
            criado.telefone
        );

        console.log(
            "🌐 ONLINE:",
            criado.online
        );

        console.log(
            "📌 STATUS:",
            criado.status
        );

        console.log(
            "💰 CARTEIRA:",
            carteira.id
        );

        console.log("==========================================");

        return res.status(201).json({

            sucesso: true,

            mensagem:
                "Entregador cadastrado com sucesso.",

            entregador:
                criado,

            carteira: {

                id:
                    carteira.id,

                saldo:
                    carteira.saldo,

                limiteNegativo:
                    carteira.limite_negativo,

                dinheiroEmMaos:
                    carteira.dinheiro_em_maos
            }
        });

    } catch (e) {

        console.error("");
        console.error(
            "❌ ERRO CREATE DELIVERY:"
        );

        console.error(e);

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao cadastrar entregador.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// LISTAR ENTREGADORES
// ============================================================

exports.list = async (req, res) => {

    try {

        const entregadores =
            await Delivery.listar();

        return res.json({

            sucesso: true,

            total:
                entregadores.length,

            entregadores
        });

    } catch (e) {

        console.error("");
        console.error(
            "❌ ERRO LIST DELIVERY:"
        );

        console.error(e);

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao listar entregadores.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// ALTERAR STATUS ONLINE / OFFLINE
// ============================================================

exports.status = async (req, res) => {

    try {

        const id =
            String(
                req.params.id || ""
            ).trim();

        if (!id) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "ID do entregador não informado."
            });
        }

        const valorOnline =
            req.body?.online;

        const online =
            valorOnline === true ||
            String(valorOnline).toLowerCase() === "true" ||
            String(valorOnline) === "1";

        console.log("");
        console.log("==========================================");
        console.log("🛵 FOODJET - ALTERAR STATUS");
        console.log("==========================================");

        console.log(
            "🆔 ID:",
            id
        );

        console.log(
            "📥 ONLINE RECEBIDO:",
            valorOnline
        );

        console.log(
            "🌐 ONLINE NORMALIZADO:",
            online
        );

        // ----------------------------------------------------
        // BUSCAR ENTREGADOR
        // ----------------------------------------------------

        const entregador =
            await Delivery.buscarPorId(id);

        if (!entregador) {

            return res.status(404).json({

                sucesso: false,

                mensagem:
                    "Entregador não encontrado."
            });
        }

        // ----------------------------------------------------
        // GARANTIR CARTEIRA
        // ----------------------------------------------------

        await Wallet.garantir(id);

        // ----------------------------------------------------
        // ATUALIZAR
        // ----------------------------------------------------

        const atualizado =
            await Delivery.atualizarOnline(
                id,
                online
            );

        if (!atualizado) {

            return res.status(404).json({

                sucesso: false,

                mensagem:
                    "Entregador não encontrado para atualização."
            });
        }

        console.log("");
        console.log("✅ STATUS ATUALIZADO");

        console.log(
            "🆔 ID:",
            atualizado.id
        );

        console.log(
            "🌐 ONLINE:",
            atualizado.online
        );

        console.log(
            "📌 STATUS:",
            atualizado.status
        );

        console.log("==========================================");

        // ----------------------------------------------------
        // SOCKET
        // ----------------------------------------------------

        if (global.io) {

            global.io.emit(
                "status_entregador_atualizado",
                atualizado
            );
        }

        return res.status(200).json({

            sucesso: true,

            mensagem:
                online
                    ? "Entregador ficou ONLINE."
                    : "Entregador ficou OFFLINE.",

            entregador:
                atualizado
        });

    } catch (e) {

        console.error("");
        console.error(
            "❌ ERRO STATUS DELIVERY:"
        );

        console.error(e);

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao atualizar status.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// PEDIDOS DO ENTREGADOR
// ============================================================

exports.myOrders = async (req, res) => {

    try {

        const id =
            String(
                req.params.id || ""
            ).trim();

        if (!id) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "ID do entregador não informado."
            });
        }

        console.log("");
        console.log("==========================================");
        console.log("🛵 FOODJET - PEDIDOS DO ENTREGADOR");
        console.log("==========================================");

        console.log(
            "🆔 ENTREGADOR:",
            id
        );

        const resultado =
            await pool.query(
                `
                SELECT *
                FROM pedidos
                WHERE entregador_id = $1
                ORDER BY criado_em DESC
                `,
                [id]
            );

        console.log(
            "📦 PEDIDOS ENCONTRADOS:",
            resultado.rows.length
        );

        console.log("==========================================");

        return res.json({

            sucesso: true,

            total:
                resultado.rows.length,

            pedidos:
                resultado.rows
        });

    } catch (e) {

        console.error("");
        console.error(
            "❌ ERRO MY ORDERS:"
        );

        console.error(e);

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao buscar pedidos.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// PEDIDOS DISPONÍVEIS
// ============================================================

exports.availableOrders = async (req, res) => {

    try {

        console.log("");
        console.log("==========================================");
        console.log("📦 FOODJET - PEDIDOS DISPONÍVEIS");
        console.log("==========================================");

        const resultado =
            await pool.query(
                `
                SELECT *
                FROM pedidos
                WHERE status = 'PRONTO'
                  AND entregador_id IS NULL
                ORDER BY criado_em ASC
                `
            );

        console.log(
            "📦 PEDIDOS DISPONÍVEIS:",
            resultado.rows.length
        );

        console.log("==========================================");

        return res.json({

            sucesso: true,

            total:
                resultado.rows.length,

            pedidos:
                resultado.rows
        });

    } catch (e) {

        console.error("");
        console.error(
            "❌ ERRO AVAILABLE ORDERS:"
        );

        console.error(e);

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao buscar entregas disponíveis.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// ACEITAR ENTREGA
// ============================================================

exports.acceptOrder = async (req, res) => {

    try {

        const entregadorId =
            String(
                req.params.id || ""
            ).trim();

        const pedidoId =
            String(
                req.params.orderId || ""
            ).trim();

        if (!entregadorId) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "ID do entregador não informado."
            });
        }

        if (!pedidoId) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "ID do pedido não informado."
            });
        }

        console.log("");
        console.log("==========================================");
        console.log("🛵 FOODJET - ACEITAR ENTREGA");
        console.log("==========================================");

        console.log(
            "🆔 ENTREGADOR:",
            entregadorId
        );

        console.log(
            "📦 PEDIDO:",
            pedidoId
        );

        // ----------------------------------------------------
        // ENTREGADOR
        // ----------------------------------------------------

        const entregador =
            await Delivery.buscarPorId(
                entregadorId
            );

        if (!entregador) {

            return res.status(404).json({

                sucesso: false,

                mensagem:
                    "Entregador não encontrado."
            });
        }

        // ----------------------------------------------------
        // ONLINE
        // ----------------------------------------------------

        if (
            entregador.online !== true
        ) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "O entregador precisa estar ONLINE para aceitar uma entrega."
            });
        }

        // ----------------------------------------------------
        // GARANTIR CARTEIRA
        // ----------------------------------------------------

        await Wallet.garantir(
            entregadorId
        );

        // ----------------------------------------------------
        // ENTREGA ATIVA
        // ----------------------------------------------------

        const entregaAtiva =
            await pool.query(
                `
                SELECT id, status
                FROM pedidos
                WHERE entregador_id = $1
                  AND status IN (
                      'ENTREGADOR_A_CAMINHO',
                      'COLETANDO_PEDIDO',
                      'SAIU_PARA_ENTREGA'
                  )
                LIMIT 1
                `,
                [entregadorId]
            );

        if (
            entregaAtiva.rowCount > 0
        ) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "Você já possui uma entrega em andamento.",

                pedido:
                    entregaAtiva.rows[0]
            });
        }

        // ----------------------------------------------------
        // RESERVAR PEDIDO
        // ----------------------------------------------------

        const resultado =
            await pool.query(
                `
                UPDATE pedidos
                SET
                    entregador_id = $1,
                    status = 'ENTREGADOR_A_CAMINHO',
                    atualizado_em = NOW()
                WHERE id = $2
                  AND status = 'PRONTO'
                  AND entregador_id IS NULL
                RETURNING *
                `,
                [
                    entregadorId,
                    pedidoId
                ]
            );

        if (
            resultado.rowCount === 0
        ) {

            const pedidoAtual =
                await pool.query(
                    `
                    SELECT *
                    FROM pedidos
                    WHERE id = $1
                    LIMIT 1
                    `,
                    [pedidoId]
                );

            if (
                pedidoAtual.rowCount === 0
            ) {

                return res.status(404).json({

                    sucesso: false,

                    mensagem:
                        "Pedido não encontrado."
                });
            }

            return res.status(409).json({

                sucesso: false,

                mensagem:
                    "Pedido já foi aceito por outro entregador ou não está mais disponível.",

                pedido:
                    pedidoAtual.rows[0]
            });
        }

        const pedido =
            resultado.rows[0];

        // ----------------------------------------------------
        // SOCKET
        // ----------------------------------------------------

        if (global.io) {

            global.io.emit(
                "pedido_atualizado",
                pedido
            );

            global.io.emit(
                "entrega_reservada",
                {

                    pedidoId:
                        pedido.id,

                    entregadorId,

                    pedido
                }
            );
        }

        console.log(
            "✅ ENTREGA ACEITA"
        );

        console.log("==========================================");

        return res.json({

            sucesso: true,

            mensagem:
                "Entrega aceita com sucesso.",

            pedido
        });

    } catch (e) {

        console.error("");
        console.error(
            "❌ ERRO ACCEPT ORDER:"
        );

        console.error(e);

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao aceitar entrega.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// CHEGOU AO RESTAURANTE
// ============================================================

exports.arrivedRestaurant = async (req, res) => {

    try {

        const pedidoId =
            String(
                req.params.orderId || ""
            ).trim();

        if (!pedidoId) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "ID do pedido não informado."
            });
        }

        const resultado =
            await pool.query(
                `
                UPDATE pedidos
                SET
                    status = 'COLETANDO_PEDIDO',
                    atualizado_em = NOW()
                WHERE id = $1
                  AND entregador_id IS NOT NULL
                  AND status = 'ENTREGADOR_A_CAMINHO'
                RETURNING *
                `,
                [pedidoId]
            );

        if (
            resultado.rowCount === 0
        ) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "Pedido não pode ser marcado como chegada ao restaurante."
            });
        }

        const pedido =
            resultado.rows[0];

        if (global.io) {

            global.io.emit(
                "pedido_atualizado",
                pedido
            );
        }

        return res.json({

            sucesso: true,

            mensagem:
                "Entregador chegou ao restaurante.",

            pedido
        });

    } catch (e) {

        console.error(
            "❌ ERRO ARRIVED RESTAURANT:",
            e
        );

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao atualizar pedido.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// INICIAR ENTREGA
// ============================================================

exports.startDelivery = async (req, res) => {

    try {

        const pedidoId =
            String(
                req.params.orderId || ""
            ).trim();

        if (!pedidoId) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "ID do pedido não informado."
            });
        }

        const resultado =
            await pool.query(
                `
                UPDATE pedidos
                SET
                    status = 'SAIU_PARA_ENTREGA',
                    atualizado_em = NOW()
                WHERE id = $1
                  AND entregador_id IS NOT NULL
                  AND status = 'COLETANDO_PEDIDO'
                RETURNING *
                `,
                [pedidoId]
            );

        if (
            resultado.rowCount === 0
        ) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "Pedido não pode ser iniciado para entrega."
            });
        }

        const pedido =
            resultado.rows[0];

        if (global.io) {

            global.io.emit(
                "pedido_atualizado",
                pedido
            );
        }

        return res.json({

            sucesso: true,

            mensagem:
                "Pedido saiu para entrega.",

            pedido
        });

    } catch (e) {

        console.error(
            "❌ ERRO START DELIVERY:",
            e
        );

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao iniciar entrega.",

            detalhe:
                e.message
        });
    }
};


// ============================================================
// FINALIZAR ENTREGA + CARTEIRA
// ============================================================
//
// Modelo financeiro:
//
// Cliente paga R$100
//
// Restaurante = subtotal
// FoodJet     = taxa de serviço
// Entregador  = taxa de entrega
//
// Carteira:
//
// - total recebido do cliente
// + comissão do entregador
//
// Exemplo:
//
// -100 + 10 = -90
//
// DINHEIRO:
//
// dinheiro_em_maos +100
//
// PIX/CARTÃO/DÉBITO:
//
// dinheiro_em_maos não aumenta.
//
// ============================================================

exports.finishDelivery = async (req, res) => {

    const client =
        await pool.connect();

    try {

        const pedidoId =
            String(
                req.params.orderId || ""
            ).trim();

        if (!pedidoId) {

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "ID do pedido não informado."
            });
        }

        console.log("");
        console.log("==========================================");
        console.log("💰 FOODJET - FINALIZAR ENTREGA");
        console.log("==========================================");

        console.log(
            "📦 PEDIDO:",
            pedidoId
        );

        // ====================================================
        // TRANSAÇÃO
        // ====================================================

        await client.query("BEGIN");

        // ====================================================
        // BUSCAR PEDIDO COM LOCK
        // ====================================================

        const pedidoResult =
            await client.query(
                `
                SELECT *
                FROM pedidos
                WHERE id = $1
                  AND entregador_id IS NOT NULL
                FOR UPDATE
                `,
                [pedidoId]
            );

        if (
            pedidoResult.rowCount === 0
        ) {

            await client.query("ROLLBACK");

            return res.status(404).json({

                sucesso: false,

                mensagem:
                    "Pedido não encontrado ou sem entregador."
            });
        }

        const pedido =
            pedidoResult.rows[0];

        // ====================================================
        // VERIFICAR STATUS
        // ====================================================

        if (
            pedido.status !==
            "SAIU_PARA_ENTREGA"
        ) {

            await client.query("ROLLBACK");

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "Pedido não pode ser finalizado.",

                statusAtual:
                    pedido.status
            });
        }

        const entregadorId =
            String(
                pedido.entregador_id
            );

        // ====================================================
        // VALORES
        // ====================================================

        const total =
            Number(
                pedido.total
            ) || 0;

        const subtotal =
            Number(
                pedido.subtotal
            ) || 0;

        const taxaServico =
            Number(
                pedido.taxa_servico
            ) || 0;

        const taxaEntrega =
            Number(
                pedido.taxa_entrega
            ) || 0;

        if (total <= 0) {

            await client.query("ROLLBACK");

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "O pedido possui valor total inválido."
            });
        }

        // ====================================================
        // FORMA DE PAGAMENTO
        // ====================================================

        const formaPagamento =
            String(
                pedido.pagamento || ""
            )
                .trim()
                .toUpperCase();

        // ====================================================
        // DISTRIBUIÇÃO
        // ====================================================
        //
        // Neste modelo:
        //
        // subtotal       -> restaurante
        // taxa serviço   -> FoodJet
        // taxa entrega   -> entregador
        //
        // Exemplo:
        //
        // subtotal = 80
        // serviço  = 10
        // entrega  = 10
        //
        // total = 100
        //
        // ====================================================

        let valorRestaurante =
            subtotal;

        let valorFoodjet =
            taxaServico;

        let valorEntregador =
            taxaEntrega;

        // ====================================================
        // VALIDAR DISTRIBUIÇÃO
        // ====================================================

        let soma =
            valorRestaurante +
            valorFoodjet +
            valorEntregador;

        if (
            soma >
            total + 0.01
        ) {

            await client.query("ROLLBACK");

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "A distribuição financeira do pedido ultrapassa o valor total.",

                financeiro: {

                    total,

                    restaurante:
                        valorRestaurante,

                    foodjet:
                        valorFoodjet,

                    entregador:
                        valorEntregador,

                    soma
                }
            });
        }

        // ====================================================
        // CORRIGIR DIFERENÇA DE CENTAVOS
        // ====================================================

        const diferenca =
            total -
            (
                valorRestaurante +
                valorFoodjet +
                valorEntregador
            );

        if (
            Math.abs(diferenca) > 0 &&
            Math.abs(diferenca) <= 0.01
        ) {

            valorFoodjet +=
                diferenca;
        }

        // ====================================================
        // DINHEIRO EM MÃOS
        // ====================================================

        const ehDinheiro =
            formaPagamento === "DINHEIRO" ||
            formaPagamento === "CASH" ||
            formaPagamento === "ESPECIE" ||
            formaPagamento === "ESPÉCIE";

        const alteracaoDinheiroEmMaos =
            ehDinheiro
                ? total
                : 0;

        // ====================================================
        // BUSCAR CARTEIRA COM LOCK
        // ====================================================

        const carteiraResult =
            await client.query(
                `
                SELECT *
                FROM carteiras_entregadores
                WHERE entregador_id = $1
                FOR UPDATE
                `,
                [entregadorId]
            );

        if (
            carteiraResult.rowCount === 0
        ) {

            await client.query("ROLLBACK");

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "O entregador não possui uma carteira financeira."
            });
        }

        const carteira =
            carteiraResult.rows[0];

        // ====================================================
        // REFERÊNCIA ÚNICA
        // ====================================================

        const referencia =
            `PEDIDO-${pedido.id}-FINALIZACAO`;

        // ====================================================
        // VERIFICAR DUPLICIDADE
        // ====================================================

        const movimentoExistente =
            await client.query(
                `
                SELECT id
                FROM movimentacoes_carteira
                WHERE entregador_id = $1
                  AND referencia = $2
                LIMIT 1
                `,
                [
                    entregadorId,
                    referencia
                ]
            );

        if (
            movimentoExistente.rowCount > 0
        ) {

            await client.query("ROLLBACK");

            return res.status(409).json({

                sucesso: false,

                mensagem:
                    "A movimentação financeira deste pedido já foi registrada.",

                movimentacaoId:
                    movimentoExistente.rows[0].id
            });
        }

        // ====================================================
        // SALDOS
        // ====================================================

        const saldoAnterior =
            Number(
                carteira.saldo
            ) || 0;

        const dinheiroAnterior =
            Number(
                carteira.dinheiro_em_maos
            ) || 0;

        // ====================================================
        // NOVO SALDO
        //
        // Cliente pagou:
        //
        // -100
        //
        // Entregador recebe:
        //
        // +10
        //
        // Resultado:
        //
        // -90
        //
        // ====================================================

        const novoSaldo =
            saldoAnterior
            - total
            + valorEntregador;

        const novoDinheiroEmMaos =
            dinheiroAnterior
            + alteracaoDinheiroEmMaos;

        // ====================================================
        // LIMITE NEGATIVO
        // ====================================================

        const limiteNegativo =
            Number(
                carteira.limite_negativo
            ) || 200;

        if (
            novoSaldo <
            -Math.abs(limiteNegativo)
        ) {

            await client.query("ROLLBACK");

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "O entregador atingiu o limite negativo da carteira.",

                saldoAtual:
                    saldoAnterior,

                novoSaldo,

                limiteNegativo:
                    -Math.abs(
                        limiteNegativo
                    )
            });
        }

        // ====================================================
        // FINALIZAR PEDIDO
        // ====================================================

        const pedidoAtualizadoResult =
            await client.query(
                `
                UPDATE pedidos
                SET
                    status = 'ENTREGUE',
                    entregue_em = NOW(),
                    atualizado_em = NOW()
                WHERE id = $1
                  AND entregador_id = $2
                  AND status = 'SAIU_PARA_ENTREGA'
                RETURNING *
                `,
                [
                    pedidoId,
                    entregadorId
                ]
            );

        if (
            pedidoAtualizadoResult.rowCount === 0
        ) {

            await client.query("ROLLBACK");

            return res.status(400).json({

                sucesso: false,

                mensagem:
                    "Pedido não pode ser finalizado."
            });
        }

        const pedidoFinalizado =
            pedidoAtualizadoResult.rows[0];

        // ====================================================
        // ATUALIZAR CARTEIRA
        // ====================================================

        const carteiraAtualizadaResult =
            await client.query(
                `
                UPDATE carteiras_entregadores
                SET

                    saldo = $1,

                    dinheiro_em_maos = $2,

                    total_comissoes =
                        total_comissoes + $3,

                    total_recebido_clientes =
                        total_recebido_clientes + $4,

                    total_devido_restaurante =
                        total_devido_restaurante + $5,

                    total_devido_foodjet =
                        total_devido_foodjet + $6,

                    atualizado_em = NOW()

                WHERE id = $7

                RETURNING *
                `,
                [
                    novoSaldo,

                    novoDinheiroEmMaos,

                    valorEntregador,

                    total,

                    valorRestaurante,

                    valorFoodjet,

                    carteira.id
                ]
            );

        if (
            carteiraAtualizadaResult.rowCount === 0
        ) {

            throw new Error(
                "Não foi possível atualizar a carteira."
            );
        }

        const carteiraAtualizada =
            carteiraAtualizadaResult.rows[0];

        // ====================================================
        // REGISTRAR EXTRATO
        // ====================================================

        const movimentacaoResult =
            await client.query(
                `
                INSERT INTO movimentacoes_carteira (

                    carteira_id,

                    entregador_id,

                    pedido_id,

                    tipo,

                    descricao,

                    forma_pagamento,

                    valor,

                    saldo_anterior,

                    saldo_posterior,

                    valor_restaurante,

                    valor_foodjet,

                    valor_entregador,

                    dinheiro_em_maos_anterior,

                    dinheiro_em_maos_posterior,

                    referencia,

                    dados

                )

                VALUES (

                    $1,
                    $2,
                    $3,
                    $4,
                    $5,
                    $6,
                    $7,
                    $8,
                    $9,
                    $10,
                    $11,
                    $12,
                    $13,
                    $14,
                    $15,
                    $16

                )

                RETURNING *
                `,
                [

                    carteira.id,

                    entregadorId,

                    pedido.id,

                    "ENTREGA_FINALIZADA",

                    `Pagamento do pedido #${pedido.id}`,

                    formaPagamento || null,

                    total,

                    saldoAnterior,

                    novoSaldo,

                    valorRestaurante,

                    valorFoodjet,

                    valorEntregador,

                    dinheiroAnterior,

                    novoDinheiroEmMaos,

                    referencia,

                    JSON.stringify({

                        pedidoId:
                            pedido.id,

                        total,

                        subtotal,

                        taxaServico,

                        taxaEntrega,

                        formaPagamento,

                        valorRestaurante,

                        valorFoodjet,

                        valorEntregador,

                        saldoAnterior,

                        saldoPosterior:
                            novoSaldo
                    })
                ]
            );

        const movimentacao =
            movimentacaoResult.rows[0];

        // ====================================================
        // COMMIT
        // ====================================================

        await client.query("COMMIT");

        // ====================================================
        // LOG
        // ====================================================

        console.log("");
        console.log("==========================================");
        console.log("💰 MOVIMENTAÇÃO FINANCEIRA CONFIRMADA");
        console.log("==========================================");

        console.log(
            "📦 PEDIDO:",
            pedido.id
        );

        console.log(
            "🏍️ ENTREGADOR:",
            entregadorId
        );

        console.log(
            "💳 PAGAMENTO:",
            formaPagamento || "NÃO INFORMADO"
        );

        console.log(
            "💵 TOTAL:",
            `R$ ${total.toFixed(2)}`
        );

        console.log(
            "🏪 RESTAURANTE:",
            `R$ ${valorRestaurante.toFixed(2)}`
        );

        console.log(
            "🟠 FOODJET:",
            `R$ ${valorFoodjet.toFixed(2)}`
        );

        console.log(
            "🏍️ COMISSÃO:",
            `R$ ${valorEntregador.toFixed(2)}`
        );

        console.log(
            "💰 SALDO ANTERIOR:",
            `R$ ${saldoAnterior.toFixed(2)}`
        );

        console.log(
            "💰 SALDO ATUAL:",
            `R$ ${novoSaldo.toFixed(2)}`
        );

        console.log(
            "💵 DINHEIRO EM MÃOS:",
            `R$ ${novoDinheiroEmMaos.toFixed(2)}`
        );

        console.log(
            "📒 MOVIMENTAÇÃO:",
            movimentacao.id
        );

        console.log("==========================================");

        // ====================================================
        // SOCKET
        // ====================================================

        if (global.io) {

            global.io.emit(
                "pedido_atualizado",
                pedidoFinalizado
            );

            global.io.emit(
                "carteira_entregador_atualizada",
                {

                    entregadorId,

                    carteira:
                        carteiraAtualizada,

                    movimentacao
                }
            );
        }

        // ====================================================
        // RESPOSTA
        // ====================================================

        return res.json({

            sucesso: true,

            mensagem:
                "Entrega finalizada e movimentação financeira registrada.",

            pedido:
                pedidoFinalizado,

            financeiro: {

                total,

                formaPagamento,

                restaurante:
                    valorRestaurante,

                foodjet:
                    valorFoodjet,

                entregador:
                    valorEntregador,

                saldoAnterior,

                saldoAtual:
                    novoSaldo,

                dinheiroEmMaos:
                    novoDinheiroEmMaos
            },

            movimentacaoId:
                movimentacao.id
        });

    } catch (e) {

        try {
            await client.query(
                "ROLLBACK"
            );
        } catch (_) {}

        console.error("");
        console.error(
            "❌ ERRO FINANCEIRO AO FINALIZAR ENTREGA:"
        );

        console.error(e);

        console.error(
            "Mensagem:",
            e.message
        );

        console.error("==========================================");

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Erro ao finalizar entrega e registrar movimentação financeira.",

            detalhe:
                e.message
        });

    } finally {

        client.release();
    }
};


// ============================================================
// EXPORTAÇÃO
// ============================================================

console.log(
    "✅ CONTROLLER ENTREGADORES CARREGADO"
);


// ============================================================
// CARTEIRA / GANHOS DO ENTREGADOR
// ============================================================

exports.wallet = async (req, res) => {
    try {

        const entregadorId =
            String(
                req.params.id || ""
            ).trim();

        if (!entregadorId) {

            return res.status(400).json({
                sucesso: false,
                mensagem:
                    "ID do entregador não informado."
            });
        }

        // ====================================================
        // GARANTIR CARTEIRA
        // ====================================================

        await Wallet.garantir(
            entregadorId
        );

        // ====================================================
        // RESUMO
        // ====================================================

        const resumo =
            await Wallet.resumo(
                entregadorId
            );

        // ====================================================
        // EXTRATO
        // ====================================================

        const extrato =
            await Wallet.extrato(
                entregadorId,
                20
            );

        // ====================================================
        // RESPOSTA
        // ====================================================

        return res.status(200).json({

            sucesso: true,

            dados: {

                ganhosHoje:
                    Number(
                        resumo.ganhosHoje
                    ) || 0,

                entregasHoje:
                    Number(
                        resumo.entregasHoje
                    ) || 0,

                recebidoHoje:
                    Number(
                        resumo.recebidoHoje
                    ) || 0,

                ganhosTotais:
                    Number(
                        resumo.ganhosTotais
                    ) || 0,

                entregasTotais:
                    Number(
                        resumo.entregasTotais
                    ) || 0,

                recebidoTotal:
                    Number(
                        resumo.recebidoTotal
                    ) || 0,

                saldo:
                    Number(
                        resumo.saldo
                    ) || 0,

                dinheiroEmMaos:
                    Number(
                        resumo.dinheiroEmMaos
                    ) || 0,

                totalComissoes:
                    Number(
                        resumo.totalComissoes
                    ) || 0,

                totalRecebidoClientes:
                    Number(
                        resumo.totalRecebidoClientes
                    ) || 0,

                totalDevidoRestaurante:
                    Number(
                        resumo.totalDevidoRestaurante
                    ) || 0,

                totalDevidoFoodjet:
                    Number(
                        resumo.totalDevidoFoodjet
                    ) || 0,

                limiteNegativo:
                    Number(
                        resumo.limiteNegativo
                    ) || 0,

                extrato:
                    extrato || []
            }
        });

    } catch (error) {

        console.error("");
        console.error(
            "❌ ERRO AO BUSCAR CARTEIRA:"
        );

        console.error(error);

        return res.status(500).json({

            sucesso: false,

            mensagem:
                "Não foi possível carregar os ganhos do entregador.",

            detalhe:
                error.message
        });
    }
};

