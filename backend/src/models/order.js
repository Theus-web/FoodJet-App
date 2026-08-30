
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
// GERAR ID DO PEDIDO
// ======================================================

async function gerarIdPedido() {
    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    if (db.data.pedidos.length === 0) {
        return 1;
    }

    const maiorId = db.data.pedidos.reduce(
        (maior, pedido) => {
            const id = Number(pedido.id) || 0;

            return id > maior ? id : maior;
        },
        0
    );

    return maiorId + 1;
}


// ======================================================
// CRIAR PEDIDO
// ======================================================
//
// IMPORTANTE:
// O clienteId deve ser definido pelo CONTROLLER,
// usando req.usuario.id.
//
// O Flutter NÃO deve decidir qual é o cliente.
//
// ======================================================

async function criar(pedido) {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    // ==================================================
    // VALIDAÇÕES
    // ==================================================

    if (
        !pedido ||
        typeof pedido !== "object"
    ) {
        throw new Error(
            "Dados do pedido inválidos."
        );
    }

    if (
        pedido.clienteId === undefined ||
        pedido.clienteId === null ||
        String(pedido.clienteId).trim() === ""
    ) {
        throw new Error(
            "Cliente não identificado."
        );
    }

    if (
        pedido.restauranteId === undefined ||
        pedido.restauranteId === null ||
        String(pedido.restauranteId).trim() === ""
    ) {
        throw new Error(
            "Restaurante não identificado."
        );
    }

    // ==================================================
    // ID
    // ==================================================

    const id = await gerarIdPedido();

    // ==================================================
    // ITENS
    // ==================================================

    const itens = Array.isArray(pedido.itens)
        ? pedido.itens
        : [];

    // ==================================================
    // VALORES
    // ==================================================

    const subtotal =
        Number(pedido.subtotal) || 0;

    const taxaServico =
        Number(pedido.taxaServico) || 0;

    const total =
        Number(pedido.total) ||
        subtotal + taxaServico;

    // ==================================================
    // PAGAMENTO
    // ==================================================

    const pagamento =
        String(
            pedido.pagamento || "PIX"
        )
            .trim()
            .toUpperCase();

    // ==================================================
    // TROCO
    // ==================================================

    const precisaTroco =
        pagamento === "DINHEIRO"
            ? Boolean(pedido.precisaTroco)
            : false;

    const trocoPara =
        precisaTroco
            ? Number(pedido.trocoPara) || 0
            : null;

    const valorTroco =
        precisaTroco && trocoPara !== null
            ? Math.max(
                0,
                trocoPara - total
            )
            : 0;

    // ==================================================
    // NOVO PEDIDO
    // ==================================================

    const novoPedido = {

        id,

        // ==================================================
        // CLIENTE
        // ==================================================
        //
        // Este valor deve vir do backend.
        //
        clienteId:
            String(pedido.clienteId),

        // ==================================================
        // RESTAURANTE
        // ==================================================

        restauranteId:
            String(pedido.restauranteId),

        // ==================================================
        // ITENS
        // ==================================================

        itens,

        // ==================================================
        // ENDEREÇO
        // ==================================================

        endereco:
            pedido.endereco || {},

        // ==================================================
        // PAGAMENTO
        // ==================================================

        pagamento,

        pagamentoStatus:
            pagamento === "PIX"
                ? "PENDENTE"
                : "AGUARDANDO",

        // ==================================================
        // VALORES
        // ==================================================

        subtotal,

        taxaServico,

        total,

        // ==================================================
        // TROCO
        // ==================================================

        precisaTroco,

        trocoPara,

        valorTroco,

        // ==================================================
        // REFERÊNCIA
        // ==================================================

        externalReference:
            pedido.externalReference ||
            `FOODJET-${id}-${Date.now()}`,

        // ==================================================
        // STATUS
        // ==================================================

        status:
            "AGUARDANDO_RESTAURANTE",

        // ==================================================
        // SUPORTE
        // ==================================================

        suporte: {
            aberto: false,
            status: "FECHADO",
            mensagens: []
        },

        // ==================================================
        // DATAS
        // ==================================================

        criadoEm:
            pedido.criadoEm ||
            new Date().toISOString()
    };

    // ==================================================
    // NÃO SALVAR TAXA DE ENTREGA
    // ==================================================
    //
    // A taxa pode ser calculada posteriormente
    // pelo sistema.
    //
    // ==================================================

    delete novoPedido.taxaEntrega;

    // ==================================================
    // SALVAR
    // ==================================================

    db.data.pedidos.push(
        novoPedido
    );

    await db.write();

    console.log(
        "========================================"
    );

    console.log(
        "✅ PEDIDO CRIADO"
    );

    console.log(
        "ID:",
        novoPedido.id
    );

    console.log(
        "CLIENTE:",
        novoPedido.clienteId
    );

    console.log(
        "RESTAURANTE:",
        novoPedido.restauranteId
    );

    console.log(
        "PAGAMENTO:",
        novoPedido.pagamento
    );

    console.log(
        "TOTAL:",
        novoPedido.total
    );

    console.log(
        "STATUS:",
        novoPedido.status
    );

    console.log(
        "========================================"
    );

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
            item =>
                Number(item.id) === Number(id)
        );

    return pedido || null;
}


// ======================================================
// ATUALIZAR STATUS
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
            item =>
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
            item =>
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
            item =>
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
            item =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    if (pedido.status !== "PRONTO") {
        return null;
    }

    pedido.entregadorId =
        String(entregadorId);

    pedido.status =
        "EM_ENTREGA";

    pedido.aceitoEm =
        new Date().toISOString();

    await db.write();

    return pedido;
}


// ======================================================
// PEDIDOS DO RESTAURANTE
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
        pedido =>
            String(pedido.restauranteId) ===
            String(restauranteId)
    );
}


// ======================================================
// PEDIDOS DO CLIENTE
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
        pedido =>
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
        pedido =>
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
            item =>
                Number(item.id) === Number(id)
        );

    if (index === -1) {
        return null;
    }

    const pedido =
        db.data.pedidos[index];

    if (
        pedido.status !==
        "EM_ENTREGA"
    ) {
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
            item =>
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
// LISTAR SUPORTES
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
        pedido =>
            pedido.suporte &&
            pedido.suporte.aberto === true
    );
}


// ======================================================
// RESPONDER SUPORTE
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
            item =>
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
// ======================================================

async function fecharSuporte(
    pedidoId
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
            item =>
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

    prepararBanco,

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

