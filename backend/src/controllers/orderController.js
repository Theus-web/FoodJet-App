const Order = require("../models/order");

// ======================================================
// OBTER USUÁRIO AUTENTICADO
// ======================================================

function obterUsuarioAutenticado(req) {
    const usuario = req.usuario || req.user || null;

    if (!usuario) return null;

    const id =
        usuario.id ||
        usuario.usuarioId ||
        usuario.userId ||
        usuario._id ||
        null;

    if (!id) return null;

    return {
        ...usuario,
        id: String(id).trim(),
    };
}

// ======================================================
// CRIAR PEDIDO
// ======================================================

async function create(req, res) {
    try {
        console.log("");
        console.log("========================================");
        console.log("📦 CONTROLLER - CRIAR PEDIDO");
        console.log("========================================");

        const usuario = obterUsuarioAutenticado(req);

        if (!usuario) {
            return res.status(401).json({
                sucesso: false,
                erro: "Cliente não identificado. Faça login novamente.",
            });
        }

        const body = req.body || {};

        if (!body.restauranteId) {
            return res.status(400).json({
                sucesso: false,
                erro: "Restaurante não identificado.",
            });
        }

        if (!Array.isArray(body.itens) || body.itens.length === 0) {
            return res.status(400).json({
                sucesso: false,
                erro: "O pedido precisa possuir pelo menos um item.",
            });
        }

        const pedido = await Order.criar({
            clienteId: usuario.id,
            restauranteId: String(body.restauranteId).trim(),
            itens: body.itens,
            endereco: body.endereco || {},
            pagamento: String(body.pagamento || "PIX").toUpperCase(),
            subtotal: Number(body.subtotal) || 0,
            taxaServico: Number(body.taxaServico) || 0,
            taxaEntrega: Number(body.taxaEntrega) || 0,
            total: Number(body.total) || 0,
            precisaTroco: Boolean(body.precisaTroco),
            trocoPara:
                body.trocoPara !== undefined &&
                body.trocoPara !== null
                    ? Number(body.trocoPara)
                    : null,
            valorTroco: Number(body.valorTroco) || 0,
        });

        console.log("========================================");
        console.log("✅ PEDIDO CRIADO PELO CONTROLLER");
        console.log("ID:", pedido.id);
        console.log("CLIENTE:", pedido.clienteId);
        console.log("RESTAURANTE:", pedido.restauranteId);
        console.log("STATUS:", pedido.status);
        console.log("========================================");

        return res.status(201).json({
            sucesso: true,
            mensagem: "Pedido criado com sucesso.",
            pedido,
            pedidoId: pedido.id,
        });
    } catch (error) {
        console.error("❌ ERRO CONTROLLER CRIAR PEDIDO:", error);

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao criar pedido",
            detalhes: error.message,
        });
    }
}

// ======================================================
// LISTAR PEDIDOS
// ======================================================

async function list(req, res) {
    try {
        const pedidos = await Order.listar();

        return res.json({
            sucesso: true,
            pedidos,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao listar pedidos",
            detalhes: error.message,
        });
    }
}

// ======================================================
// BUSCAR PEDIDO
// ======================================================

async function getById(req, res) {
    try {
        const pedido = await Order.buscarPorId(req.params.id);

        if (!pedido) {
            return res.status(404).json({
                sucesso: false,
                erro: "Pedido não encontrado.",
            });
        }

        return res.json({
            sucesso: true,
            pedido,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedido",
            detalhes: error.message,
        });
    }
}

// ======================================================
// ATUALIZAR STATUS
// ======================================================

async function updateStatus(req, res) {
    try {
        const { status } = req.body;

        if (!status) {
            return res.status(400).json({
                sucesso: false,
                erro: "Status não informado.",
            });
        }

        const pedido = await Order.atualizarStatus(
            req.params.id,
            status
        );

        if (!pedido) {
            return res.status(404).json({
                sucesso: false,
                erro: "Pedido não encontrado.",
            });
        }

        return res.json({
            sucesso: true,
            pedido,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao atualizar status",
            detalhes: error.message,
        });
    }
}

// ======================================================
// PEDIDOS DO RESTAURANTE
// ======================================================

async function restaurantOrders(req, res) {
    try {
        const pedidos =
            await Order.listarPorRestaurante(req.params.id);

        return res.json({
            sucesso: true,
            pedidos,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedidos do restaurante",
            detalhes: error.message,
        });
    }
}

// ======================================================
// PEDIDOS DO CLIENTE
// ======================================================

async function clientOrders(req, res) {
    try {
        const pedidos =
            await Order.listarPorCliente(req.params.id);

        return res.json({
            sucesso: true,
            pedidos,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedidos do cliente",
            detalhes: error.message,
        });
    }
}

// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ======================================================

async function availableDeliveries(req, res) {
    try {
        const pedidos =
            await Order.listarDisponiveisEntrega();

        return res.json({
            sucesso: true,
            pedidos,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedidos disponíveis",
            detalhes: error.message,
        });
    }
}

// ======================================================
// RESTAURANTE ACEITA PEDIDO
// ======================================================

async function acceptRestaurant(req, res) {
    try {
        const pedido =
            await Order.aceitarPedidoRestaurante(req.params.id);

        if (!pedido) {
            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está aguardando o restaurante.",
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Pedido aceito pelo restaurante.",
            pedido,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao aceitar pedido",
            detalhes: error.message,
        });
    }
}

// ======================================================
// RESTAURANTE RECUSA PEDIDO
// ======================================================

async function rejectRestaurant(req, res) {
    try {
        const pedido =
            await Order.recusarPedidoRestaurante(
                req.params.id,
                req.body.motivo
            );

        if (!pedido) {
            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está aguardando o restaurante.",
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Pedido recusado.",
            pedido,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao recusar pedido",
            detalhes: error.message,
        });
    }
}

// ======================================================
// ENTREGADOR ACEITA ENTREGA
// ======================================================

async function acceptDelivery(req, res) {
    try {
        const pedido = await Order.aceitarEntrega(
            req.params.id,
            req.body.entregadorId
        );

        if (!pedido) {
            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está disponível para entrega.",
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Entrega aceita.",
            pedido,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao aceitar entrega",
            detalhes: error.message,
        });
    }
}

// ======================================================
// FINALIZAR ENTREGA
// ======================================================

async function completeDelivery(req, res) {
    try {
        const pedido =
            await Order.finalizarEntrega(req.params.id);

        if (!pedido) {
            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está em entrega.",
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Entrega finalizada.",
            pedido,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao finalizar entrega",
            detalhes: error.message,
        });
    }
}

// ======================================================
// ABRIR SUPORTE
// ======================================================

async function openSupport(req, res) {
    try {
        const usuario = obterUsuarioAutenticado(req);

        const pedido = await Order.abrirSuporte(
            req.params.id,
            usuario.id,
            usuario.tipo || "CLIENTE",
            req.body.mensagem,
            req.body.motivo
        );

        if (!pedido) {
            return res.status(404).json({
                sucesso: false,
                erro: "Pedido não encontrado.",
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Suporte aberto.",
            pedido,
        });
    } catch (error) {
        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao abrir suporte",
            detalhes: error.message,
        });
    }
}

module.exports = {
    create,
    list,
    getById,
    updateStatus,
    restaurantOrders,
    clientOrders,
    availableDeliveries,
    acceptRestaurant,
    rejectRestaurant,
    acceptDelivery,
    completeDelivery,
    openSupport,
};