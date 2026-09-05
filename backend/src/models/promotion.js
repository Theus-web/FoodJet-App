
const { v4: uuid } = require("uuid");
const { pool } = require("../config/database");

// ============================================================
// NORMALIZAR DADOS
// ============================================================

function normalizarDados(row) {

    if (!row) {
        return {};
    }

    if (
        row.dados &&
        typeof row.dados === "object"
    ) {
        return row.dados;
    }

    if (
        typeof row.dados === "string"
    ) {
        try {
            return JSON.parse(row.dados);
        } catch {
            return {};
        }
    }

    return {};
}


// ============================================================
// MONTAR PROMOÇÃO
// ============================================================

function montarPromocao(row) {

    if (!row) {
        return null;
    }

    const dados =
        normalizarDados(row);

    return {

        ...dados,

        id:
            row.id,

        restauranteId:
            row.restauranteId ??
            row.restaurante_id ??
            dados.restauranteId ??
            null,

        plano:
            row.plano ??
            dados.plano ??
            null,

        valor:
            Number(
                row.valor ??
                dados.valor ??
                0
            ),

        dias:
            Number(
                row.dias ??
                dados.dias ??
                0
            ),

        inicio:
            row.inicio
                ? new Date(
                    row.inicio
                ).toISOString()
                : dados.inicio ??
                  null,

        fim:
            row.fim
                ? new Date(
                    row.fim
                ).toISOString()
                : dados.fim ??
                  null,

        ativo:
            row.ativo !== null &&
            row.ativo !== undefined
                ? Boolean(row.ativo)
                : Boolean(dados.ativo),

        criadoEm:
            row.criadoEm
                ? new Date(
                    row.criadoEm
                ).toISOString()
                : dados.criadoEm ??
                  null,

    };
}


// ============================================================
// CRIAR PROMOÇÃO
// ============================================================

exports.criar = async (dados) => {

    if (
        !dados ||
        typeof dados !== "object"
    ) {
        throw new Error(
            "Dados da promoção são obrigatórios."
        );
    }


    if (!dados.restauranteId) {
        throw new Error(
            "restauranteId é obrigatório."
        );
    }


    const dias =
        Number(dados.dias || 30);


    const valor =
        Number(dados.valor || 0);


    if (
        !Number.isFinite(dias) ||
        dias <= 0
    ) {
        throw new Error(
            "Quantidade de dias inválida."
        );
    }


    if (
        !Number.isFinite(valor) ||
        valor < 0
    ) {
        throw new Error(
            "Valor da promoção inválido."
        );
    }


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


    // ========================================================
    // UUID COMO TEXT
    // ========================================================

    const promocao = {

        id:
            uuid(),

        restauranteId:
            String(
                dados.restauranteId
            ),

        plano:
            dados.plano ||
            null,

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


    // ========================================================
    // SALVAR NO POSTGRESQL
    // ========================================================

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

            restaurante_id =
                EXCLUDED.restaurante_id,

            plano =
                EXCLUDED.plano,

            valor =
                EXCLUDED.valor,

            dias =
                EXCLUDED.dias,

            inicio =
                EXCLUDED.inicio,

            fim =
                EXCLUDED.fim,

            ativo =
                EXCLUDED.ativo,

            dados =
                EXCLUDED.dados
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

            JSON.stringify(
                promocao
            ),

        ]
    );


    return promocao;
};


// ============================================================
// LISTAR TODAS
// ============================================================

exports.listar = async () => {

    const resultado =
        await pool.query(
            `
            SELECT
                id,

                restaurante_id
                    AS "restauranteId",

                plano,

                valor,

                dias,

                inicio,

                fim,

                ativo,

                criado_em
                    AS "criadoEm",

                dados

            FROM promocoes

            ORDER BY
                criado_em DESC
            `
        );


    return resultado.rows.map(
        montarPromocao
    );
};


// ============================================================
// BUSCAR PROMOÇÃO ATIVA
// ============================================================

exports.buscarAtiva =
    async (restauranteId) => {

        if (!restauranteId) {
            return null;
        }


        const resultado =
            await pool.query(
                `
                SELECT
                    id,

                    restaurante_id
                        AS "restauranteId",

                    plano,

                    valor,

                    dias,

                    inicio,

                    fim,

                    ativo,

                    criado_em
                        AS "criadoEm",

                    dados

                FROM promocoes

                WHERE restaurante_id = $1

                  AND ativo = TRUE

                  AND inicio <= NOW()

                  AND fim > NOW()

                ORDER BY
                    fim DESC

                LIMIT 1
                `,
                [
                    String(
                        restauranteId
                    ),
                ]
            );


        if (
            resultado.rowCount === 0
        ) {
            return null;
        }


        return montarPromocao(
            resultado.rows[0]
        );
    };


// ============================================================
// DESATIVAR
// ============================================================

exports.desativar =
    async (id) => {

        if (!id) {
            return null;
        }


        const resultado =
            await pool.query(
                `
                UPDATE promocoes

                SET
                    ativo = FALSE,

                    dados =
                        COALESCE(
                            dados,
                            '{}'::jsonb
                        )
                        ||
                        jsonb_build_object(
                            'ativo',
                            false
                        )

                WHERE id = $1

                RETURNING
                    id,

                    restaurante_id
                        AS "restauranteId",

                    plano,

                    valor,

                    dias,

                    inicio,

                    fim,

                    ativo,

                    criado_em
                        AS "criadoEm",

                    dados
                `,
                [
                    String(id),
                ]
            );


        if (
            resultado.rowCount === 0
        ) {
            return null;
        }


        return montarPromocao(
            resultado.rows[0]
        );
    };


// ============================================================
// EXPORTAR MONTADOR
// ============================================================

exports.montarPromocao =
    montarPromocao;

