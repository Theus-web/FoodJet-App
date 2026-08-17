const Restaurant = require("../models/restaurant");

// ==================================================
// CRIAR RESTAURANTE
// ==================================================

exports.create = async (req, res) => {
    try {

        const restaurante = {
            id: Date.now(),

            nome: req.body.nome || "",
            categoria: req.body.categoria || "",
            descricao: req.body.descricao || "",
            telefone: req.body.telefone || "",
            endereco: req.body.endereco || "",

            taxaEntrega:
                Number(req.body.taxaEntrega) || 0,

            tempoEntrega:
                req.body.tempoEntrega || "",

            status: "ABERTO",

            online: true,

            aberto: true,

            aceitarAutomatico:
                req.body.aceitarAutomatico !== false,

            criadoEm:
                new Date().toISOString()
        };

        await Restaurant.criar(restaurante);

        return res.status(201).json({
            sucesso: true,
            mensagem:
                "Restaurante cadastrado com sucesso",
            restaurante
        });

    } catch (erro) {

        console.error(
            "ERRO AO CRIAR RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao cadastrar restaurante",
            detalhe:
                erro.message
        });
    }
};


// ==================================================
// LISTAR
// ==================================================

exports.list = async (req, res) => {
    try {

        const lista =
            await Restaurant.listar();

        return res.json(lista);

    } catch (erro) {

        console.error(
            "ERRO AO LISTAR RESTAURANTES:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao listar restaurantes",
            detalhe:
                erro.message
        });
    }
};


// ==================================================
// BUSCAR POR ID
// ==================================================

exports.getById = async (req, res) => {
    try {

        const { id } = req.params;

        if (
            !id ||
            String(id).trim() === ""
        ) {
            return res.status(400).json({
                erro:
                    "ID do restaurante é obrigatório"
            });
        }

        const restaurante =
            await Restaurant.buscarPorId(id);

        if (!restaurante) {
            return res.status(404).json({
                erro:
                    "Restaurante não encontrado"
            });
        }

        return res.json(restaurante);

    } catch (erro) {

        console.error(
            "ERRO AO BUSCAR RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            erro:
                "Erro ao buscar restaurante",
            detalhe:
                erro.message
        });
    }
};


// ==================================================
// ATUALIZAR CONFIGURAÇÕES
// PUT /api/restaurants/:id
// ==================================================

exports.update = async (req, res) => {
    try {

        const { id } = req.params;

        if (
            !id ||
            String(id).trim() === ""
        ) {
            return res.status(400).json({
                erro:
                    "ID do restaurante é obrigatório"
            });
        }

        console.log(
            "================================"
        );

        console.log(
            "⚙️ ATUALIZANDO RESTAURANTE"
        );

        console.log(
            "ID:",
            id
        );

        console.log(
            "DADOS:",
            req.body
        );

        console.log(
            "================================"
        );

        const restaurante =
            await Restaurant.atualizar(
                id,
                req.body
            );

        if (!restaurante) {
            return res.status(404).json({
                erro:
                    "Restaurante não encontrado"
            });
        }

        // ==================================================
        // AVISAR CLIENTES
        // ==================================================

        if (global.io) {

            global.io.emit(
                "restaurante_atualizado",
                restaurante
            );

            console.log(
                "📡 ATUALIZAÇÃO ENVIADA AOS CLIENTES:",
                restaurante.id
            );
        }

        return res.json({
            sucesso: true,
            mensagem:
                "Restaurante atualizado com sucesso",
            restaurante
        });

    } catch (erro) {

        console.error(
            "ERRO AO ATUALIZAR RESTAURANTE:",
            erro
        );

        return res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao atualizar restaurante",
            detalhe:
                erro.message
        });
    }
};


// ==================================================
// EXCLUIR CONTA COMPLETAMENTE
// DELETE /api/restaurants/:id
// ==================================================

exports.delete = async (req, res) => {

    try {

        const { id } = req.params;

        console.log(
            "================================"
        );

        console.log(
            "🗑️ EXCLUSÃO COMPLETA DE CONTA"
        );

        console.log(
            "RESTAURANTE ID:",
            id
        );

        console.log(
            "================================"
        );

        if (
            !id ||
            String(id).trim() === ""
        ) {
            return res.status(400).json({
                erro:
                    "ID do restaurante é obrigatório"
            });
        }

        const restaurante =
            await Restaurant.buscarPorId(id);

        if (!restaurante) {
            return res.status(404).json({
                erro:
                    "Restaurante não encontrado"
            });
        }

        const resultado =
            await Restaurant.excluir(id);

        if (
            !resultado ||
            resultado.sucesso !== true
        ) {
            return res.status(500).json({
                erro:
                    "Não foi possível excluir a conta do restaurante"
            });
        }

        console.log(
            "✅ EXCLUSÃO CONCLUÍDA"
        );

        console.log(
            "Restaurante:",
            resultado.removidos.restaurante
        );

        console.log(
            "Produtos:",
            resultado.removidos.produtos
        );

        console.log(
            "Pedidos:",
            resultado.removidos.pedidos
        );

        console.log(
            "Pagamentos:",
            resultado.removidos.pagamentos
        );

        console.log(
            "Outros:",
            resultado.removidos.outros
        );

        console.log(
            "================================"
        );

        // ==================================================
        // AVISAR CLIENTES
        // ==================================================

        if (global.io) {

            global.io.emit(
                "restaurante_excluido",
                {
                    restauranteId:
                        String(id)
                }
            );
        }

        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Conta e dados vinculados ao restaurante foram excluídos com sucesso",

            restauranteId:
                String(id),

            removidos:
                resultado.removidos
        });

    } catch (erro) {

        console.error(
            "================================"
        );

        console.error(
            "❌ ERRO AO EXCLUIR CONTA"
        );

        console.error(
            erro
        );

        console.error(
            "================================"
        );

        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro interno ao excluir a conta do restaurante",

            detalhe:
                erro.message
        });
    }
};


// ==================================================
// ATUALIZAR STATUS
// PUT /api/restaurants/:id/status
// ==================================================

exports.updateStatus = async (req, res) => {

    try {

        const { id } = req.params;

        const statusRecebido =
            req.body.status
                ?.toString()
                .trim()
                .toUpperCase();

        console.log(
            "================================"
        );

        console.log(
            "🔄 ALTERANDO STATUS RESTAURANTE"
        );

        console.log(
            "RESTAURANTE ID:",
            id
        );

        console.log(
            "NOVO STATUS:",
            statusRecebido
        );

        console.log(
            "================================"
        );

        // ==================================================
        // VALIDAR ID
        // ==================================================

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "ID do restaurante é obrigatório"
            });
        }

        // ==================================================
        // VALIDAR STATUS
        // ==================================================

        const statusPermitidos = [
            "ABERTO",
            "FECHADO"
        ];

        if (
            !statusPermitidos.includes(
                statusRecebido
            )
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "Status inválido. Use ABERTO ou FECHADO."
            });
        }

        // ==================================================
        // BUSCAR RESTAURANTE
        // ==================================================

        const existente =
            await Restaurant.buscarPorId(id);

        if (!existente) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"
            });
        }

        // ==================================================
        // SINCRONIZAR STATUS
        // ==================================================

        const online =
            statusRecebido === "ABERTO";

        const aberto =
            statusRecebido === "ABERTO";

        const dadosAtualizacao = {

            status:
                statusRecebido,

            online:
                online,

            aberto:
                aberto,

            atualizadoEm:
                new Date().toISOString()
        };

        // ==================================================
        // SALVAR
        // ==================================================

        const restaurante =
            await Restaurant.atualizar(
                id,
                dadosAtualizacao
            );

        if (!restaurante) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"
            });
        }

        // ==================================================
        // GARANTIR CAMPOS
        // ==================================================

        restaurante.status =
            statusRecebido;

        restaurante.online =
            online;

        restaurante.aberto =
            aberto;

        // ==================================================
        // WEBSOCKET
        // ==================================================

        if (global.io) {

            const evento = {

                restauranteId:
                    String(restaurante.id),

                id:
                    restaurante.id,

                nome:
                    restaurante.nome,

                status:
                    restaurante.status,

                online:
                    restaurante.online,

                aberto:
                    restaurante.aberto,

                atualizadoEm:
                    restaurante.atualizadoEm
            };

            // ----------------------------------------------
            // TODOS OS CLIENTES
            // ----------------------------------------------

            global.io.emit(
                "restaurante_status_atualizado",
                evento
            );

            // ----------------------------------------------
            // SALA DO RESTAURANTE
            // ----------------------------------------------

            const sala =
                "restaurante_" +
                restaurante.id;

            global.io
                .to(sala)
                .emit(
                    "restaurante_status_atualizado",
                    evento
                );

            console.log(
                "📡 STATUS ENVIADO PELO WEBSOCKET"
            );

            console.log(
                "🏪 SALA:",
                sala
            );

            console.log(
                "🟢 ONLINE:",
                online
            );

            console.log(
                "📌 STATUS:",
                statusRecebido
            );
        }

        // ==================================================
        // LOG
        // ==================================================

        console.log(
            online
                ? "🟢 RESTAURANTE ONLINE"
                : "🔴 RESTAURANTE OFFLINE"
        );

        console.log(
            "STATUS:",
            statusRecebido
        );

        console.log(
            "ONLINE:",
            online
        );

        console.log(
            "ABERTO:",
            aberto
        );

        console.log(
            "================================"
        );

        // ==================================================
        // RESPOSTA
        // ==================================================

        return res.json({

            sucesso: true,

            restauranteOnline:
                online,

            mensagem:
                online
                    ? "Restaurante está online e aceitando pedidos"
                    : "Restaurante está offline e não está aceitando pedidos",

            restaurante
        });

    } catch (erro) {

        console.error(
            "================================"
        );

        console.error(
            "❌ ERRO AO ATUALIZAR STATUS"
        );

        console.error(
            erro
        );

        console.error(
            "================================"
        );

        return res.status(500).json({

            sucesso: false,

            restauranteOnline: false,

            erro:
                "Erro interno ao atualizar status do restaurante",

            detalhe:
                erro.message
        });
    }
};