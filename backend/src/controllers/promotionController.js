const { v4: uuid } = require("uuid");
const { pool } = require("../config/database");


// ======================================================
// GARANTIR TABELA
// ======================================================

async function garantirEstrutura() {

    await pool.query(`
        CREATE TABLE IF NOT EXISTS promocoes (
            id TEXT PRIMARY KEY,

            restaurante_id TEXT NOT NULL,

            produto_id TEXT,

            titulo TEXT,

            descricao TEXT DEFAULT '',

            preco_original NUMERIC(12,2) DEFAULT 0,

            preco_promocional NUMERIC(12,2) DEFAULT 0,

            desconto NUMERIC(12,2) DEFAULT 0,

            inicio TIMESTAMPTZ,

            fim TIMESTAMPTZ,

            ativa BOOLEAN DEFAULT TRUE,

            criado_em TIMESTAMPTZ DEFAULT NOW(),

            dados JSONB DEFAULT '{}'::jsonb
        )
    `);


    await pool.query(`
        CREATE INDEX IF NOT EXISTS idx_promocoes_restaurante
        ON promocoes(restaurante_id)
    `);


    await pool.query(`
        CREATE INDEX IF NOT EXISTS idx_promocoes_ativa
        ON promocoes(ativa)
    `);
}


// ======================================================
// MONTAR PROMOÇÃO
// ======================================================

function montarPromocao(row) {

    if (!row) {
        return null;
    }


    let dados = {};

    if (row.dados) {

        try {

            dados =
                typeof row.dados === "string"
                    ? JSON.parse(row.dados)
                    : row.dados;

        } catch {

            dados = {};

        }
    }


    return {

        ...dados,

        id:
            row.id,

        restauranteId:
            row.restaurante_id !== null &&
            row.restaurante_id !== undefined
                ? String(row.restaurante_id)
                : dados.restauranteId,

        produtoId:
            row.produto_id ??
            dados.produtoId ??
            null,

        titulo:
            row.titulo ??
            dados.titulo,

        descricao:
            row.descricao ??
            dados.descricao ??
            "",

        precoOriginal:
            Number(
                row.preco_original ??
                dados.precoOriginal ??
                0
            ),

        precoPromocional:
            Number(
                row.preco_promocional ??
                dados.precoPromocional ??
                0
            ),

        desconto:
            Number(
                row.desconto ??
                dados.desconto ??
                0
            ),

        inicio:
            row.inicio
                ? new Date(row.inicio).toISOString()
                : dados.inicio ?? null,

        fim:
            row.fim
                ? new Date(row.fim).toISOString()
                : dados.fim ?? null,

        ativa:
            row.ativa !== null &&
            row.ativa !== undefined
                ? Boolean(row.ativa)
                : Boolean(dados.ativa),

        criadoEm:
            row.criado_em
                ? new Date(row.criado_em).toISOString()
                : dados.criadoEm

    };
}


// ======================================================
// CRIAR PROMOÇÃO
// POST /api/promocoes
// ======================================================

exports.create = async (req, res) => {

    try {

        await garantirEstrutura();


        const promocao = {

            id:
                uuid(),

            restauranteId:
                req.body.restauranteId,

            produtoId:
                req.body.produtoId || null,

            titulo:
                req.body.titulo,

            descricao:
                req.body.descricao || "",

            precoOriginal:
                Number(
                    req.body.precoOriginal || 0
                ),

            precoPromocional:
                Number(
                    req.body.precoPromocional || 0
                ),

            desconto:
                Number(
                    req.body.desconto || 0
                ),

            inicio:
                req.body.inicio || null,

            fim:
                req.body.fim || null,

            ativa:
                true,

            criadoEm:
                new Date().toISOString()

        };


        // ==================================================
        // VALIDAR RESTAURANTE
        // ==================================================

        if (
            !promocao.restauranteId
        ) {

            return res.status(400).json({

                erro:
                    "restauranteId obrigatório"

            });
        }


        // ==================================================
        // SALVAR NO POSTGRESQL
        // ==================================================

        await pool.query(
            `
            INSERT INTO promocoes (
                id,
                restaurante_id,
                produto_id,
                titulo,
                descricao,
                preco_original,
                preco_promocional,
                desconto,
                inicio,
                fim,
                ativa,
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
                $12,
                $13::jsonb
            )
            `,
            [
                promocao.id,

                String(
                    promocao.restauranteId
                ),

                promocao.produtoId
                    ? String(
                        promocao.produtoId
                    )
                    : null,

                promocao.titulo,

                promocao.descricao,

                promocao.precoOriginal,

                promocao.precoPromocional,

                promocao.desconto,

                promocao.inicio,

                promocao.fim,

                promocao.ativa,

                promocao.criadoEm,

                JSON.stringify(
                    promocao
                )
            ]
        );


        return res.status(201).json(
            promocao
        );


    } catch (error) {

        console.error(
            "ERRO AO CRIAR PROMOÇÃO:",
            error
        );


        return res.status(500).json({

            erro:
                "Erro ao criar promoção"

        });
    }
};


// ======================================================
// LISTAR PROMOÇÕES DO RESTAURANTE
// GET /api/promocoes/restaurante/:id
// ======================================================

exports.listarRestaurante =
    async (req, res) => {

        try {

            await garantirEstrutura();


            const id =
                String(
                    req.params.id
                );


            const resultado =
                await pool.query(
                    `
                    SELECT
                        id,
                        restaurante_id,
                        produto_id,
                        titulo,
                        descricao,
                        preco_original,
                        preco_promocional,
                        desconto,
                        inicio,
                        fim,
                        ativa,
                        criado_em,
                        dados
                    FROM promocoes
                    WHERE restaurante_id = $1
                    ORDER BY criado_em DESC
                    `,
                    [id]
                );


            const promocoes =
                resultado.rows.map(
                    montarPromocao
                );


            return res.json(
                promocoes
            );


        } catch (error) {

            console.error(
                "ERRO AO BUSCAR PROMOÇÕES:",
                error
            );


            return res.status(500).json({

                erro:
                    "Erro ao buscar promoções"

            });
        }
    };


// ======================================================
// LISTAR PROMOÇÕES ATIVAS CLIENTE
// GET /api/promocoes
// ======================================================

exports.listarAtivas =
    async (req, res) => {

        try {

            await garantirEstrutura();


            const hoje =
                new Date();


            const resultado =
                await pool.query(
                    `
                    SELECT
                        id,
                        restaurante_id,
                        produto_id,
                        titulo,
                        descricao,
                        preco_original,
                        preco_promocional,
                        desconto,
                        inicio,
                        fim,
                        ativa,
                        criado_em,
                        dados
                    FROM promocoes

                    WHERE ativa = TRUE

                    AND (
                        inicio IS NULL
                        OR inicio <= $1
                    )

                    AND (
                        fim IS NULL
                        OR fim >= $1
                    )

                    ORDER BY criado_em DESC
                    `,
                    [hoje]
                );


            const promocoes =
                resultado.rows.map(
                    montarPromocao
                );


            return res.json(
                promocoes
            );


        } catch (error) {

            console.error(
                "ERRO AO BUSCAR PROMOÇÕES ATIVAS:",
                error
            );


            return res.status(500).json({

                erro:
                    "Erro ao buscar promoções"

            });
        }
    };


// ======================================================
// ATIVAR / DESATIVAR
// PUT /api/promocoes/:id/status
// ======================================================

exports.status =
    async (req, res) => {

        try {

            await garantirEstrutura();


            const id =
                String(
                    req.params.id
                );


            // ==================================================
            // BUSCAR
            // ==================================================

            const existente =
                await pool.query(
                    `
                    SELECT
                        id,
                        restaurante_id,
                        produto_id,
                        titulo,
                        descricao,
                        preco_original,
                        preco_promocional,
                        desconto,
                        inicio,
                        fim,
                        ativa,
                        criado_em,
                        dados
                    FROM promocoes
                    WHERE id = $1
                    LIMIT 1
                    `,
                    [id]
                );


            if (
                existente.rows.length === 0
            ) {

                return res.status(404).json({

                    erro:
                        "Promoção não encontrada"

                });
            }


            // ==================================================
            // NOVO STATUS
            // ==================================================

            const ativa =
                Boolean(
                    req.body.ativa
                );


            const resultado =
                await pool.query(
                    `
                    UPDATE promocoes

                    SET
                        ativa = $1,

                        dados =
                            COALESCE(
                                dados,
                                '{}'::jsonb
                            )
                            ||
                            jsonb_build_object(
                                'ativa',
                                $1
                            )

                    WHERE id = $2

                    RETURNING
                        id,
                        restaurante_id,
                        produto_id,
                        titulo,
                        descricao,
                        preco_original,
                        preco_promocional,
                        desconto,
                        inicio,
                        fim,
                        ativa,
                        criado_em,
                        dados
                    `,
                    [
                        ativa,
                        id
                    ]
                );


            const promocao =
                montarPromocao(
                    resultado.rows[0]
                );


            return res.json(
                promocao
            );


        } catch (error) {

            console.error(
                "ERRO AO ATUALIZAR PROMOÇÃO:",
                error
            );


            return res.status(500).json({

                erro:
                    "Erro atualizar promoção"

            });
        }
    };


// ======================================================
// EXCLUIR
// DELETE /api/promocoes/:id
// ======================================================

exports.delete =
    async (req, res) => {

        try {

            await garantirEstrutura();


            const id =
                String(
                    req.params.id
                );


            const resultado =
                await pool.query(
                    `
                    DELETE FROM promocoes
                    WHERE id = $1
                    RETURNING id
                    `,
                    [id]
                );


            if (
                resultado.rows.length === 0
            ) {

                return res.status(404).json({

                    erro:
                        "Promoção não encontrada"

                });
            }


            return res.json({

                sucesso:
                    true

            });


        } catch (error) {

            console.error(
                "ERRO AO EXCLUIR PROMOÇÃO:",
                error
            );


            return res.status(500).json({

                erro:
                    "Erro excluir promoção"

            });
        }
    };