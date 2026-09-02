const { pool } = require("../config/database");

// ======================================================
// GARANTIR ESTRUTURA
// ======================================================

async function garantirEstrutura() {
    await pool.query("SELECT 1");
}

// ======================================================
// MONTAR RECLAMAÇÃO
// ======================================================

function montarReclamacao(row) {

    if (!row) {
        return null;
    }

    const dados =
        row.dados &&
        typeof row.dados === "object"
            ? row.dados
            : {};

    return {
        ...dados,

        id: row.id,

        pedidoId: row.pedido_id,

        clienteId: row.cliente_id,

        restauranteId: row.restaurante_id,

        status: row.status,

        resposta: row.resposta,

        criadoEm: row.criado_em
            ? new Date(row.criado_em).toISOString()
            : dados.criadoEm,

        atualizadoEm: row.atualizado_em
            ? new Date(row.atualizado_em).toISOString()
            : dados.atualizadoEm
    };
}

// ======================================================
// CRIAR RECLAMAÇÃO
// ======================================================

async function criar(reclamacao) {

    await garantirEstrutura();

    if (
        !reclamacao ||
        typeof reclamacao !== "object"
    ) {
        throw new Error(
            "Dados da reclamação inválidos."
        );
    }

    if (
        reclamacao.id === undefined ||
        reclamacao.id === null
    ) {
        throw new Error(
            "ID da reclamação é obrigatório."
        );
    }

    const agora =
        reclamacao.criadoEm ||
        new Date().toISOString();

    const atualizadoEm =
        reclamacao.atualizadoEm ||
        agora;

    const dados = {
        ...reclamacao,
        criadoEm: agora,
        atualizadoEm
    };

    await pool.query(
        `
        INSERT INTO reclamacoes (
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            status,
            resposta,
            criado_em,
            atualizado_em,
            dados
        )
        VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            $7,
            $8,
            $9::jsonb
        )
        ON CONFLICT (id)
        DO UPDATE SET
            pedido_id = EXCLUDED.pedido_id,
            cliente_id = EXCLUDED.cliente_id,
            restaurante_id = EXCLUDED.restaurante_id,
            status = EXCLUDED.status,
            resposta = EXCLUDED.resposta,
            atualizado_em = EXCLUDED.atualizado_em,
            dados = EXCLUDED.dados
        `,
        [
            reclamacao.id,

            reclamacao.pedidoId !== undefined &&
            reclamacao.pedidoId !== null
                ? String(reclamacao.pedidoId)
                : null,

            reclamacao.clienteId !== undefined &&
            reclamacao.clienteId !== null
                ? String(reclamacao.clienteId)
                : null,

            reclamacao.restauranteId !== undefined &&
            reclamacao.restauranteId !== null
                ? String(reclamacao.restauranteId)
                : null,

            reclamacao.status || "ABERTA",

            reclamacao.resposta || null,

            agora,

            atualizadoEm,

            JSON.stringify(dados)
        ]
    );

    return reclamacao;
}

// ======================================================
// LISTAR TODAS
// ======================================================

async function listar() {

    await garantirEstrutura();

    const resultado = await pool.query(
        `
        SELECT
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            status,
            resposta,
            criado_em,
            atualizado_em,
            dados
        FROM reclamacoes
        ORDER BY criado_em DESC
        `
    );

    return resultado.rows.map(
        montarReclamacao
    );
}

// ======================================================
// BUSCAR POR ID
// ======================================================

async function buscarPorId(id) {

    await garantirEstrutura();

    const resultado = await pool.query(
        `
        SELECT
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            status,
            resposta,
            criado_em,
            atualizado_em,
            dados
        FROM reclamacoes
        WHERE id = $1
        LIMIT 1
        `,
        [id]
    );

    if (
        resultado.rows.length === 0
    ) {
        return null;
    }

    return montarReclamacao(
        resultado.rows[0]
    );
}

// ======================================================
// BUSCAR RECLAMAÇÕES DO PEDIDO
// ======================================================

async function listarPorPedido(pedidoId) {

    await garantirEstrutura();

    const resultado = await pool.query(
        `
        SELECT
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            status,
            resposta,
            criado_em,
            atualizado_em,
            dados
        FROM reclamacoes
        WHERE pedido_id = $1
        ORDER BY criado_em DESC
        `,
        [String(pedidoId)]
    );

    return resultado.rows.map(
        montarReclamacao
    );
}

// ======================================================
// BUSCAR RECLAMAÇÕES DO CLIENTE
// ======================================================

async function listarPorCliente(clienteId) {

    await garantirEstrutura();

    const resultado = await pool.query(
        `
        SELECT
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            status,
            resposta,
            criado_em,
            atualizado_em,
            dados
        FROM reclamacoes
        WHERE cliente_id = $1
        ORDER BY criado_em DESC
        `,
        [String(clienteId)]
    );

    return resultado.rows.map(
        montarReclamacao
    );
}

// ======================================================
// BUSCAR RECLAMAÇÕES DO RESTAURANTE
// ======================================================

async function listarPorRestaurante(
    restauranteId
) {

    await garantirEstrutura();

    const resultado = await pool.query(
        `
        SELECT
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            status,
            resposta,
            criado_em,
            atualizado_em,
            dados
        FROM reclamacoes
        WHERE restaurante_id = $1
        ORDER BY criado_em DESC
        `,
        [String(restauranteId)]
    );

    return resultado.rows.map(
        montarReclamacao
    );
}

// ======================================================
// ATUALIZAR STATUS
// ======================================================

async function atualizarStatus(
    id,
    status,
    resposta
) {

    await garantirEstrutura();

    const atual =
        await buscarPorId(id);

    if (!atual) {
        return null;
    }

    const atualizadoEm =
        new Date().toISOString();

    const reclamacaoAtualizada = {
        ...atual,

        status,

        ...(resposta
            ? { resposta }
            : {}),

        atualizadoEm
    };

    const dados = {
        ...reclamacaoAtualizada
    };

    await pool.query(
        `
        UPDATE reclamacoes
        SET
            status = $2,
            resposta = $3,
            atualizado_em = $4,
            dados = $5::jsonb
        WHERE id = $1
        `,
        [
            id,

            status,

            resposta !== undefined &&
            resposta !== null &&
            resposta !== ""
                ? resposta
                : atual.resposta || null,

            atualizadoEm,

            JSON.stringify(dados)
        ]
    );

    return reclamacaoAtualizada;
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