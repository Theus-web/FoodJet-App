
const Order = require("../models/order");

// ======================================================
// CRIAR PEDIDO
// POST /api/orders
// ======================================================

exports.create = async (req, res) => {
    try {
        const pedido = {
            id: Date.now(),

            clienteId: req.body.clienteId,

            restauranteId: req.body.restauranteId,

            itens: req.body.itens || [],

            endereco: req.body.endereco || {},

            pagamento: req.body.pagamento || "PIX",

            subtotal: Number(req.body.subtotal) || 0,

            taxaEntrega: Number(req.body.taxaEntrega) || 0,

            total: Number(req.body.total) || 0,

            status: "AGUARDANDO_RESTAURANTE",

            criadoEm: new Date().toISOString()
        };

        if (!pedido.clienteId) {
            return res.status(400).json({
                erro: "clienteId é obrigatório"
            });
        }

        if (!pedido.restauranteId) {
            return res.status(400).json({
                erro: "restauranteId é obrigatório"
            });
        }

        await Order.criar(pedido);

        // ==================================================
        // SOCKET - NOVO PEDIDO
        // ==================================================

        if (global.io) {
            const salaRestaurante =
                "restaurante_" + pedido.restauranteId;

            global.io
                .to(salaRestaurante)
                .emit("novo_pedido", pedido);

            console.log(
                "🔔 NOVO PEDIDO ENVIADO PARA:",
                salaRestaurante
            );
        }

        console.log("📦 NOVO PEDIDO CRIADO");
        console.log("🆔 ID:", pedido.id);
        console.log("🏪 RESTAURANTE:", pedido.restauranteId);
        console.log("👤 CLIENTE:", pedido.clienteId);
        console.log("💰 TOTAL:", pedido.total);
        console.log("📌 STATUS:", pedido.status);

        return res.status(201).json({
            mensagem: "Pedido criado com sucesso",
            pedido
        });

    } catch (erro) {
        console.error(
            "❌ ERRO AO CRIAR PEDIDO:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao criar pedido",
            detalhes: erro.message
        });
    }
};


// ======================================================
// LISTAR TODOS OS PEDIDOS
// GET /api/orders
// ======================================================

exports.list = async (req, res) => {
    try {
        const pedidos = await Order.listar();

        return res.status(200).json(pedidos);

    } catch (erro) {
        console.error(
            "❌ ERRO AO LISTAR PEDIDOS:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao listar pedidos",
            detalhes: erro.message
        });
    }
};


// ======================================================
// BUSCAR PEDIDO PELO ID
// GET /api/orders/:id
// ======================================================

exports.getById = async (req, res) => {
    try {
        const id = Number(req.params.id);

        if (!id) {
            return res.status(400).json({
                erro: "ID do pedido inválido"
            });
        }

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro: "Pedido não encontrado"
            });
        }

        return res.status(200).json(pedido);

    } catch (erro) {
        console.error(
            "❌ ERRO AO BUSCAR PEDIDO:",
            erro
        );

        return res.status(500).json({
            erro: "Erro interno ao buscar pedido",
            detalhes: erro.message
        });
    }
};


// ======================================================
// ATUALIZAR STATUS
// PUT /api/orders/:id/status
// ======================================================

exports.updateStatus = async (req, res) => {
    try {
        const id = Number(req.params.id);

        const novoStatus =
            req.body.status;

        if (!id) {
            return res.status(400).json({
                erro: "ID do pedido inválido"
            });
        }

        if (!novoStatus) {
            return res.status(400).json({
                erro: "Status não informado"
            });
        }

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro: "Pedido não encontrado"
            });
        }

        pedido.status = novoStatus;

        pedido.atualizadoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );

        if (index === -1) {
            return res.status(404).json({
                erro: "Pedido não encontrado na base"
            });
        }

        pedidos[index] = pedido;

        const { db } =
            require("../config/database");

        await db.write();

        // ==================================================
        // SOCKET
        // ==================================================

        if (global.io) {
            global.io.emit(
                "status_pedido",
                pedido
            );
        }

        console.log(
            "🔄 STATUS ATUALIZADO:",
            id,
            novoStatus
        );

        return res.status(200).json({
            mensagem:
                "Status atualizado com sucesso",
            pedido
        });

    } catch (erro) {
        console.error(
            "❌ ERRO AO ATUALIZAR STATUS:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao atualizar status",
            detalhes: erro.message
        });
    }
};


// ======================================================
// PEDIDOS DO RESTAURANTE
// GET /api/orders/restaurante/:id
// ======================================================

exports.restaurantOrders = async (req, res) => {
    try {
        const restauranteId =
            req.params.id;

        const pedidos =
            await Order.listarPorRestaurante(
                restauranteId
            );

        return res.status(200).json(pedidos);

    } catch (erro) {
        console.error(
            "❌ ERRO PEDIDOS RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao buscar pedidos",
            detalhes: erro.message
        });
    }
};


// ======================================================
// PEDIDOS DO CLIENTE
// GET /api/orders/cliente/:id
// ======================================================

exports.clientOrders = async (req, res) => {
    try {
        const clienteId =
            req.params.id;

        if (!clienteId) {
            return res.status(400).json({
                erro: "ID do cliente é obrigatório"
            });
        }

        const pedidos =
            await Order.listar();

        const pedidosCliente =
            pedidos.filter(
                pedido =>
                    String(pedido.clienteId) ===
                    String(clienteId)
            );

        return res.status(200).json(
            pedidosCliente
        );

    } catch (erro) {
        console.error(
            "❌ ERRO PEDIDOS CLIENTE:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao buscar pedidos do cliente",
            detalhes: erro.message
        });
    }
};


// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// GET /api/orders/delivery/available
// ======================================================

exports.availableDeliveries = async (req, res) => {
    try {
        const pedidos =
            await Order.listarDisponiveisEntrega();

        return res.status(200).json(pedidos);

    } catch (erro) {
        console.error(
            "❌ ERRO PEDIDOS DISPONÍVEIS:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao buscar pedidos disponíveis",
            detalhes:
                erro.message
        });
    }
};


// ======================================================
// RESTAURANTE ACEITA PEDIDO
// PUT /api/orders/:id/accept
// ======================================================

exports.acceptRestaurant = async (req, res) => {
    try {
        const id =
            Number(req.params.id);

        if (!id) {
            return res.status(400).json({
                erro: "ID do pedido inválido"
            });
        }

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro: "Pedido não encontrado"
            });
        }

        if (
            pedido.status !==
            "AGUARDANDO_RESTAURANTE"
        ) {
            return res.status(400).json({
                erro:
                    "Este pedido não está aguardando aceitação do restaurante",
                statusAtual:
                    pedido.status
            });
        }

        pedido.status =
            "ACEITO_RESTAURANTE";

        pedido.aceitoRestauranteEm =
            new Date().toISOString();

        pedido.atualizadoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );

        pedidos[index] = pedido;

        const { db } =
            require("../config/database");

        await db.write();

        if (global.io) {
            global.io.emit(
                "status_pedido",
                pedido
            );
        }

        return res.status(200).json({
            mensagem:
                "Pedido aceito pelo restaurante",
            pedido
        });

    } catch (erro) {
        console.error(
            "❌ ERRO AO ACEITAR PEDIDO:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao aceitar pedido",
            detalhes:
                erro.message
        });
    }
};


// ======================================================
// RESTAURANTE RECUSA PEDIDO
// PUT /api/orders/:id/reject
// ======================================================

exports.rejectRestaurant = async (req, res) => {
    try {
        const id =
            Number(req.params.id);

        if (!id) {
            return res.status(400).json({
                erro: "ID do pedido inválido"
            });
        }

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro: "Pedido não encontrado"
            });
        }

        if (
            pedido.status !==
            "AGUARDANDO_RESTAURANTE"
        ) {
            return res.status(400).json({
                erro:
                    "Este pedido não pode mais ser recusado"
            });
        }

        pedido.status =
            "RECUSADO_RESTAURANTE";

        pedido.recusadoRestauranteEm =
            new Date().toISOString();

        pedido.motivoRecusa =
            req.body.motivo || "";

        pedido.atualizadoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );

        pedidos[index] = pedido;

        const { db } =
            require("../config/database");

        await db.write();

        if (global.io) {
            global.io.emit(
                "status_pedido",
                pedido
            );
        }

        return res.status(200).json({
            mensagem:
                "Pedido recusado pelo restaurante",
            pedido
        });

    } catch (erro) {
        console.error(
            "❌ ERRO AO RECUSAR PEDIDO:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao recusar pedido",
            detalhes:
                erro.message
        });
    }
};


// ======================================================
// ENTREGADOR ACEITA PEDIDO
// PUT /api/orders/:id/accept-delivery
// ======================================================

exports.acceptDelivery = async (req, res) => {
    try {
        const id =
            Number(req.params.id);

        const entregadorId =
            req.body.entregadorId;

        if (!id) {
            return res.status(400).json({
                erro: "ID do pedido inválido"
            });
        }

        if (!entregadorId) {
            return res.status(400).json({
                erro:
                    "ID do entregador não informado"
            });
        }

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro:
                    "Pedido não encontrado"
            });
        }

        if (
            pedido.entregadorId &&
            String(pedido.entregadorId) !==
            String(entregadorId)
        ) {
            return res.status(409).json({
                erro:
                    "Este pedido já foi aceito por outro entregador"
            });
        }

        pedido.entregadorId =
            entregadorId;

        pedido.status =
            "EM_ENTREGA";

        pedido.aceitoEm =
            new Date().toISOString();

        pedido.atualizadoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );

        pedidos[index] = pedido;

        const { db } =
            require("../config/database");

        await db.write();

        if (global.io) {
            global.io.emit(
                "status_pedido",
                pedido
            );
        }

        return res.status(200).json({
            mensagem:
                "Pedido aceito pelo entregador",
            pedido
        });

    } catch (erro) {
        console.error(
            "❌ ERRO AO ACEITAR PEDIDO:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao aceitar pedido",
            detalhes:
                erro.message
        });
    }
};


// ======================================================
// FINALIZAR ENTREGA
// PUT /api/orders/:id/complete
// ======================================================

exports.completeDelivery = async (req, res) => {
    try {
        const id =
            Number(req.params.id);

        const entregadorId =
            req.body.entregadorId;

        if (!id) {
            return res.status(400).json({
                erro:
                    "ID do pedido inválido"
            });
        }

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro:
                    "Pedido não encontrado"
            });
        }

        if (
            entregadorId &&
            pedido.entregadorId &&
            String(pedido.entregadorId) !==
            String(entregadorId)
        ) {
            return res.status(403).json({
                erro:
                    "Este pedido pertence a outro entregador"
            });
        }

        if (
            pedido.status ===
            "ENTREGUE"
        ) {
            return res.status(400).json({
                erro:
                    "Este pedido já foi entregue"
            });
        }

        if (
            pedido.status !==
            "EM_ENTREGA"
        ) {
            return res.status(400).json({
                erro:
                    "O pedido precisa estar em entrega para ser finalizado",
                statusAtual:
                    pedido.status
            });
        }

        pedido.status =
            "ENTREGUE";

        pedido.entregueEm =
            new Date().toISOString();

        pedido.atualizadoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );

        if (index === -1) {
            return res.status(404).json({
                erro:
                    "Pedido não encontrado na base de dados"
            });
        }

        pedidos[index] =
            pedido;

        const { db } =
            require("../config/database");

        await db.write();

        if (global.io) {
            global.io.emit(
                "status_pedido",
                pedido
            );
        }

        console.log(
            "✅ PEDIDO ENTREGUE:",
            pedido.id
        );

        return res.status(200).json({
            mensagem:
                "Entrega finalizada com sucesso",
            pedido
        });

    } catch (erro) {
        console.error(
            "❌ ERRO AO FINALIZAR ENTREGA:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao finalizar entrega",
            detalhes:
                erro.message
        });
    }
};


// ======================================================
// ABRIR SUPORTE
// POST /api/orders/:id/support
// ======================================================

exports.openSupport = async (req, res) => {
    try {
        const id =
            Number(req.params.id);

        if (!id) {
            return res.status(400).json({
                erro:
                    "ID do pedido inválido"
            });
        }

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro:
                    "Pedido não encontrado"
            });
        }

        pedido.suporte =
            pedido.suporte || {};

        pedido.suporte.aberto =
            true;

        pedido.suporte.mensagem =
            req.body.mensagem || "";

        pedido.suporte.abertoEm =
            new Date().toISOString();

        pedido.atualizadoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                item =>
                    Number(item.id) === id
            );

        if (index !== -1) {
            pedidos[index] =
                pedido;
        }

        const { db } =
            require("../config/database");

        await db.write();

        if (global.io) {
            global.io.emit(
                "suporte_pedido",
                pedido
            );
        }

        return res.status(200).json({
            mensagem:
                "Suporte aberto com sucesso",
            pedido
        });

    } catch (erro) {
        console.error(
            "❌ ERRO AO ABRIR SUPORTE:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao abrir suporte",
            detalhes:
                erro.message
        });
    }
};
