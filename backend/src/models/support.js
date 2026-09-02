const { pool } = require("../config/database");

// ======================================================
// GARANTIR ESTRUTURA
// ======================================================

async function garantirEstrutura() {
    await pool.query("SELECT 1");
}

// ======================================================
// CONVERTER LINHA DO POSTGRES
// PARA O FORMATO ANTIGO DO FOODJET
// ======================================================

function montarChamado(row) {
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

        assunto: row.assunto,
        descricao: row.descricao,
        status: row.status,

        mensagens: Array.isArray(row.mensagens)
            ? row.mensagens
            : Array.isArray(dados.mensagens)
                ? dados.mensagens
                : [],

        criadoEm: row.criado_em
            ? new Date(row.criado_em).toISOString()
            : dados.criadoEm,

        atualizadoEm: row.atualizado_em
            ? new Date(row.atualizado_em).toISOString()
            : dados.atualizadoEm
    };
}

// ======================================================
// CRIAR CHAMADO
// ======================================================

async function criar(chamado) {

    await garantirEstrutura();

    if (!chamado || typeof chamado !== "object") {
        throw new Error("Dados do chamado inválidos.");
    }

    if (
        chamado.id === undefined ||
        chamado.id === null
    ) {
        throw new Error("ID do chamado é obrigatório.");
    }

    const agora =
        chamado.criadoEm ||
        new Date().toISOString();

    const atualizadoEm =
        chamado.atualizadoEm ||
        agora;

    const mensagens =
        Array.isArray(chamado.mensagens)
            ? chamado.mensagens
            : [];

    const dados = {
        ...chamado,
        criadoEm: agora,
        atualizadoEm
    };

    await pool.query(
        `
        INSERT INTO suportes (
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            assunto,
            descricao,
            status,
            mensagens,
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
            $8::jsonb,
            $9,
            $10,
            $11::jsonb
        )
        ON CONFLICT (id)
        DO UPDATE SET
            pedido_id = EXCLUDED.pedido_id,
            cliente_id = EXCLUDED.cliente_id,
            restaurante_id = EXCLUDED.restaurante_id,
            assunto = EXCLUDED.assunto,
            descricao = EXCLUDED.descricao,
            status = EXCLUDED.status,
            mensagens = EXCLUDED.mensagens,
            atualizado_em = EXCLUDED.atualizado_em,
            dados = EXCLUDED.dados
        `,
        [
            chamado.id,
            chamado.pedidoId !== undefined &&
            chamado.pedidoId !== null
                ? String(chamado.pedidoId)
                : null,

            chamado.clienteId !== undefined &&
            chamado.clienteId !== null
                ? String(chamado.clienteId)
                : null,

            chamado.restauranteId !== undefined &&
            chamado.restauranteId !== null
                ? String(chamado.restauranteId)
                : null,

            chamado.assunto || null,
            chamado.descricao || null,
            chamado.status || "ABERTO",

            JSON.stringify(mensagens),

            agora,
            atualizadoEm,

            JSON.stringify(dados)
        ]
    );

    return chamado;
}

// ======================================================
// LISTAR TODOS
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
            assunto,
            descricao,
            status,
            mensagens,
            criado_em,
            atualizado_em,
            dados
        FROM suportes
        ORDER BY criado_em DESC
        `
    );

    return resultado.rows.map(montarChamado);
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
            assunto,
            descricao,
            status,
            mensagens,
            criado_em,
            atualizado_em,
            dados
        FROM suportes
        WHERE id = $1
        LIMIT 1
        `,
        [id]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarChamado(resultado.rows[0]);
}

// ======================================================
// BUSCAR PELO PEDIDO
// ======================================================

async function buscarPorPedido(pedidoId) {

    await garantirEstrutura();

    const resultado = await pool.query(
        `
        SELECT
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            assunto,
            descricao,
            status,
            mensagens,
            criado_em,
            atualizado_em,
            dados
        FROM suportes
        WHERE pedido_id = $1
        ORDER BY criado_em DESC
        `,
        [String(pedidoId)]
    );

    return resultado.rows.map(montarChamado);
}

// ======================================================
// BUSCAR DO CLIENTE
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
            assunto,
            descricao,
            status,
            mensagens,
            criado_em,
            atualizado_em,
            dados
        FROM suportes
        WHERE cliente_id = $1
        ORDER BY criado_em DESC
        `,
        [String(clienteId)]
    );

    return resultado.rows.map(montarChamado);
}

// ======================================================
// BUSCAR DO RESTAURANTE
// ======================================================

async function listarPorRestaurante(restauranteId) {

    await garantirEstrutura();

    const resultado = await pool.query(
        `
        SELECT
            id,
            pedido_id,
            cliente_id,
            restaurante_id,
            assunto,
            descricao,
            status,
            mensagens,
            criado_em,
            atualizado_em,
            dados
        FROM suportes
        WHERE restaurante_id = $1
        ORDER BY criado_em DESC
        `,
        [String(restauranteId)]
    );

    return resultado.rows.map(montarChamado);
}

// ======================================================
// ATUALIZAR CHAMADO
// ======================================================

async function atualizar(id, dadosAtualizacao) {

    await garantirEstrutura();

    const atual = await buscarPorId(id);

    if (!atual) {
        return null;
    }

    const atualizadoEm =
        new Date().toISOString();

    const chamadoAtualizado = {
        ...atual,
        ...dadosAtualizacao,
        id: atual.id,
        atualizadoEm
    };

    const mensagens =
        Array.isArray(chamadoAtualizado.mensagens)
            ? chamadoAtualizado.mensagens
            : [];

    const dados = {
        ...chamadoAtualizado
    };

    await pool.query(
        `
        UPDATE suportes
        SET
            pedido_id = $2,
            cliente_id = $3,
            restaurante_id = $4,
            assunto = $5,
            descricao = $6,
            status = $7,
            mensagens = $8::jsonb,
            atualizado_em = $9,
            dados = $10::jsonb
        WHERE id = $1
        `,
        [
            id,

            chamadoAtualizado.pedidoId !== undefined &&
            chamadoAtualizado.pedidoId !== null
                ? String(chamadoAtualizado.pedidoId)
                : null,

            chamadoAtualizado.clienteId !== undefined &&
            chamadoAtualizado.clienteId !== null
                ? String(chamadoAtualizado.clienteId)
                : null,

            chamadoAtualizado.restauranteId !== undefined &&
            chamadoAtualizado.restauranteId !== null
                ? String(chamadoAtualizado.restauranteId)
                : null,

            chamadoAtualizado.assunto || null,
            chamadoAtualizado.descricao || null,
            chamadoAtualizado.status || "ABERTO",

            JSON.stringify(mensagens),

            atualizadoEm,

            JSON.stringify(dados)
        ]
    );

    return chamadoAtualizado;
}

// ======================================================
// ADICIONAR MENSAGEM
// ======================================================

async function adicionarMensagem(id, mensagem) {

    await garantirEstrutura();

    const atual = await buscarPorId(id);

    if (!atual) {
        return null;
    }

    if (!Array.isArray(atual.mensagens)) {
        atual.mensagens = [];
    }

    atual.mensagens.push(mensagem);

    atual.atualizadoEm =
        new Date().toISOString();

    const dados = {
        ...atual
    };

    await pool.query(
        `
        UPDATE suportes
        SET
            mensagens = $2::jsonb,
            atualizado_em = $3,
            dados = $4::jsonb
        WHERE id = $1
        `,
        [
            id,
            JSON.stringify(atual.mensagens),
            atual.atualizadoEm,
            JSON.stringify(dados)
        ]
    );

    return atual;
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