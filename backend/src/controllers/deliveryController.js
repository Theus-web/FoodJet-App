const Delivery = require("../models/delivery");
const Order = require("../models/order");
const { pool } = require("../config/database");

// ============================================================
// CADASTRAR ENTREGADOR
// ============================================================

exports.create = async (req, res) => {
    try {
        const {
            nome,
            telefone,
            email,
            veiculo,
            placa,
        } = req.body;

        if (!nome || !telefone) {
            return res.status(400).json({
                sucesso: false,
                mensagem: "Nome e telefone são obrigatórios.",
            });
        }

        const entregador = {
            id: Date.now().toString(),
            nome,
            telefone,
            email,
            veiculo,
            placa,
            online: false,
            status: "OFFLINE",
            criadoEm: new Date().toISOString(),
        };

        await Delivery.criar(entregador);

        res.status(201).json({
            sucesso: true,
            mensagem: "Entregador cadastrado com sucesso.",
            entregador,
        });
    } catch (e) {
        console.error("ERRO CREATE DELIVERY:", e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao cadastrar entregador.",
        });
    }
};

// ============================================================
// LISTAR ENTREGADORES
// ============================================================

exports.list = async (req, res) => {
    try {
        const entregadores = await Delivery.listar();

        res.json({
            sucesso: true,
            total: entregadores.length,
            entregadores,
        });
    } catch (e) {
        console.error("ERRO LIST DELIVERY:", e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao listar entregadores.",
        });
    }
};

// ============================================================
// ALTERAR STATUS ONLINE/OFFLINE
// ============================================================

exports.status = async (req, res) => {
    try {
        const id = req.params.id;
        const online = req.body.online === true;

        const entregador = await Delivery.buscarPorId(id);

        if (!entregador) {
            return res.status(404).json({
                sucesso: false,
                mensagem: "Entregador não encontrado.",
            });
        }

        const status = online ? "DISPONIVEL" : "OFFLINE";

        await pool.query(
            `
            UPDATE entregadores
            SET
                online = $1,
                status = $2,
                atualizado_em = NOW()
            WHERE id = $3
            `,
            [online, status, id]
        );

        const atualizado = await Delivery.buscarPorId(id);

        res.json({
            sucesso: true,
            mensagem: online
                ? "Entregador ficou ONLINE."
                : "Entregador ficou OFFLINE.",
            entregador: atualizado,
        });
    } catch (e) {
        console.error("ERRO STATUS DELIVERY:", e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao atualizar status.",
        });
    }
};

// ============================================================
// PEDIDO ATUAL DO ENTREGADOR
// ============================================================

exports.myOrders = async (req, res) => {
    try {
        const id = req.params.id;

        const resultado = await pool.query(
            `
            SELECT *
            FROM pedidos
            WHERE entregador_id = $1
            ORDER BY criado_em DESC
            `,
            [id]
        );

        res.json({
            sucesso: true,
            total: resultado.rows.length,
            pedidos: resultado.rows,
        });
    } catch (e) {
        console.error("ERRO MY ORDERS:", e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao buscar pedidos.",
        });
    }
};

// ============================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ============================================================

exports.availableOrders = async (req, res) => {
    try {
        const resultado = await pool.query(`
            SELECT *
            FROM pedidos
            WHERE status = 'PRONTO'
            AND entregador_id IS NULL
            ORDER BY criado_em ASC
        `);

        res.json({
            sucesso: true,
            total: resultado.rows.length,
            pedidos: resultado.rows,
        });
    } catch (e) {
        console.error("ERRO AVAILABLE ORDERS:", e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao buscar entregas disponíveis.",
        });
    }
};

// ============================================================
// ACEITAR ENTREGA
// ============================================================

exports.acceptOrder = async (req, res) => {
    try {
        const entregadorId = req.params.id;
        const pedidoId = req.params.orderId;

        const pedido = await pool.query(
            `
            SELECT *
            FROM pedidos
            WHERE id = $1
            LIMIT 1
            `,
            [pedidoId]
        );

        if (pedido.rowCount === 0) {
            return res.status(404).json({
                sucesso: false,
                mensagem: "Pedido não encontrado.",
            });
        }

        if (pedido.rows[0].entregador_id) {
            return res.status(400).json({
                sucesso: false,
                mensagem: "Pedido já foi aceito por outro entregador.",
            });
        }

        await pool.query(
            `
            UPDATE pedidos
            SET
                entregador_id = $1,
                status = 'ENTREGADOR_A_CAMINHO',
                atualizado_em = NOW()
            WHERE id = $2
            `,
            [entregadorId, pedidoId]
        );

        const atualizado = await pool.query(
            `
            SELECT *
            FROM pedidos
            WHERE id = $1
            `,
            [pedidoId]
        );

        if (global.io) {
            global.io.emit("pedido_atualizado", atualizado.rows[0]);
        }

        res.json({
            sucesso: true,
            mensagem: "Entrega aceita com sucesso.",
            pedido: atualizado.rows[0],
        });
    } catch (e) {
        console.error("ERRO ACCEPT ORDER:", e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao aceitar entrega.",
        });
    }
};

// ============================================================
// ENTREGADOR CHEGOU AO RESTAURANTE
// ============================================================

exports.arrivedRestaurant = async (req, res) => {
    try {
        const pedidoId = req.params.orderId;

        await pool.query(
            `
            UPDATE pedidos
            SET
                status = 'COLETANDO_PEDIDO',
                atualizado_em = NOW()
            WHERE id = $1
            `,
            [pedidoId]
        );

        const pedido = await pool.query(
            `SELECT * FROM pedidos WHERE id=$1`,
            [pedidoId]
        );

        if (global.io) {
            global.io.emit("pedido_atualizado", pedido.rows[0]);
        }

        res.json({
            sucesso: true,
            mensagem: "Entregador chegou ao restaurante.",
            pedido: pedido.rows[0],
        });
    } catch (e) {
        console.error(e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao atualizar pedido.",
        });
    }
};

// ============================================================
// PEDIDO COLETADO / SAIU PARA ENTREGA
// ============================================================

exports.startDelivery = async (req, res) => {
    try {
        const pedidoId = req.params.orderId;

        await pool.query(
            `
            UPDATE pedidos
            SET
                status = 'SAIU_PARA_ENTREGA',
                atualizado_em = NOW()
            WHERE id = $1
            `,
            [pedidoId]
        );

        const pedido = await pool.query(
            `SELECT * FROM pedidos WHERE id=$1`,
            [pedidoId]
        );

        if (global.io) {
            global.io.emit("pedido_atualizado", pedido.rows[0]);
        }

        res.json({
            sucesso: true,
            mensagem: "Pedido saiu para entrega.",
            pedido: pedido.rows[0],
        });
    } catch (e) {
        console.error(e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao iniciar entrega.",
        });
    }
};

// ============================================================
// ENTREGA FINALIZADA
// ============================================================

exports.finishDelivery = async (req, res) => {
    try {
        const pedidoId = req.params.orderId;

        await pool.query(
            `
            UPDATE pedidos
            SET
                status = 'ENTREGUE',
                entregue_em = NOW(),
                atualizado_em = NOW()
            WHERE id = $1
            `,
            [pedidoId]
        );

        const pedido = await pool.query(
            `SELECT * FROM pedidos WHERE id=$1`,
            [pedidoId]
        );

        if (global.io) {
            global.io.emit("pedido_atualizado", pedido.rows[0]);
        }

        res.json({
            sucesso: true,
            mensagem: "Entrega finalizada.",
            pedido: pedido.rows[0],
        });
    } catch (e) {
        console.error(e);

        res.status(500).json({
            sucesso: false,
            mensagem: "Erro ao finalizar entrega.",
        });
    }
};