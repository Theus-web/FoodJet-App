const { pool } = require("../config/database");

// ============================================================
// CRIAR PROMOÇÃO
// ============================================================

exports.criar = async (dados) => {

    if (!dados || typeof dados !== "object") {
        throw new Error("Dados da promoção são obrigatórios.");
    }

    if (!dados.restauranteId) {
        throw new Error("restauranteId é obrigatório.");
    }

    const dias =
        Number(dados.dias || 30);

    const valor =
        Number(dados.valor || 0);

    const inicio =
        new Date();

    const fim =
        new Date(
            inicio.getTime() +
            (
                dias *
                24 *
                60 *
                60 *
                1000
            )
        );

    const promocao = {

        id: Date.now(),

        restauranteId:
            String(dados.restauranteId),

        plano:
            dados.plano || null,

        valor,

        dias,

        inicio:
            inicio.toISOString(),

        fim:
            fim.toISOString(),

        ativo:
            true,

        criadoEm:
            inicio.toISOString(),

    };

    await pool.query(
        `
        INSERT INTO promocoes (
            id,
            restaurante_id,
            plano,
            valor,
            dias,
            inicio,
            fim,
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
            $10::jsonb
        )
        ON CONFLICT (id)
        DO UPDATE SET
            restaurante_id = EXCLUDED.restaurante_id,
            plano = EXCLUDED.plano,
            valor = EXCLUDED.valor,
            dias = EXCLUDED.dias,
            inicio = EXCLUDED.inicio,
            fim = EXCLUDED.fim,
            ativo = EXCLUDED.ativo,
            dados = EXCLUDED.dados
        `,
        [
            promocao.id,
            promocao.restauranteId,
            promocao.plano,
            promocao.valor,
            promocao.dias,
            promocao.inicio,
            promocao.fim,
            promocao.ativo,
            promocao.criadoEm,
            JSON.stringify(promocao),
        ]
    );

    return promocao;
};

// ============================================================
// LISTAR
// ============================================================

exports.listar = async () => {

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id AS "restauranteId",
            plano,
            valor,
            dias,
            inicio,
            fim,
            ativo,
            criado_em AS "criadoEm",
            dados
        FROM promocoes
        ORDER BY criado_em DESC
        `
    );

    return resultado.rows.map((row) => {

        const dados =
            row.dados &&
            typeof row.dados === "object"
                ? row.dados
                : {};

        return {
            ...dados,

            id: row.id,
            restauranteId: row.restauranteId,
            plano: row.plano,
            valor: Number(row.valor || 0),
            dias: Number(row.dias || 0),
            inicio: row.inicio,
            fim: row.fim,
            ativo: row.ativo,
            criadoEm: row.criadoEm,
        };

    });
};

// ============================================================
// BUSCAR PROMOÇÃO ATIVA POR RESTAURANTE
// ============================================================

exports.buscarAtiva = async (restauranteId) => {

    if (!restauranteId) {
        return null;
    }

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id AS "restauranteId",
            plano,
            valor,
            dias,
            inicio,
            fim,
            ativo,
            criado_em AS "criadoEm",
            dados
        FROM promocoes
        WHERE restaurante_id = $1
          AND ativo = TRUE
          AND fim > NOW()
        ORDER BY fim DESC
        LIMIT 1
        `,
        [
            String(restauranteId),
        ]
    );

    if (resultado.rowCount === 0) {
        return null;
    }

    const row =
        resultado.rows[0];

    const dados =
        row.dados &&
        typeof row.dados === "object"
            ? row.dados
            : {};

    return {

        ...dados,

        id:
            row.id,

        restauranteId:
            row.restauranteId,

        plano:
            row.plano,

        valor:
            Number(row.valor || 0),

        dias:
            Number(row.dias || 0),

        inicio:
            row.inicio,

        fim:
            row.fim,

        ativo:
            row.ativo,

        criadoEm:
            row.criadoEm,

    };
};

// ============================================================
// DESATIVAR
// ============================================================

exports.desativar = async (id) => {

    if (!id) {
        return null;
    }

    const resultado = await pool.query(
        `
        UPDATE promocoes
        SET
            ativo = FALSE,
            dados = COALESCE(dados, '{}'::jsonb) ||
                    jsonb_build_object(
                        'ativo',
                        false
                    )
        WHERE id = $1
        RETURNING
            id,
            restaurante_id AS "restauranteId",
            plano,
            valor,
            dias,
            inicio,
            fim,
            ativo,
            criado_em AS "criadoEm",
            dados
        `,
        [
            Number(id),
        ]
    );

    if (resultado.rowCount === 0) {
        return null;
    }

    const row =
        resultado.rows[0];

    const dados =
        row.dados &&
        typeof row.dados === "object"
            ? row.dados
            : {};

    return {

        ...dados,

        id:
            row.id,

        restauranteId:
            row.restauranteId,

        plano:
            row.plano,

        valor:
            Number(row.valor || 0),

        dias:
            Number(row.dias || 0),

        inicio:
            row.inicio,

        fim:
            row.fim,

        ativo:
            row.ativo,

        criadoEm:
            row.criadoEm,

    };
};