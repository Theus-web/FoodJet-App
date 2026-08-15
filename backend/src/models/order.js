const { db } = require("../config/database");

// ======================================================
// GARANTIR ESTRUTURA DO BANCO
// ======================================================

async function prepararBanco() {
    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    await db.write();
}


// ======================================================
// CRIAR PEDIDO
// ======================================================

async function criar(pedido) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    /*
     * IMPORTANTE:
     * A taxa de entrega NÃO é definida pelo restaurante.
     *
     * O sistema poderá calcular a entrega posteriormente.
     */

    const novoPedido = {
        ...pedido,

        // relacionamento
        clienteId: pedido.clienteId,
        restauranteId: pedido.restauranteId,

        // status inicial
        status: "AGUARDANDO_RESTAURANTE",

        // suporte
        suporte: {
            aberto: false,
            status: "FECHADO",
            mensagens: []
        },

        criadoEm:
            pedido.criadoEm ||
            new Date().toISOString()
    };

    /*
     * Remover taxa antiga caso venha do aplicativo
     */
    delete novoPedido.taxaEntrega;

    db.data.pedidos.push(novoPedido);

    await db.write();

    return novoPedido;
}


// ======================================================
// LISTAR TODOS OS PEDIDOS
// ======================================================

async function listar() {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    return db.data.pedidos;
}


// ======================================================
// BUSCAR PEDIDO PELO ID
// ======================================================

async function buscarPorId(id) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const pedido =
        db.data.pedidos.find(
            (item) =>
                Number(item.id) === Number(id)
        );

    return pedido || null;
}


// ======================================================
// ATUALIZAR STATUS DO PEDIDO
// ======================================================

async function atualizarStatus(
    id,
    novoStatus
) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    db.data.pedidos[index].status =
        novoStatus;

    db.data.pedidos[index].atualizadoEm =
        new Date().toISOString();

    await db.write();

    return db.data.pedidos[index];
}


// ======================================================
// ACEITAR PEDIDO PELO RESTAURANTE
// ======================================================

async function aceitarPedidoRestaurante(id) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    /*
     * Só permite aceitar pedidos
     * que estão aguardando o restaurante.
     */

    if (
        pedido.status !==
        "AGUARDANDO_RESTAURANTE"
    ) {
        return null;
    }

    pedido.status = "ACEITO";

    pedido.aceitoRestauranteEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// RECUSAR PEDIDO PELO RESTAURANTE
// ======================================================

async function recusarPedidoRestaurante(
    id,
    motivo
) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    if (
        pedido.status !==
        "AGUARDANDO_RESTAURANTE"
    ) {
        return null;
    }

    pedido.status = "RECUSADO";

    pedido.motivoRecusa =
        motivo ||
        "Pedido recusado pelo restaurante";

    pedido.recusadoEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// ENTREGADOR ACEITA PEDIDO
// ======================================================

async function aceitarEntrega(
    id,
    entregadorId
) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    /*
     * O entregador somente pode pegar
     * pedidos que estão PRONTOS.
     */

    if (pedido.status !== "PRONTO") {
        return null;
    }

    pedido.entregadorId =
        entregadorId;

    pedido.status =
        "EM_ENTREGA";

    pedido.aceitoEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// BUSCAR PEDIDOS DO RESTAURANTE
// ======================================================

async function listarPorRestaurante(
    restauranteId
) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    return db.data.pedidos.filter(
        (pedido) =>
            String(pedido.restauranteId) ===
            String(restauranteId)
    );
}


// ======================================================
// BUSCAR PEDIDOS DO CLIENTE
// ======================================================

async function listarPorCliente(
    clienteId
) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    return db.data.pedidos.filter(
        (pedido) =>
            String(pedido.clienteId) ===
            String(clienteId)
    );
}


// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ======================================================

async function listarDisponiveisEntrega() {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    return db.data.pedidos.filter(
        (pedido) =>
            pedido.status === "PRONTO"
    );
}


// ======================================================
// FINALIZAR ENTREGA
// ======================================================

async function finalizarEntrega(id) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    /*
     * Só pode finalizar uma entrega
     * que realmente está em entrega.
     */

    if (pedido.status !== "EM_ENTREGA") {
        return null;
    }

    pedido.status =
        "ENTREGUE";

    pedido.entregueEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// ABRIR SUPORTE
// ======================================================

async function abrirSuporte(
    pedidoId,
    autorId,
    autorTipo,
    mensagem,
    motivo
) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) ===
                Number(pedidoId)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    if (!pedido.suporte) {
        pedido.suporte = {
            aberto: false,
            status: "FECHADO",
            mensagens: []
        };
    }

    const mensagemSuporte = {

        id: Date.now(),

        autorId,

        autorTipo,

        mensagem,

        motivo:
            motivo ||
            "Problema com pedido",

        criadoEm:
            new Date().toISOString()
    };

    pedido.suporte.mensagens.push(
        mensagemSuporte
    );

    pedido.suporte.aberto = true;

    pedido.suporte.status =
        "AGUARDANDO_ADMIN";

    pedido.suporte.abertoEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// LISTAR PEDIDOS COM SUPORTE
// FUTURO PAINEL ADMIN
// ======================================================

async function listarSuportes() {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    return db.data.pedidos.filter(
        (pedido) =>
            pedido.suporte &&
            pedido.suporte.aberto === true
    );
}


// ======================================================
// RESPONDER SUPORTE
// FUTURO ADMIN
// ======================================================

async function responderSuporte(
    pedidoId,
    adminId,
    mensagem
) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) ===
                Number(pedidoId)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    if (!pedido.suporte) {
        return null;
    }

    pedido.suporte.mensagens.push({

        id: Date.now(),

        autorId: adminId,

        autorTipo: "ADMIN",

        mensagem,

        criadoEm:
            new Date().toISOString()
    });

    pedido.suporte.status =
        "RESPONDIDO_ADMIN";

    pedido.suporte.ultimaRespostaEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// FECHAR SUPORTE
// FUTURO ADMIN
// ======================================================

async function fecharSuporte(pedidoId) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    const index =
        db.data.pedidos.findIndex(
            (item) =>
                Number(item.id) ===
                Number(pedidoId)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    if (!pedido.suporte) {
        return null;
    }

    pedido.suporte.aberto = false;

    pedido.suporte.status =
        "FECHADO";

    pedido.suporte.fechadoEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// EXPORTAR
// ======================================================

module.exports = {

    criar,

    listar,

    buscarPorId,

    atualizarStatus,

    aceitarPedidoRestaurante,

    recusarPedidoRestaurante,

    aceitarEntrega,

    listarPorRestaurante,

    listarPorCliente,

    listarDisponiveisEntrega,

    finalizarEntrega,

    abrirSuporte,

    listarSuportes,

    responderSuporte,

    fecharSuporte
};