
const Order = require("../models/order");

// ======================================================
// CRIAR PEDIDO
// ======================================================
//
// O cliente é obtido do JWT:
//
// req.usuario.id
//
// O Flutter NÃO define clienteId.
//
// ======================================================

async function create(req, res) {
    try {

        console.log("========================================");
        console.log("📦 CONTROLLER - CRIAR PEDIDO");
        console.log("========================================");

        // ==================================================
        // VERIFICAR USUÁRIO AUTENTICADO
        // ==================================================

        console.log("REQ.USUARIO:", req.usuario);

        if (
            !req.usuario ||
            !req.usuario.id
        ) {

            console.error(
                "❌ req.usuario.id não encontrado."
            );

            return res.status(401).json({
                sucesso: false,
                erro: "Cliente não identificado."
            });
        }

        const clienteId =
            String(req.usuario.id).trim();

        // ==================================================
        // DADOS RECEBIDOS
        // ==================================================

        const body =
            req.body || {};

        console.log(
            "CLIENTE AUTENTICADO:",
            clienteId
        );

        console.log(
            "RESTAURANTE:",
            body.restauranteId
        );

        console.log(
            "PAGAMENTO:",
            body.pagamento
        );

        console.log(
            "TOTAL:",
            body.total
        );

        // ==================================================
        // RESTAURANTE
        // ==================================================

        if (
            !body.restauranteId ||
            String(body.restauranteId).trim() === ""
        ) {

            return res.status(400).json({
                sucesso: false,
                erro: "Restaurante não identificado."
            });
        }

        // ==================================================
        // ITENS
        // ==================================================

        if (
            !Array.isArray(body.itens) ||
            body.itens.length === 0
        ) {

            return res.status(400).json({
                sucesso: false,
                erro: "O pedido precisa possuir pelo menos um item."
            });
        }

        // ==================================================
        // CRIAR PEDIDO
        // ==================================================

        const pedido = await Order.criar({

            // IMPORTANTE:
            // vem do JWT
            clienteId,

            restauranteId:
                String(body.restauranteId),

            itens:
                body.itens,

            endereco:
                body.endereco || {},

            pagamento:
                body.pagamento || "PIX",

            subtotal:
                Number(body.subtotal) || 0,

            taxaServico:
                Number(body.taxaServico) || 0,

            taxaEntrega:
                Number(body.taxaEntrega) || 0,

            total:
                Number(body.total) || 0,

            precisaTroco:
                Boolean(body.precisaTroco),

            trocoPara:
                body.trocoPara !== null &&
                body.trocoPara !== undefined
                    ? Number(body.trocoPara)
                    : null,

            valorTroco:
                Number(body.valorTroco) || 0,

            externalReference:
                body.externalReference ||
                `FOODJET-${Date.now()}`
        });

        // ==================================================
        // SUCESSO
        // ==================================================

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
            pedidoId: pedido.id
        });

    } catch (error) {

        console.error(
            "❌ ERRO CONTROLLER CRIAR PEDIDO:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao criar pedido",
            detalhes: error.message
        });
    }
}


// ======================================================
// LISTAR TODOS OS PEDIDOS
// ======================================================

async function list(req, res) {

    try {

        const pedidos =
            await Order.listar();

        return res.json({
            sucesso: true,
            pedidos
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO LISTAR PEDIDOS:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao listar pedidos",
            detalhes: error.message
        });
    }
}


// ======================================================
// BUSCAR PEDIDO
// ======================================================

async function getById(req, res) {

    try {

        const pedido =
            await Order.buscarPorId(
                req.params.id
            );

        if (!pedido) {

            return res.status(404).json({
                sucesso: false,
                erro: "Pedido não encontrado."
            });
        }

        return res.json({
            sucesso: true,
            pedido
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO BUSCAR PEDIDO:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedido",
            detalhes: error.message
        });
    }
}


// ======================================================
// ATUALIZAR STATUS
// ======================================================

async function updateStatus(req, res) {

    try {

        const {
            status
        } = req.body || {};

        if (!status) {

            return res.status(400).json({
                sucesso: false,
                erro: "Status não informado."
            });
        }

        const pedido =
            await Order.atualizarStatus(
                req.params.id,
                status
            );

        if (!pedido) {

            return res.status(404).json({
                sucesso: false,
                erro: "Pedido não encontrado."
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Status atualizado com sucesso.",
            pedido
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO ATUALIZAR STATUS:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao atualizar status",
            detalhes: error.message
        });
    }
}


// ======================================================
// PEDIDOS DO RESTAURANTE
// ======================================================

async function restaurantOrders(req, res) {

    try {

        const pedidos =
            await Order.listarPorRestaurante(
                req.params.id
            );

        return res.json({
            sucesso: true,
            pedidos
        });

    } catch (error) {

        console.error(
            "❌ ERRO PEDIDOS RESTAURANTE:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedidos do restaurante",
            detalhes: error.message
        });
    }
}


// ======================================================
// PEDIDOS DO CLIENTE
// ======================================================

async function clientOrders(req, res) {

    try {

        const pedidos =
            await Order.listarPorCliente(
                req.params.id
            );

        return res.json({
            sucesso: true,
            pedidos
        });

    } catch (error) {

        console.error(
            "❌ ERRO PEDIDOS CLIENTE:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedidos do cliente",
            detalhes: error.message
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
            pedidos
        });

    } catch (error) {

        console.error(
            "❌ ERRO PEDIDOS DISPONÍVEIS:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao buscar pedidos disponíveis",
            detalhes: error.message
        });
    }
}


// ======================================================
// RESTAURANTE ACEITA PEDIDO
// ======================================================

async function acceptRestaurant(req, res) {

    try {

        const pedido =
            await Order.aceitarPedidoRestaurante(
                req.params.id
            );

        if (!pedido) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está aguardando o restaurante."
            });
        }

        console.log(
            "🍽️ RESTAURANTE ACEITOU PEDIDO:",
            pedido.id
        );

        return res.json({
            sucesso: true,
            mensagem: "Pedido aceito pelo restaurante.",
            pedido
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO ACEITAR PEDIDO:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao aceitar pedido",
            detalhes: error.message
        });
    }
}


// ======================================================
// RESTAURANTE RECUSA PEDIDO
// ======================================================

async function rejectRestaurant(req, res) {

    try {

        const motivo =
            req.body?.motivo ||
            "Pedido recusado pelo restaurante";

        const pedido =
            await Order.recusarPedidoRestaurante(
                req.params.id,
                motivo
            );

        if (!pedido) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está aguardando o restaurante."
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Pedido recusado pelo restaurante.",
            pedido
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO RECUSAR PEDIDO:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao recusar pedido",
            detalhes: error.message
        });
    }
}


// ======================================================
// ENTREGADOR ACEITA PEDIDO
// ======================================================

async function acceptDelivery(req, res) {

    try {

        if (
            !req.body ||
            !req.body.entregadorId
        ) {

            return res.status(400).json({
                sucesso: false,
                erro: "Entregador não informado."
            });
        }

        const pedido =
            await Order.aceitarEntrega(
                req.params.id,
                req.body.entregadorId
            );

        if (!pedido) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está disponível para entrega."
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Pedido aceito pelo entregador.",
            pedido
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO ACEITAR ENTREGA:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao aceitar entrega",
            detalhes: error.message
        });
    }
}


// ======================================================
// FINALIZAR ENTREGA
// ======================================================

async function completeDelivery(req, res) {

    try {

        const pedido =
            await Order.finalizarEntrega(
                req.params.id
            );

        if (!pedido) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Pedido não encontrado ou não está em entrega."
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Entrega finalizada.",
            pedido
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO FINALIZAR ENTREGA:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao finalizar entrega",
            detalhes: error.message
        });
    }
}


// ======================================================
// ABRIR SUPORTE
// ======================================================

async function openSupport(req, res) {

    try {

        const usuario =
            req.usuario || {};

        const autorId =
            usuario.id ||
            req.body?.autorId;

        const autorTipo =
            usuario.tipo ||
            req.body?.autorTipo ||
            "CLIENTE";

        const mensagem =
            req.body?.mensagem ||
            "";

        const motivo =
            req.body?.motivo ||
            "Problema com pedido";

        if (!autorId) {

            return res.status(401).json({
                sucesso: false,
                erro: "Usuário não identificado."
            });
        }

        if (!mensagem.trim()) {

            return res.status(400).json({
                sucesso: false,
                erro: "Mensagem de suporte não informada."
            });
        }

        const pedido =
            await Order.abrirSuporte(
                req.params.id,
                autorId,
                autorTipo,
                mensagem,
                motivo
            );

        if (!pedido) {

            return res.status(404).json({
                sucesso: false,
                erro: "Pedido não encontrado."
            });
        }

        return res.json({
            sucesso: true,
            mensagem: "Suporte aberto com sucesso.",
            pedido
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO ABRIR SUPORTE:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro: "Erro ao abrir suporte",
            detalhes: error.message
        });
    }
}


// ======================================================
// EXPORTAR
// ======================================================

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

    openSupport
};

