const { db } = require("../config/database");

// ======================================================
// GARANTIR ESTRUTURA
// ======================================================

async function garantirEstrutura() {
    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.suportes)) {
        db.data.suportes = [];
    }
}

// ======================================================
// CRIAR CHAMADO
// ======================================================

async function criar(chamado) {
    await garantirEstrutura();

    db.data.suportes.push(chamado);

    await db.write();

    return chamado;
}

// ======================================================
// LISTAR TODOS
// ======================================================

async function listar() {
    await garantirEstrutura();

    return db.data.suportes;
}

// ======================================================
// BUSCAR POR ID
// ======================================================

async function buscarPorId(id) {
    await garantirEstrutura();

    const chamado = db.data.suportes.find(
        (item) => Number(item.id) === Number(id)
    );

    return chamado || null;
}

// ======================================================
// BUSCAR PELO PEDIDO
// ======================================================

async function buscarPorPedido(pedidoId) {
    await garantirEstrutura();

    return db.data.suportes.filter(
        (item) =>
            String(item.pedidoId) === String(pedidoId)
    );
}

// ======================================================
// BUSCAR DO CLIENTE
// ======================================================

async function listarPorCliente(clienteId) {
    await garantirEstrutura();

    return db.data.suportes.filter(
        (item) =>
            String(item.clienteId) === String(clienteId)
    );
}

// ======================================================
// BUSCAR DO RESTAURANTE
// ======================================================

async function listarPorRestaurante(restauranteId) {
    await garantirEstrutura();

    return db.data.suportes.filter(
        (item) =>
            String(item.restauranteId) ===
            String(restauranteId)
    );
}

// ======================================================
// ATUALIZAR CHAMADO
// ======================================================

async function atualizar(id, dados) {
    await garantirEstrutura();

    const index = db.data.suportes.findIndex(
        (item) => Number(item.id) === Number(id)
    );

    if (index === -1) {
        return null;
    }

    db.data.suportes[index] = {
        ...db.data.suportes[index],
        ...dados,
        atualizadoEm: new Date().toISOString()
    };

    await db.write();

    return db.data.suportes[index];
}

// ======================================================
// ADICIONAR MENSAGEM
// ======================================================

async function adicionarMensagem(id, mensagem) {
    await garantirEstrutura();

    const index = db.data.suportes.findIndex(
        (item) => Number(item.id) === Number(id)
    );

    if (index === -1) {
        return null;
    }

    if (!Array.isArray(db.data.suportes[index].mensagens)) {
        db.data.suportes[index].mensagens = [];
    }

    db.data.suportes[index].mensagens.push(mensagem);

    db.data.suportes[index].atualizadoEm =
        new Date().toISOString();

    await db.write();

    return db.data.suportes[index];
}

// ======================================================
// EXPORTAR
// ======================================================

module.exports = {
    criar,
    listar,
    buscarPorId,
    buscarPorPedido,
    listarPorCliente,
    listarPorRestaurante,
    atualizar,
    adicionarMensagem
};