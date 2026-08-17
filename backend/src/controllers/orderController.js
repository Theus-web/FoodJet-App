const Order = require("../models/order");
const Restaurant = require("../models/restaurant");

// ======================================================
// CRIAR PEDIDO
// POST /api/orders
// ======================================================

exports.create = async (req, res) => {
    try {

        // ==================================================
        // DADOS RECEBIDOS
        // ==================================================

        const restauranteId =
            req.body.restauranteId;

        const clienteId =
            req.body.clienteId;

        const itens =
            req.body.itens || [];

        // ==================================================
        // VALIDAR RESTAURANTE ID
        // ==================================================

        if (
            restauranteId === undefined ||
            restauranteId === null ||
            String(restauranteId).trim() === ""
        ) {
            return res.status(400).json({
                sucesso: false,
                restauranteOffline: false,
                erro:
                    "restauranteId é obrigatório"
            });
        }

        // ==================================================
        // BUSCAR RESTAURANTE
        // ==================================================

        const restaurante =
            await Restaurant.buscarPorId(
                restauranteId
            );

        if (!restaurante) {

            console.log(
                "❌ RESTAURANTE NÃO ENCONTRADO:",
                restauranteId
            );

            return res.status(404).json({
                sucesso: false,
                restauranteOffline: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        // ==================================================
        // NORMALIZAR STATUS
        // ==================================================

        const status =
            String(
                restaurante.status || ""
            )
                .trim()
                .toUpperCase();

        // ==================================================
        // NORMALIZAR ONLINE
        // ==================================================

        const online =
            restaurante.online === true ||
            String(
                restaurante.online
            ).toLowerCase() === "true";

        // ==================================================
        // NORMALIZAR ABERTO
        // ==================================================

        const aberto =
            restaurante.aberto === true ||
            String(
                restaurante.aberto
            ).toLowerCase() === "true";

        // ==================================================
        // LOG
        // ==================================================

        console.log(
            "================================"
        );

        console.log(
            "🔎 VERIFICAÇÃO DO RESTAURANTE"
        );

        console.log(
            "🏪 ID:",
            restauranteId
        );

        console.log(
            "🏪 NOME:",
            restaurante.nome
        );

        console.log(
            "📌 STATUS:",
            status
        );

        console.log(
            "🟢 ONLINE:",
            online
        );

        console.log(
            "🚪 ABERTO:",
            aberto
        );

        console.log(
            "================================"
        );

        // ==================================================
        // VERIFICAR SE PODE RECEBER PEDIDOS
        //
        // TODAS precisam estar corretas:
        //
        // status = ABERTO
        // online = true
        // aberto = true
        //
        // Se UMA estiver errada, bloqueia.
        // ==================================================

        const restauranteDisponivel =
            status === "ABERTO" &&
            online === true &&
            aberto === true;

        if (!restauranteDisponivel) {

            console.log(
                "🔴 PEDIDO BLOQUEADO"
            );

            console.log(
                "🏪 RESTAURANTE:",
                restauranteId
            );

            console.log(
                "📌 STATUS:",
                status
            );

            console.log(
                "🟢 ONLINE:",
                online
            );

            console.log(
                "🚪 ABERTO:",
                aberto
            );

            return res.status(409).json({

                sucesso: false,

                restauranteOffline: true,

                erro:
                    "O restaurante está offline e não está aceitando pedidos.",

                mensagem:
                    "Este restaurante está fechado no momento. Tente novamente mais tarde.",

                restaurante: {

                    id:
                        restaurante.id,

                    nome:
                        restaurante.nome,

                    status:
                        status || "FECHADO",

                    online:
                        online,

                    aberto:
                        aberto
                }
            });
        }

        // ==================================================
        // VALIDAR ITENS
        // ==================================================

        if (
            !Array.isArray(itens) ||
            itens.length === 0
        ) {

            return res.status(400).json({

                sucesso: false,

                restauranteOffline: false,

                erro:
                    "O pedido precisa ter pelo menos um produto."
            });
        }

        // ==================================================
        // CRIAR PEDIDO
        // ==================================================

        const pedido = {

            id:
                Date.now(),

            clienteId:
                clienteId,

            restauranteId:
                restauranteId,

            itens:
                itens,

            endereco:
                req.body.endereco || {},

            pagamento:
                req.body.pagamento || "PIX",

            subtotal:
                Number(
                    req.body.subtotal
                ) || 0,

            taxaEntrega:
                Number(
                    req.body.taxaEntrega
                ) || 0,

            total:
                Number(
                    req.body.total
                ) || 0,

            status:
                "AGUARDANDO_RESTAURANTE",

            criadoEm:
                new Date().toISOString()
        };

        // ==================================================
        // SALVAR PEDIDO
        // ==================================================

        await Order.criar(
            pedido
        );

        // ==================================================
        // WEBSOCKET
        // ==================================================

        if (global.io) {

            const salaRestaurante =
                "restaurante_" +
                pedido.restauranteId;

            global.io
                .to(salaRestaurante)
                .emit(
                    "novo_pedido",
                    pedido
                );

            console.log(
                "🔔 NOVO PEDIDO ENVIADO PARA:",
                salaRestaurante
            );
        }

        // ==================================================
        // LOG
        // ==================================================

        console.log(
            "================================"
        );

        console.log(
            "📦 NOVO PEDIDO CRIADO"
        );

        console.log(
            "🆔 ID:",
            pedido.id
        );

        console.log(
            "🏪 RESTAURANTE:",
            pedido.restauranteId
        );

        console.log(
            "👤 CLIENTE:",
            pedido.clienteId
        );

        console.log(
            "💰 TOTAL:",
            pedido.total
        );

        console.log(
            "📌 STATUS:",
            pedido.status
        );

        console.log(
            "================================"
        );

        // ==================================================
        // RESPOSTA
        // ==================================================

        return res.status(201).json({

            sucesso: true,

            restauranteOffline: false,

            mensagem:
                "Pedido criado com sucesso",

            pedido

        });

    } catch (erro) {

        console.error(
            "================================"
        );

        console.error(
            "❌ ERRO AO CRIAR PEDIDO:"
        );

        console.error(
            erro
        );

        console.error(
            "================================"
        );

        return res.status(500).json({

            sucesso: false,

            restauranteOffline: false,

            erro:
                "Erro ao criar pedido",

            detalhes:
                erro.message

        });
    }
};


// ======================================================
// LISTAR TODOS OS PEDIDOS
// GET /api/orders
// ======================================================

exports.list = async (req, res) => {
    try {

        const pedidos =
            await Order.listar();

        return res.status(200).json(
            pedidos
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO LISTAR PEDIDOS:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao listar pedidos",

            detalhes:
                erro.message
        });
    }
};


// ======================================================
// BUSCAR PEDIDO PELO ID
// GET /api/orders/:id
// ======================================================

exports.getById = async (req, res) => {
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

        console.log(
            "🔎 PEDIDO CONSULTADO:",
            id
        );

        return res.status(200).json(
            pedido
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR PEDIDO:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro interno ao buscar pedido",

            detalhes:
                erro.message
        });
    }
};


// ======================================================
// ATUALIZAR STATUS DO PEDIDO
// PUT /api/orders/:id/status
// ======================================================

exports.updateStatus = async (req, res) => {
    try {

        const id =
            Number(req.params.id);

        const novoStatus =
            req.body.status;

        if (!id) {
            return res.status(400).json({
                erro:
                    "ID do pedido inválido"
            });
        }

        if (!novoStatus) {
            return res.status(400).json({
                erro:
                    "Status não informado"
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

        pedido.status =
            novoStatus;

        pedido.atualizadoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                (item) =>
                    Number(item.id) === id
            );

        if (index !== -1) {
            pedidos[index] =
                pedido;
        }

        const { db } =
            require("../config/database");

        await db.write();

        // ==================================================
        // AVISAR CLIENTE
        // ==================================================

        if (global.io) {

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

            console.log(
                "📡 STATUS ENVIADO AO CLIENTE:",
                pedido.id,
                pedido.status
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
            erro:
                "Erro ao atualizar status",

            detalhes:
                erro.message
        });
    }
};


// ======================================================
// BUSCAR PEDIDOS DO RESTAURANTE
// GET /api/orders/restaurante/:id
// ======================================================

exports.restaurantOrders = async (req, res) => {
    try {

        const restauranteId =
            Number(req.params.id);

        const pedidos =
            await Order.listar();

        const resultado =
            pedidos.filter(
                (pedido) =>
                    Number(
                        pedido.restauranteId
                    ) === restauranteId
            );

        return res.status(200).json(
            resultado
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR PEDIDOS DO RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao buscar pedidos do restaurante",

            detalhes:
                erro.message
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
            await Order.listar();

        const disponiveis =
            pedidos.filter(
                (pedido) =>
                    pedido.status ===
                    "PRONTO"
            );

        return res.status(200).json(
            disponiveis
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR PEDIDOS DISPONÍVEIS:",
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
// ENTREGADOR ACEITA O PEDIDO
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
                erro:
                    "ID do pedido inválido"
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

        pedido.entregadorId =
            entregadorId;

        pedido.status =
            "EM_ENTREGA";

        pedido.aceitoEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                (item) =>
                    Number(item.id) === id
            );

        if (index !== -1) {
            pedidos[index] =
                pedido;
        }

        const { db } =
            require("../config/database");

        await db.write();

        // ==================================================
        // AVISAR CLIENTE
        // ==================================================

        if (global.io) {

            global.io.emit(
                "status_pedido_atualizado",
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

        const pedido =
            await Order.buscarPorId(id);

        if (!pedido) {
            return res.status(404).json({
                erro:
                    "Pedido não encontrado"
            });
        }

        pedido.status =
            "ENTREGUE";

        pedido.entregueEm =
            new Date().toISOString();

        const pedidos =
            await Order.listar();

        const index =
            pedidos.findIndex(
                (item) =>
                    Number(item.id) === id
            );

        if (index !== -1) {
            pedidos[index] =
                pedido;
        }

        const { db } =
            require("../config/database");

        await db.write();

        // ==================================================
        // AVISAR CLIENTE
        // ==================================================

        if (global.io) {

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );
        }

        console.log(
            "✅ PEDIDO ENTREGUE:",
            id
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