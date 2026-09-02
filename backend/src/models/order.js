const { pool } = require("../config/database");

// ======================================================
// GARANTIR CONEXÃO
// ======================================================

async function prepararBanco() {

    await pool.query("SELECT 1");

}


// ======================================================
// GERAR ID DO PEDIDO
// ======================================================
//
// O PostgreSQL possui uma sequence na coluna pedidos.id.
//
// Isso evita gerar ID manualmente no Node e mantém a
// sequência existente após a migração.
// ======================================================

async function gerarIdPedido() {

    const resultado = await pool.query(
        `
        SELECT nextval(
            pg_get_serial_sequence(
                'pedidos',
                'id'
            )
        ) AS id
        `
    );

    if (
        !resultado.rows.length ||
        resultado.rows[0].id === null
    ) {
        throw new Error(
            "Não foi possível gerar o ID do pedido."
        );
    }

    return Number(
        resultado.rows[0].id
    );
}


// ======================================================
// ENCONTRAR PAGAMENTO ASAAS PENDENTE
// ======================================================
//
// Antes:
// db.data.pagamentosAsaas
//
// Agora:
// PostgreSQL -> pagamentos_asaas
//
// O webhook salva o pagamento nessa tabela caso o pedido
// ainda não exista.
//
// Quando o pedido for criado, procuramos pela mesma
// externalReference e fazemos a conciliação.
// ======================================================

async function encontrarPagamentoAsaasPendente(
    externalReference
) {

    const referencia =
        String(
            externalReference || ""
        ).trim();

    if (!referencia) {
        return null;
    }

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                pagamento_id,
                external_reference,
                status_asaas,
                status_pagamento,
                evento,
                valor,
                atualizado_em,
                dados
            FROM pagamentos_asaas
            WHERE
                external_reference = $1
            ORDER BY id DESC
            LIMIT 1
            `,
            [
                referencia
            ]
        );

    if (
        resultado.rows.length === 0
    ) {
        return null;
    }

    const row =
        resultado.rows[0];

    let dados =
        row.dados;

    if (
        typeof dados === "string"
    ) {

        try {

            dados =
                JSON.parse(dados);

        } catch {

            dados = {};

        }

    }

    if (
        !dados ||
        typeof dados !== "object"
    ) {

        dados = {};

    }

    return {

        id:
            row.id,

        pagamentoId:
            row.pagamento_id ||
            dados.pagamentoId ||
            dados.paymentId ||
            "",

        paymentId:
            row.pagamento_id ||
            dados.paymentId ||
            dados.pagamentoId ||
            "",

        externalReference:
            row.external_reference ||
            dados.externalReference ||
            "",

        statusAsaas:
            row.status_asaas ||
            dados.statusAsaas ||
            "",

        statusPagamento:
            row.status_pagamento ||
            dados.statusPagamento ||
            "pending",

        valor:
            Number(
                row.valor
            ) ||
            Number(
                dados.valor
            ) ||
            0,

        evento:
            row.evento ||
            dados.evento ||
            "",

        atualizadoEm:
            row.atualizado_em
                ? new Date(
                    row.atualizado_em
                ).toISOString()
                : (
                    dados.atualizadoEm ||
                    new Date().toISOString()
                ),

        dados,

    };

}


// ======================================================
// MARCAR PAGAMENTO ASAAS COMO CONCILIADO
// ======================================================
//
// Não apagamos o registro.
//
// O histórico permanece no PostgreSQL.
//
// Apenas adicionamos informações de conciliação dentro
// do JSONB `dados`.
// ======================================================

async function marcarPagamentoAsaasConciliado(
    pagamentoAsaas,
    pedido
) {

    if (
        !pagamentoAsaas ||
        !pagamentoAsaas.id ||
        !pedido
    ) {
        return;
    }

    const dadosAtuais =
        pagamentoAsaas.dados &&
        typeof pagamentoAsaas.dados === "object"
            ? pagamentoAsaas.dados
            : {};

    const dadosAtualizados = {

        ...dadosAtuais,

        conciliado: true,

        conciliadoEm:
            new Date().toISOString(),

        pedidoId:
            pedido.id,

        pedidoRestauranteId:
            pedido.restauranteId ||
            null,

    };

    await pool.query(
        `
        UPDATE pagamentos_asaas
        SET
            dados = $1,
            atualizado_em = $2
        WHERE id = $3
        `,
        [
            dadosAtualizados,
            new Date(),
            pagamentoAsaas.id,
        ]
    );

    console.log(
        "🔗 PAGAMENTO ASAAS CONCILIADO COM PEDIDO:",
        pedido.id
    );

}


// ======================================================
// CRIAR PEDIDO
// ======================================================
//
// IMPORTANTE:
//
// clienteId continua vindo do controller:
//
// req.usuario.id
//
// O Flutter NÃO define o cliente.
// ======================================================

async function criar(pedido) {

    await prepararBanco();

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
        String(
            pedido.clienteId
        ).trim() === ""
    ) {

        throw new Error(
            "Cliente não identificado."
        );
    }

    if (
        pedido.restauranteId === undefined ||
        pedido.restauranteId === null ||
        String(
            pedido.restauranteId
        ).trim() === ""
    ) {

        throw new Error(
            "Restaurante não identificado."
        );
    }

    // ==================================================
    // ID
    // ==================================================

    const id =
        await gerarIdPedido();

    // ==================================================
    // ITENS
    // ==================================================

    const itens =
        Array.isArray(pedido.itens)
            ? pedido.itens
            : [];

    // ==================================================
    // VALORES
    // ==================================================

    const subtotal =
        Number(
            pedido.subtotal
        ) || 0;

    const taxaServico =
        Number(
            pedido.taxaServico
        ) || 0;

    const total =
        Number(
            pedido.total
        ) ||
        subtotal +
        taxaServico;

    // ==================================================
    // PAGAMENTO
    // ==================================================

    const pagamento =
        String(
            pedido.pagamento ||
            "PIX"
        )
            .trim()
            .toUpperCase();

    // ==================================================
    // TROCO
    // ==================================================

    const precisaTroco =
        pagamento === "DINHEIRO"
            ? Boolean(
                pedido.precisaTroco
            )
            : false;

    const trocoPara =
        precisaTroco
            ? Number(
                pedido.trocoPara
            ) || 0
            : null;

    const valorTroco =
        precisaTroco &&
        trocoPara !== null
            ? Math.max(
                0,
                trocoPara - total
            )
            : 0;

    // ==================================================
    // REFERÊNCIA ASAAS
    // ==================================================
    //
    // Se o controller já tiver fornecido uma referência,
    // preservamos.
    //
    // Caso contrário, usamos o ID do pedido.
    // ==================================================

    const externalReference =
        String(
            pedido.externalReference ||
            pedido.referenciaPagamento ||
            id
        ).trim();

    // ==================================================
    // NOVO PEDIDO
    // ==================================================

    const novoPedido = {

        id,

        // ------------------------------------------------
        // CLIENTE
        // ------------------------------------------------

        clienteId:
            String(
                pedido.clienteId
            ),

        // ------------------------------------------------
        // RESTAURANTE
        // ------------------------------------------------

        restauranteId:
            String(
                pedido.restauranteId
            ),

        // ------------------------------------------------
        // ITENS
        // ------------------------------------------------

        itens,

        // ------------------------------------------------
        // ENDEREÇO
        // ------------------------------------------------

        endereco:
            pedido.endereco || {},

        // ------------------------------------------------
        // PAGAMENTO
        // ------------------------------------------------

        pagamento,

        pagamentoStatus:
            pagamento === "PIX"
                ? "PENDENTE"
                : "AGUARDANDO",

        statusPagamento:
            "pending",

        pagamentoAprovado:
            false,

        // ------------------------------------------------
        // VALORES
        // ------------------------------------------------

        subtotal,

        taxaServico,

        total,

        // ------------------------------------------------
        // TROCO
        // ------------------------------------------------

        precisaTroco,

        trocoPara,

        valorTroco,

        // ------------------------------------------------
        // ASAAS
        // ------------------------------------------------

        externalReference,

        referenciaPagamento:
            externalReference,

        // ------------------------------------------------
        // STATUS
        // ------------------------------------------------

        status:
            "AGUARDANDO_RESTAURANTE",

        // ------------------------------------------------
        // SUPORTE
        // ------------------------------------------------

        suporte: {

            aberto: false,

            status: "FECHADO",

            mensagens: []

        },

        // ------------------------------------------------
        // DATA
        // ------------------------------------------------

        criadoEm:
            pedido.criadoEm ||
            new Date().toISOString()

    };

    // ==================================================
    // PRESERVAR DADOS EXTRAS DO PEDIDO
    // ==================================================
    //
    // O objeto recebido pode possuir outros campos usados
    // pelo restante do FoodJet.
    //
    // Copiamos somente campos que não foram definidos acima.
    // ==================================================

    for (
        const [chave, valor]
        of Object.entries(pedido)
    ) {

        if (
            novoPedido[chave] === undefined
        ) {

            novoPedido[chave] =
                valor;

        }

    }

    // ==================================================
    // NÃO SALVAR TAXA DE ENTREGA
    // ==================================================

    delete novoPedido.taxaEntrega;

    // ==================================================
    // RECONCILIAR ASAAS
    // ==================================================
    //
    // O webhook pode ter chegado antes do pedido.
    //
    // Nesse caso o pagamento está em:
    //
    // pagamentos_asaas
    //
    // e agora tentamos associá-lo ao pedido.
    // ==================================================

    const pagamentoAsaas =
        await encontrarPagamentoAsaasPendente(
            novoPedido.externalReference
        );

    if (pagamentoAsaas) {

        console.log(
            "========================================"
        );

        console.log(
            "🔄 RECONCILIANDO PAGAMENTO ASAAS"
        );

        console.log(
            "REFERÊNCIA:",
            novoPedido.externalReference
        );

        console.log(
            "PAGAMENTO ASAAS:",
            pagamentoAsaas.pagamentoId
        );

        console.log(
            "STATUS ASAAS:",
            pagamentoAsaas.statusAsaas
        );

        console.log(
            "STATUS FOODJET:",
            pagamentoAsaas.statusPagamento
        );

        // ------------------------------------------------
        // DADOS ASAAS
        // ------------------------------------------------

        novoPedido.pagamentoId =
            pagamentoAsaas.pagamentoId ||
            "";

        novoPedido.asaasPaymentId =
            pagamentoAsaas.pagamentoId ||
            "";

        novoPedido.externalReference =
            pagamentoAsaas.externalReference ||
            novoPedido.externalReference;

        novoPedido.referenciaPagamento =
            pagamentoAsaas.externalReference ||
            novoPedido.referenciaPagamento;

        novoPedido.statusPagamento =
            pagamentoAsaas.statusPagamento ||
            "pending";

        novoPedido.statusPagamentoAsaas =
            pagamentoAsaas.statusAsaas ||
            "";

        novoPedido.asaasEvento =
            pagamentoAsaas.evento ||
            "";

        novoPedido.asaasAtualizadoEm =
            pagamentoAsaas.atualizadoEm ||
            new Date().toISOString();

        novoPedido.pagamentoAtualizadoEm =
            pagamentoAsaas.atualizadoEm ||
            new Date().toISOString();

        novoPedido.valorPagamento =
            Number(
                pagamentoAsaas.valor
            ) || 0;

        // ------------------------------------------------
        // PAGAMENTO APROVADO
        // ------------------------------------------------

        if (
            pagamentoAsaas.statusPagamento ===
            "approved"
        ) {

            novoPedido.statusPagamento =
                "approved";

            novoPedido.pagamentoAprovado =
                true;

            novoPedido.pagamentoAprovadoEm =
                new Date().toISOString();

            novoPedido.status =
                "AGUARDANDO_RESTAURANTE";

            novoPedido.pagamentoStatus =
                "PAGO";

            console.log(
                "========================================"
            );

            console.log(
                "✅ PIX JÁ ESTAVA PAGO"
            );

            console.log(
                "💳 STATUS:",
                "APPROVED"
            );

            console.log(
                "📦 PEDIDO:",
                novoPedido.id
            );

            console.log(
                "🍽️ STATUS:",
                "AGUARDANDO_RESTAURANTE"
            );

            console.log(
                "========================================"
            );

        }

        // ------------------------------------------------
        // PAGAMENTO AINDA PENDENTE
        // ------------------------------------------------

        else {

            novoPedido.pagamentoAprovado =
                false;

            console.log(
                "⏳ PAGAMENTO ASAAS AINDA PENDENTE"
            );

        }

    }

    // ==================================================
    // SALVAR NO POSTGRESQL
    // ==================================================

    const resultado =
        await pool.query(
            `
            INSERT INTO pedidos (
                id,
                dados
            )
            VALUES (
                $1,
                $2
            )
            RETURNING
                id,
                dados
            `,
            [
                id,
                novoPedido,
            ]
        );

    const pedidoSalvo =
        montarPedido(
            resultado.rows[0]
        );

    // ==================================================
    // MARCAR PAGAMENTO COMO CONCILIADO
    // ==================================================

    if (pagamentoAsaas) {

        await marcarPagamentoAsaasConciliado(
            pagamentoAsaas,
            pedidoSalvo
        );

    }

    // ==================================================
    // LOG
    // ==================================================

    console.log(
        "========================================"
    );

    console.log(
        "✅ PEDIDO CRIADO NO POSTGRESQL"
    );

    console.log(
        "ID:",
        pedidoSalvo.id
    );

    console.log(
        "CLIENTE:",
        pedidoSalvo.clienteId
    );

    console.log(
        "RESTAURANTE:",
        pedidoSalvo.restauranteId
    );

    console.log(
        "PAGAMENTO:",
        pedidoSalvo.pagamento
    );

    console.log(
        "PAGAMENTO ID:",
        pedidoSalvo.pagamentoId ||
        "NÃO DEFINIDO"
    );

    console.log(
        "STATUS PAGAMENTO:",
        pedidoSalvo.statusPagamento
    );

    console.log(
        "PAGAMENTO APROVADO:",
        pedidoSalvo.pagamentoAprovado
    );

    console.log(
        "TOTAL:",
        pedidoSalvo.total
    );

    console.log(
        "STATUS PEDIDO:",
        pedidoSalvo.status
    );

    console.log(
        "REFERÊNCIA:",
        pedidoSalvo.externalReference
    );

    console.log(
        "========================================"
    );

    return pedidoSalvo;
}


// ======================================================
// LISTAR TODOS OS PEDIDOS
// ======================================================

async function listar() {

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                dados
            FROM pedidos
            ORDER BY id ASC
            `
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// BUSCAR PEDIDO PELO ID
// ======================================================

async function buscarPorId(id) {

    if (
        id === undefined ||
        id === null ||
        String(id).trim() === ""
    ) {
        return null;
    }

    const numeroId =
        Number(id);

    if (
        !Number.isSafeInteger(
            numeroId
        )
    ) {
        return null;
    }

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                dados
            FROM pedidos
            WHERE id = $1
            LIMIT 1
            `,
            [
                numeroId
            ]
        );

    if (
        resultado.rows.length === 0
    ) {
        return null;
    }

    return montarPedido(
        resultado.rows[0]
    );
}


// ======================================================
// ATUALIZAR PEDIDO NO JSONB
// ======================================================

async function atualizarDadosPedido(
    id,
    alteracoes
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {
        return null;
    }

    const pedidoAtualizado = {

        ...pedido,

        ...alteracoes,

        id:
            pedido.id,

        atualizadoEm:
            new Date().toISOString(),

    };

    const resultado =
        await pool.query(
            `
            UPDATE pedidos
            SET dados = $1
            WHERE id = $2
            RETURNING
                id,
                dados
            `,
            [
                pedidoAtualizado,
                Number(id)
            ]
        );

    if (
        resultado.rows.length === 0
    ) {
        return null;
    }

    return montarPedido(
        resultado.rows[0]
    );
}


// ======================================================
// ATUALIZAR STATUS
// ======================================================

async function atualizarStatus(
    id,
    novoStatus
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {
        return null;
    }

    return atualizarDadosPedido(
        id,
        {
            status:
                novoStatus,
        }
    );
}


// ======================================================
// ACEITAR PEDIDO PELO RESTAURANTE
// ======================================================

async function aceitarPedidoRestaurante(
    id
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {
        return null;
    }

    if (
        pedido.status !==
        "AGUARDANDO_RESTAURANTE"
    ) {
        return null;
    }

    return atualizarDadosPedido(
        id,
        {
            status:
                "ACEITO",

            aceitoRestauranteEm:
                new Date().toISOString(),
        }
    );
}


// ======================================================
// RECUSAR PEDIDO PELO RESTAURANTE
// ======================================================

async function recusarPedidoRestaurante(
    id,
    motivo
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {
        return null;
    }

    if (
        pedido.status !==
        "AGUARDANDO_RESTAURANTE"
    ) {
        return null;
    }

    return atualizarDadosPedido(
        id,
        {
            status:
                "RECUSADO",

            motivoRecusa:
                motivo ||
                "Pedido recusado pelo restaurante",

            recusadoEm:
                new Date().toISOString(),
        }
    );
}


// ======================================================
// ENTREGADOR ACEITA PEDIDO
// ======================================================

async function aceitarEntrega(
    id,
    entregadorId
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {
        return null;
    }

    if (
        pedido.status !==
        "PRONTO"
    ) {
        return null;
    }

    return atualizarDadosPedido(
        id,
        {
            entregadorId:
                String(
                    entregadorId
                ),

            status:
                "EM_ENTREGA",

            aceitoEm:
                new Date().toISOString(),
        }
    );
}


// ======================================================
// PEDIDOS DO RESTAURANTE
// ======================================================

async function listarPorRestaurante(
    restauranteId
) {

    if (
        restauranteId === undefined ||
        restauranteId === null ||
        String(restauranteId).trim() === ""
    ) {
        return [];
    }

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                dados
            FROM pedidos
            WHERE dados->>'restauranteId' = $1
            ORDER BY id DESC
            `,
            [
                String(
                    restauranteId
                )
            ]
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// PEDIDOS DO CLIENTE
// ======================================================

async function listarPorCliente(
    clienteId
) {

    if (
        clienteId === undefined ||
        clienteId === null ||
        String(clienteId).trim() === ""
    ) {
        return [];
    }

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                dados
            FROM pedidos
            WHERE dados->>'clienteId' = $1
            ORDER BY id DESC
            `,
            [
                String(
                    clienteId
                )
            ]
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ======================================================

async function listarDisponiveisEntrega() {

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                dados
            FROM pedidos
            WHERE dados->>'status' = 'PRONTO'
            ORDER BY id ASC
            `
        );

    return resultado.rows.map(
        montarPedido
    );
}


// ======================================================
// FINALIZAR ENTREGA
// ======================================================

async function finalizarEntrega(
    id
) {

    const pedido =
        await buscarPorId(id);

    if (!pedido) {
        return null;
    }

    if (
        pedido.status !==
        "EM_ENTREGA"
    ) {
        return null;
    }

    return atualizarDadosPedido(
        id,
        {
            status:
                "ENTREGUE",

            entregueEm:
                new Date().toISOString(),
        }
    );
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

    const pedido =
        await buscarPorId(
            pedidoId
        );

    if (!pedido) {
        return null;
    }

    const suporteAtual =
        pedido.suporte || {

            aberto: false,

            status:
                "FECHADO",

            mensagens: []

        };

    if (
        !Array.isArray(
            suporteAtual.mensagens
        )
    ) {

        suporteAtual.mensagens = [];

    }

    const momento =
        new Date().toISOString();

    const mensagemSuporte = {

        id:
            Date.now(),

        autorId,

        autorTipo,

        mensagem,

        motivo:
            motivo ||
            "Problema com pedido",

        criadoEm:
            momento,

    };

    suporteAtual.mensagens.push(
        mensagemSuporte
    );

    suporteAtual.aberto =
        true;

    suporteAtual.status =
        "AGUARDANDO_ADMIN";

    suporteAtual.abertoEm =
        momento;

    return atualizarDadosPedido(
        pedidoId,
        {
            suporte:
                suporteAtual
        }
    );
}


// ======================================================
// LISTAR SUPORTES
// ======================================================

async function listarSuportes() {

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                dados
            FROM pedidos
            WHERE
                COALESCE(
                    (dados->'suporte'->>'aberto')::boolean,
                    false
                ) = true
            ORDER BY id DESC
            `
        );

    return resultado.rows.map(
        montarPedido
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

    const pedido =
        await buscarPorId(
            pedidoId
        );

    if (!pedido) {
        return null;
    }

    if (!pedido.suporte) {
        return null;
    }

    const suporte = {

        ...pedido.suporte,

    };

    if (
        !Array.isArray(
            suporte.mensagens
        )
    ) {

        suporte.mensagens = [];

    }

    const momento =
        new Date().toISOString();

    suporte.mensagens.push({

        id:
            Date.now(),

        autorId:
            adminId,

        autorTipo:
            "ADMIN",

        mensagem,

        criadoEm:
            momento,

    });

    suporte.status =
        "RESPONDIDO_ADMIN";

    suporte.ultimaRespostaEm =
        momento;

    return atualizarDadosPedido(
        pedidoId,
        {
            suporte
        }
    );
}


// ======================================================
// FECHAR SUPORTE
// ======================================================

async function fecharSuporte(
    pedidoId
) {

    const pedido =
        await buscarPorId(
            pedidoId
        );

    if (!pedido) {
        return null;
    }

    if (!pedido.suporte) {
        return null;
    }

    const suporte = {

        ...pedido.suporte,

        aberto:
            false,

        status:
            "FECHADO",

        fechadoEm:
            new Date().toISOString(),

    };

    return atualizarDadosPedido(
        pedidoId,
        {
            suporte
        }
    );
}


// ======================================================
// MONTAR PEDIDO
// ======================================================

function montarPedido(row) {

    if (!row) {
        return null;
    }

    let dados =
        row.dados;

    // --------------------------------------------------
    // Segurança caso o driver devolva JSON como string
    // --------------------------------------------------

    if (
        typeof dados === "string"
    ) {

        try {

            dados =
                JSON.parse(dados);

        } catch {

            dados = {};

        }

    }

    if (
        !dados ||
        typeof dados !== "object"
    ) {

        dados = {};

    }

    return {

        ...dados,

        id:
            row.id !== undefined &&
            row.id !== null
                ? Number(
                    row.id
                )
                : dados.id,

    };

}


// ======================================================
// EXPORTAR
// ======================================================

module.exports = {

    prepararBanco,

    criar,

    listar,

    buscarPorId,

    atualizarDadosPedido,

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

    fecharSuporte,

};