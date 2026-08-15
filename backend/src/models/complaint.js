const { db } = require("../config/database");

// ======================================================
// GARANTIR ESTRUTURA
// ======================================================

async function garantirEstrutura() {
    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.reclamacoes)) {
        db.data.reclamacoes = [];
    }
}

// ======================================================
// CRIAR RECLAMAÇÃO
// ======================================================

async function criar(reclamacao) {
    await garantirEstrutura();

    db.data.reclamacoes.push(reclamacao);

    await db.write();

    return reclamacao;
}

// ======================================================
// LISTAR TODAS
// ======================================================

async function listar() {
    await garantirEstrutura();

    return db.data.reclamacoes;
}

// ======================================================
// BUSCAR POR ID
// ======================================================

async function buscarPorId(id) {
    await garantirEstrutura();

    return (
        db.data.reclamacoes.find(
            item => Number(item.id) === Number(id)
        ) || null
    );
}

// ======================================================
// BUSCAR RECLAMAÇÕES DO PEDIDO
// ======================================================

async function listarPorPedido(pedidoId) {
    await garantirEstrutura();

    return db.data.reclamacoes.filter(
        item =>
            Number(item.pedidoId) === Number(pedidoId)
    );
}

// ======================================================
// BUSCAR RECLAMAÇÕES DO CLIENTE
// ======================================================

async function listarPorCliente(clienteId) {
    await garantirEstrutura();

    return db.data.reclamacoes.filter(
        item =>
            String(item.clienteId) ===
            String(clienteId)
    );
}

// ======================================================
// BUSCAR RECLAMAÇÕES DO RESTAURANTE
// ======================================================

async function listarPorRestaurante(restauranteId) {
    await garantirEstrutura();

    return db.data.reclamacoes.filter(
        item =>
            String(item.restauranteId) ===
            String(restauranteId)
    );
}

// ======================================================
// ATUALIZAR STATUS
// ======================================================

async function atualizarStatus(id, status, resposta) {
    await garantirEstrutura();

    const index =
        db.data.reclamacoes.findIndex(
            item =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    db.data.reclamacoes[index].status = status;

    if (resposta) {
        db.data.reclamacoes[index].resposta =
            resposta;
    }

    db.data.reclamacoes[index].atualizadoEm =
        new Date().toISOString();

    await db.write();

    return db.data.reclamacoes[index];
}

// ======================================================
// EXPORTAR
// ======================================================

module.exports = {
    criar,
    listar,
    buscarPorId,
    listarPorPedido,
    listarPorCliente,
    listarPorRestaurante,
    atualizarStatus
};