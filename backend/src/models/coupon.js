const { pool } = require("../config/database");

// ======================================================
// MONTAR CUPOM
// ======================================================

function montarCupom(row) {

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

        restauranteId:
            row.restaurante_id,

        codigo:
            row.codigo,

        descricao:
            row.descricao || "",

        tipo:
            row.tipo || "PORCENTAGEM",

        valor:
            Number(row.valor || 0),

        valorMinimo:
            Number(row.valor_minimo || 0),

        limiteUso:
            Number(row.limite_uso || 0),

        usos:
            Number(row.usos || 0),

        ativo:
            row.ativo !== false,

        criadoEm:
            row.criado_em
                ? new Date(row.criado_em).toISOString()
                : dados.criadoEm
    };
}

// ======================================================
// CRIAR
// ======================================================

async function criar(cupom) {

    if (!cupom || typeof cupom !== "object") {
        throw new Error(
            "Dados do cupom inválidos."
        );
    }

    if (
        cupom.restauranteId === undefined ||
        cupom.restauranteId === null
    ) {
        throw new Error(
            "restauranteId é obrigatório."
        );
    }

    if (!cupom.codigo) {
        throw new Error(
            "Código do cupom é obrigatório."
        );
    }

    const novoCupom = {

        id: Date.now().toString(),

        restauranteId:
            String(cupom.restauranteId),

        codigo:
            String(cupom.codigo).toUpperCase(),

        descricao:
            cupom.descricao || "",

        tipo:
            cupom.tipo || "PORCENTAGEM",

        valor:
            Number(cupom.valor) || 0,

        valorMinimo:
            Number(cupom.valorMinimo) || 0,

        limiteUso:
            Number(cupom.limiteUso) || 0,

        usos: 0,

        ativo:
            cupom.ativo !== false,

        criadoEm:
            new Date().toISOString()
    };

    await pool.query(
        `
        INSERT INTO cupons (
            id,
            restaurante_id,
            codigo,
            descricao,
            tipo,
            valor,
            valor_minimo,
            limite_uso,
            usos,
            ativo,
            criado_em,
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
            $9,
            $10,
            $11,
            $12::jsonb
        )
        ON CONFLICT (id)
        DO UPDATE SET
            restaurante_id = EXCLUDED.restaurante_id,
            codigo = EXCLUDED.codigo,
            descricao = EXCLUDED.descricao,
            tipo = EXCLUDED.tipo,
            valor = EXCLUDED.valor,
            valor_minimo = EXCLUDED.valor_minimo,
            limite_uso = EXCLUDED.limite_uso,
            usos = EXCLUDED.usos,
            ativo = EXCLUDED.ativo,
            dados = EXCLUDED.dados
        `,
        [
            novoCupom.id,
            novoCupom.restauranteId,
            novoCupom.codigo,
            novoCupom.descricao,
            novoCupom.tipo,
            novoCupom.valor,
            novoCupom.valorMinimo,
            novoCupom.limiteUso,
            novoCupom.usos,
            novoCupom.ativo,
            novoCupom.criadoEm,
            JSON.stringify(novoCupom)
        ]
    );

    return novoCupom;
}

// ======================================================
// LISTAR POR RESTAURANTE
// ======================================================

async function listar(restauranteId) {

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id,
            codigo,
            descricao,
            tipo,
            valor,
            valor_minimo,
            limite_uso,
            usos,
            ativo,
            criado_em,
            dados
        FROM cupons
        WHERE restaurante_id = $1
        ORDER BY criado_em DESC
        `,
        [
            String(restauranteId)
        ]
    );

    return resultado.rows.map(
        montarCupom
    );
}

// ======================================================
// BUSCAR POR CÓDIGO
// ======================================================

async function buscarPorCodigo(codigo) {

    if (!codigo) {
        return null;
    }

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id,
            codigo,
            descricao,
            tipo,
            valor,
            valor_minimo,
            limite_uso,
            usos,
            ativo,
            criado_em,
            dados
        FROM cupons
        WHERE UPPER(codigo) = UPPER($1)
        LIMIT 1
        `,
        [
            String(codigo)
        ]
    );

    if (
        resultado.rows.length === 0
    ) {
        return null;
    }

    return montarCupom(
        resultado.rows[0]
    );
}

// ======================================================
// BUSCAR POR ID
// ======================================================

async function buscarPorId(id) {

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id,
            codigo,
            descricao,
            tipo,
            valor,
            valor_minimo,
            limite_uso,
            usos,
            ativo,
            criado_em,
            dados
        FROM cupons
        WHERE id = $1
        LIMIT 1
        `,
        [
            String(id)
        ]
    );

    if (
        resultado.rows.length === 0
    ) {
        return null;
    }

    return montarCupom(
        resultado.rows[0]
    );
}

// ======================================================
// ATUALIZAR
// ======================================================

async function atualizar(id, dados) {

    const atual =
        await buscarPorId(id);

    if (!atual) {
        return null;
    }

    const atualizado = {

        ...atual,

        ...dados,

        id: atual.id,

        restauranteId:
            dados.restauranteId !== undefined
                ? String(dados.restauranteId)
                : atual.restauranteId,

        codigo:
            dados.codigo
                ? String(dados.codigo).toUpperCase()
                : atual.codigo
    };

    await pool.query(
        `
        UPDATE cupons
        SET
            restaurante_id = $2,
            codigo = $3,
            descricao = $4,
            tipo = $5,
            valor = $6,
            valor_minimo = $7,
            limite_uso = $8,
            usos = $9,
            ativo = $10,
            dados = $11::jsonb
        WHERE id = $1
        `,
        [
            String(id),

            atualizado.restauranteId,

            atualizado.codigo,

            atualizado.descricao || "",

            atualizado.tipo || "PORCENTAGEM",

            Number(atualizado.valor) || 0,

            Number(atualizado.valorMinimo) || 0,

            Number(atualizado.limiteUso) || 0,

            Number(atualizado.usos) || 0,

            atualizado.ativo !== false,

            JSON.stringify(atualizado)
        ]
    );

    return atualizado;
}

// ======================================================
// EXCLUIR
// ======================================================

async function excluir(id) {

    const resultado = await pool.query(
        `
        DELETE FROM cupons
        WHERE id = $1
        `,
        [
            String(id)
        ]
    );

    return resultado.rowCount > 0;
}

// ======================================================
// REGISTRAR USO
// ======================================================

async function registrarUso(id) {

    const resultado = await pool.query(
        `
        UPDATE cupons
        SET
            usos = COALESCE(usos, 0) + 1
        WHERE id = $1
        RETURNING
            id,
            restaurante_id,
            codigo,
            descricao,
            tipo,
            valor,
            valor_minimo,
            limite_uso,
            usos,
            ativo,
            criado_em,
            dados
        `,
        [
            String(id)
        ]
    );

    if (
        resultado.rows.length === 0
    ) {
        return null;
    }

    const row =
        resultado.rows[0];

    const cupom =
        montarCupom(row);

    // Mantém o contador atualizado
    // também dentro do JSONB.
    const dadosAtualizados = {
        ...(row.dados || {}),
        usos: cupom.usos
    };

    await pool.query(
        `
        UPDATE cupons
        SET dados = $2::jsonb
        WHERE id = $1
        `,
        [
            String(id),
            JSON.stringify(
                dadosAtualizados
            )
        ]
    );

    cupom.usos =
        Number(cupom.usos);

    return cupom;
}

// ======================================================
// EXPORTAR
// ======================================================

module.exports = {
    criar,
    listar,
    buscarPorCodigo,
    buscarPorId,
    atualizar,
    excluir,
    registrarUso
};