const Support = require("../models/support");
const Order = require("../models/order");

// ======================================================
// CRIAR CHAMADO
// POST /api/support
// ======================================================

exports.create = async (req, res) => {
    try {

        const {
            pedidoId,
            clienteId,
            restauranteId,
            assunto,
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

        if (!restauranteId) {
            return res.status(400).json({
                erro: "restauranteId é obrigatório"
            });
        }

        if (!assunto || !assunto.trim()) {
            return res.status(400).json({
                erro: "Assunto é obrigatório"
            });
        }

        if (!descricao || !descricao.trim()) {
            return res.status(400).json({
                erro: "Descrição é obrigatória"
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
        // GARANTIR RELAÇÃO
        // ==================================================

        if (
            String(pedido.clienteId) !==
            String(clienteId)
        ) {
            return res.status(403).json({
                erro: "Pedido não pertence ao cliente informado"
            });
        }

        if (
            String(pedido.restauranteId) !==
            String(restauranteId)
        ) {
            return res.status(403).json({
                erro: "Pedido não pertence ao restaurante informado"
            });
        }

        // ==================================================
        // CRIAR CHAMADO
        // ==================================================

        const chamado = {

            id: Date.now(),

            pedidoId,

            clienteId,

            restauranteId,

            assunto: assunto.trim(),

            descricao: descricao.trim(),

            status: "ABERTO",

            prioridade: "NORMAL",

            mensagens: [],

            criadoEm:
                new Date().toISOString(),

            atualizadoEm:
                new Date().toISOString()
        };

        await Support.criar(chamado);

        // ==================================================
        // SOCKET RESTAURANTE
        // ==================================================

        if (global.io) {

            const salaRestaurante =
                "restaurante_" +
                restauranteId;

            global.io
                .to(salaRestaurante)
                .emit(
                    "novo_suporte",
                    chamado
                );

            console.log(
                "🆘 SUPORTE ENVIADO PARA:",
                salaRestaurante
            );
        }

        console.log(
            "🆘 NOVO CHAMADO:",
            chamado.id
        );

        return res.status(201).json({
            mensagem:
                "Chamado criado com sucesso",
            chamado
        });

    } catch (erro) {

        console.error(
            "❌ ERRO AO CRIAR SUPORTE:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao criar chamado",
            detalhes: erro.message
        });
    }
};

// ======================================================
// LISTAR SUPORTES
// GET /api/support
// ======================================================

exports.list = async (req, res) => {
    try {

        const chamados =
            await Support.listar();

        return res.status(200).json(
            chamados
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO LISTAR SUPORTES:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao listar chamados"
        });
    }
};

// ======================================================
// BUSCAR CHAMADO
// GET /api/support/:id
// ======================================================

exports.getById = async (req, res) => {
    try {

        const id =
            Number(req.params.id);

        if (!id) {
            return res.status(400).json({
                erro: "ID inválido"
            });
        }

        const chamado =
            await Support.buscarPorId(id);

        if (!chamado) {
            return res.status(404).json({
                erro: "Chamado não encontrado"
            });
        }

        return res.status(200).json(
            chamado
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR SUPORTE:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao buscar chamado"
        });
    }
};

// ======================================================
// SUPORTES DO PEDIDO
// GET /api/support/pedido/:id
// ======================================================

exports.byPedido = async (req, res) => {
    try {

        const chamados =
            await Support.buscarPorPedido(
                req.params.id
            );

        return res.status(200).json(
            chamados
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR SUPORTE DO PEDIDO:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao buscar suporte"
        });
    }
};

// ======================================================
// SUPORTES DO CLIENTE
// GET /api/support/cliente/:id
// ======================================================

exports.byCliente = async (req, res) => {
    try {

        const chamados =
            await Support.listarPorCliente(
                req.params.id
            );

        return res.status(200).json(
            chamados
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR SUPORTES DO CLIENTE:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao buscar chamados"
        });
    }
};

// ======================================================
// SUPORTES DO RESTAURANTE
// GET /api/support/restaurante/:id
// ======================================================

exports.byRestaurante = async (req, res) => {
    try {

        const chamados =
            await Support.listarPorRestaurante(
                req.params.id
            );

        return res.status(200).json(
            chamados
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR SUPORTES DO RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao buscar chamados"
        });
    }
};

// ======================================================
// ATUALIZAR CHAMADO
// PUT /api/support/:id
// ======================================================

exports.update = async (req, res) => {
    try {

        const id =
            Number(req.params.id);

        const chamado =
            await Support.buscarPorId(id);

        if (!chamado) {
            return res.status(404).json({
                erro: "Chamado não encontrado"
            });
        }

        const dados = {};

        if (req.body.status) {
            dados.status =
                req.body.status;
        }

        if (req.body.prioridade) {
            dados.prioridade =
                req.body.prioridade;
        }

        const atualizado =
            await Support.atualizar(
                id,
                dados
            );

        // ==================================================
        // AVISAR CLIENTE E RESTAURANTE
        // ==================================================

        if (global.io) {

            global.io.emit(
                "suporte_atualizado",
                atualizado
            );
        }

        return res.status(200).json({
            mensagem:
                "Chamado atualizado com sucesso",
            chamado: atualizado
        });

    } catch (erro) {

        console.error(
            "❌ ERRO AO ATUALIZAR SUPORTE:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao atualizar chamado"
        });
    }
};

// ======================================================
// RESPONDER CHAMADO
// POST /api/support/:id/mensagem
// ======================================================

exports.addMessage = async (req, res) => {
    try {

        const id =
            Number(req.params.id);

        const {
            remetenteId,
            remetenteTipo,
            mensagem
        } = req.body;

        if (!remetenteId) {
            return res.status(400).json({
                erro: "remetenteId é obrigatório"
            });
        }

        if (!remetenteTipo) {
            return res.status(400).json({
                erro: "remetenteTipo é obrigatório"
            });
        }

        if (!mensagem || !mensagem.trim()) {
            return res.status(400).json({
                erro: "Mensagem é obrigatória"
            });
        }

        const chamado =
            await Support.buscarPorId(id);

        if (!chamado) {
            return res.status(404).json({
                erro: "Chamado não encontrado"
            });
        }

        const novaMensagem = {

            id: Date.now(),

            remetenteId,

            remetenteTipo,

            mensagem:
                mensagem.trim(),

            criadoEm:
                new Date().toISOString()
        };

        const atualizado =
            await Support.adicionarMensagem(
                id,
                novaMensagem
            );

        if (global.io) {

            global.io.emit(
                "nova_mensagem_suporte",
                atualizado
            );
        }

        return res.status(200).json({
            mensagem:
                "Mensagem enviada com sucesso",
            chamado: atualizado
        });

    } catch (erro) {

        console.error(
            "❌ ERRO AO ENVIAR MENSAGEM:",
            erro
        );

        return res.status(500).json({
            erro: "Erro ao enviar mensagem",
            detalhes: erro.message
        });
    }
};