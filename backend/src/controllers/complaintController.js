const Complaint = require("../models/complaint");
const Order = require("../models/order");

// ======================================================
// CRIAR RECLAMAÇÃO
// POST /api/complaints
// ======================================================

exports.create = async (req, res) => {
    try {
        const {
            pedidoId,
            clienteId,
            restauranteId,
            tipo,
            descricao
        } = req.body;

        if (!pedidoId) {
            return res.status(400).json({
                erro: "pedidoId é obrigatório"
            });
        }

        if (!clienteId) {
            return res.status(400).json({
                erro: "clienteId é obrigatório"
            });
        }

        if (!tipo) {
            return res.status(400).json({
                erro: "Tipo da reclamação é obrigatório"
            });
        }

        if (!descricao ||
            descricao.trim().length < 5) {
            return res.status(400).json({
                erro:
                    "Descreva o problema com pelo menos 5 caracteres"
            });
        }

        // ==================================================
        // VERIFICAR PEDIDO
        // ==================================================

        const pedido =
            await Order.buscarPorId(pedidoId);

        if (!pedido) {
            return res.status(404).json({
                erro: "Pedido não encontrado"
            });
        }

        // ==================================================
        // GARANTIR DADOS DO PEDIDO
        // ==================================================

        const reclamacao = {
            id: Date.now(),

            pedidoId: pedido.id,

            clienteId:
                clienteId || pedido.clienteId,

            restauranteId:
                restauranteId ||
                pedido.restauranteId,

            entregadorId:
                pedido.entregadorId || null,

            tipo,

            descricao: descricao.trim(),

            status: "ABERTA",

            criadoEm:
                new Date().toISOString(),

            atualizadoEm:
                new Date().toISOString()
        };

        await Complaint.criar(
            reclamacao
        );

        // ==================================================
        // AVISAR RESTAURANTE
        // ==================================================

        if (global.io) {

            const salaRestaurante =
                "restaurante_" +
                reclamacao.restauranteId;

            global.io
                .to(salaRestaurante)
                .emit(
                    "nova_reclamacao",
                    reclamacao
                );

            console.log(
                "⚠️ NOVA RECLAMAÇÃO ENVIADA PARA:",
                salaRestaurante
            );

            // ==================================================
            // AVISAR CLIENTE
            // ==================================================

            const salaCliente =
                "cliente_" +
                reclamacao.clienteId;

            global.io
                .to(salaCliente)
                .emit(
                    "reclamacao_criada",
                    reclamacao
                );
        }

        console.log(
            "⚠️ RECLAMAÇÃO CRIADA:",
            reclamacao.id
        );

        return res.status(201).json({
            mensagem:
                "Reclamação registrada com sucesso",
            reclamacao
        });

    } catch (erro) {

        console.error(
            "❌ ERRO AO CRIAR RECLAMAÇÃO:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao criar reclamação",
            detalhes:
                erro.message
        });
    }
};

// ======================================================
// LISTAR RECLAMAÇÕES
// GET /api/complaints
// ======================================================

exports.list = async (req, res) => {
    try {

        const reclamacoes =
            await Complaint.listar();

        return res.status(200).json(
            reclamacoes
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO LISTAR RECLAMAÇÕES:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao listar reclamações"
        });
    }
};

// ======================================================
// RECLAMAÇÕES DO PEDIDO
// GET /api/complaints/pedido/:id
// ======================================================

exports.byOrder = async (req, res) => {
    try {

        const pedidoId =
            req.params.id;

        const reclamacoes =
            await Complaint.listarPorPedido(
                pedidoId
            );

        return res.status(200).json(
            reclamacoes
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR RECLAMAÇÕES:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao buscar reclamações"
        });
    }
};

// ======================================================
// RECLAMAÇÕES DO RESTAURANTE
// GET /api/complaints/restaurante/:id
// ======================================================

exports.byRestaurant = async (req, res) => {
    try {

        const restauranteId =
            req.params.id;

        const reclamacoes =
            await Complaint.listarPorRestaurante(
                restauranteId
            );

        return res.status(200).json(
            reclamacoes
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR RECLAMAÇÕES DO RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao buscar reclamações"
        });
    }
};

// ======================================================
// ATUALIZAR RECLAMAÇÃO
// PUT /api/complaints/:id
// ======================================================

exports.updateStatus = async (req, res) => {
    try {

        const id =
            Number(req.params.id);

        const {
            status,
            resposta
        } = req.body;

        if (!id) {
            return res.status(400).json({
                erro:
                    "ID da reclamação inválido"
            });
        }

        if (!status) {
            return res.status(400).json({
                erro:
                    "Status não informado"
            });
        }

        const reclamacao =
            await Complaint.atualizarStatus(
                id,
                status,
                resposta
            );

        if (!reclamacao) {
            return res.status(404).json({
                erro:
                    "Reclamação não encontrada"
            });
        }

        // ==================================================
        // AVISAR CLIENTE
        // ==================================================

        if (global.io) {

            const salaCliente =
                "cliente_" +
                reclamacao.clienteId;

            global.io
                .to(salaCliente)
                .emit(
                    "atualizacao_reclamacao",
                    reclamacao
                );
        }

        return res.status(200).json({
            mensagem:
                "Reclamação atualizada com sucesso",
            reclamacao
        });

    } catch (erro) {

        console.error(
            "❌ ERRO AO ATUALIZAR RECLAMAÇÃO:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao atualizar reclamação",
            detalhes:
                erro.message
        });
    }
};