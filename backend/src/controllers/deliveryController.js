
const Delivery = require("../models/delivery");
const Order = require("../models/order");
const { pool } = require("../config/database");

// ============================================================
// FOODJET - CONTROLLER DE ENTREGADORES
// ============================================================
//
// Rotas suportadas:
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
                mensagem: "Nome e telefone são obrigatórios."
            });
        }

        // ----------------------------------------------------
        // Se o ID vier do usuário, usamos o mesmo ID.
        // Isso mantém:
        //
        // usuarios.id
        // =
        // entregadores.id
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

        const criado =
            await Delivery.criar(entregador);

        console.log("");
        console.log("==========================================");
        console.log("🛵 FOODJET - ENTREGADOR CADASTRADO");
        console.log("==========================================");
        console.log("🆔 ID:", criado.id);
        console.log("👤 NOME:", criado.nome);
        console.log("📧 EMAIL:", criado.email);
        console.log("📱 TELEFONE:", criado.telefone);
        console.log("🌐 ONLINE:", criado.online);
        console.log("📌 STATUS:", criado.status);
        console.log("==========================================");

        return res.status(201).json({
            sucesso: true,
            mensagem: "Entregador cadastrado com sucesso.",
            entregador: criado
        });

    } catch (e) {
        console.error("");
        console.error("❌ ERRO CREATE DELIVERY:");
        console.error(e);
        console.error("Mensagem:", e.message);

        return res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao cadastrar entregador.",
            detalhe: e.message
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
            total: entregadores.length,
            entregadores
        });

    } catch (e) {
        console.error("");
        console.error("❌ ERRO LIST DELIVERY:");
        console.error(e);

        return res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao listar entregadores.",
            detalhe: e.message
        });
    }
};


// ============================================================
// ALTERAR STATUS ONLINE / OFFLINE
// ============================================================

exports.status = async (req, res) => {
    try {
        const id =
            String(req.params.id || "").trim();

        if (!id) {
            return res.status(400).json({
                sucesso: false,
                mensagem: "ID do entregador não informado."
            });
        }

        // ----------------------------------------------------
        // Aceita:
        //
        // true
        // "true"
        // 1
        //
        // e considera o restante como false.
        // ----------------------------------------------------

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
        console.log("🆔 ID:", id);
        console.log("📥 ONLINE RECEBIDO:", valorOnline);
        console.log("🌐 ONLINE NORMALIZADO:", online);

        // ----------------------------------------------------
        // VERIFICAR ENTREGADOR
        // ----------------------------------------------------

        const entregador =
            await Delivery.buscarPorId(id);

        if (!entregador) {
            console.log(
                "❌ ENTREGADOR NÃO ENCONTRADO:",
                id
            );

            return res.status(404).json({
                sucesso: false,
                mensagem: "Entregador não encontrado."
            });
        }

        console.log(
            "✅ ENTREGADOR ENCONTRADO:",
            entregador.id
        );

        console.log(
            "📌 STATUS ATUAL:",
            entregador.status
        );

        console.log(
            "🌐 ONLINE ATUAL:",
            entregador.online
        );

        // ----------------------------------------------------
        // ATUALIZAR
        //
        // IMPORTANTE:
        // Usa o Model Delivery.
        //
        // Não usamos diretamente:
        //
        // atualizado_em = NOW()
        //
        // porque essa coluna não faz parte da estrutura
        // confirmada do seu model.
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
        console.log("🆔 ID:", atualizado.id);
        console.log("🌐 ONLINE:", atualizado.online);
        console.log("📌 STATUS:", atualizado.status);
        console.log("==========================================");

        // ----------------------------------------------------
        // SOCKET.IO
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

            entregador: atualizado
        });

    } catch (e) {
        console.error("");
        console.error("❌ ERRO STATUS DELIVERY:");
        console.error(e);
        console.error("Mensagem:", e.message);
        console.error("==========================================");

        return res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao atualizar status.",
            detalhe: e.message
        });
    }
};


// ============================================================
// PEDIDOS DO ENTREGADOR
// ============================================================

exports.myOrders = async (req, res) => {
    try {
        const id =
            String(req.params.id || "").trim();

        if (!id) {
            return res.status(400).json({
                sucesso: false,
                mensagem: "ID do entregador não informado."
            });
        }

        console.log("");
        console.log("==========================================");
        console.log("🛵 FOODJET - PEDIDOS DO ENTREGADOR");
        console.log("==========================================");
        console.log("🆔 ENTREGADOR:", id);

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
            total: resultado.rows.length,
            pedidos: resultado.rows
        });

    } catch (e) {
        console.error("");
        console.error("❌ ERRO MY ORDERS:");
        console.error(e);
        console.error("Mensagem:", e.message);

        return res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao buscar pedidos.",
            detalhe: e.message
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
            total: resultado.rows.length,
            pedidos: resultado.rows
        });

    } catch (e) {
        console.error("");
        console.error(
            "❌ ERRO AVAILABLE ORDERS:"
        );
        console.error(e);
        console.error("Mensagem:", e.message);

        return res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao buscar entregas disponíveis.",
            detalhe: e.message
        });
    }
};


// ============================================================
// ACEITAR ENTREGA
// ============================================================

exports.acceptOrder = async (req, res) => {
    try {
        const entregadorId =
            String(req.params.id || "").trim();

        const pedidoId =
            String(req.params.orderId || "").trim();

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
        console.log("🆔 ENTREGADOR:", entregadorId);
        console.log("📦 PEDIDO:", pedidoId);

        // ----------------------------------------------------
        // VERIFICAR ENTREGADOR
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
        // PRECISA ESTAR ONLINE
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
        // VERIFICAR SE JÁ POSSUI ENTREGA ATIVA
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
        console.error("Mensagem:", e.message);

        return res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao aceitar entrega.",
            detalhe: e.message
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
            detalhe: e.message
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
            detalhe: e.message
        });
    }
};


// ============================================================
// FINALIZAR ENTREGA
// ============================================================

exports.finishDelivery = async (req, res) => {
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
                    status = 'ENTREGUE',
                    entregue_em = NOW(),
                    atualizado_em = NOW()
                WHERE id = $1
                  AND entregador_id IS NOT NULL
                  AND status = 'SAIU_PARA_ENTREGA'
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
                    "Pedido não pode ser finalizado."
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
                "Entrega finalizada.",
            pedido
        });

    } catch (e) {
        console.error(
            "❌ ERRO FINISH DELIVERY:",
            e
        );

        return res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao finalizar entrega.",
            detalhe: e.message
        });
    }
};


// ============================================================
// EXPORTAÇÃO FINAL
// ============================================================

console.log("✅ CONTROLLER ENTREGADORES CARREGADO");


