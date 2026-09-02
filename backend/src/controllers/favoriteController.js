const { pool } = require("../config/database");

// ============================================================
// NORMALIZAR ID
// ============================================================

function normalizarId(valor) {
    if (valor === null || valor === undefined) {
        return "";
    }

    return valor.toString().trim();
}

// ============================================================
// MONTAR FAVORITO
// ============================================================

function montarFavorito(row) {
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

        usuarioId:
            row.usuario_id,

        restauranteId:
            row.restaurante_id,

        criadoEm:
            row.criado_em
                ? new Date(row.criado_em).toISOString()
                : dados.criadoEm
    };
}

// ============================================================
// LISTAR FAVORITOS
// ============================================================

async function listar(req, res) {

    try {

        const usuarioId =
            normalizarId(
                req.usuario?.id ??
                req.usuario?._id ??
                req.usuario?.usuarioId
            );

        console.log(
            "========================================"
        );

        console.log(
            "❤️ FOODJET - LISTAR FAVORITOS"
        );

        console.log(
            "USUÁRIO:",
            usuarioId
        );

        console.log(
            "========================================"
        );

        if (!usuarioId) {

            return res.status(401).json({
                erro:
                    "Usuário não identificado."
            });
        }

        const resultado =
            await pool.query(
                `
                SELECT
                    id,
                    usuario_id,
                    restaurante_id,
                    criado_em,
                    dados
                FROM favoritos
                WHERE usuario_id = $1
                ORDER BY criado_em DESC
                `,
                [usuarioId]
            );

        const favoritos =
            resultado.rows.map(
                montarFavorito
            );

        console.log(
            "TOTAL FAVORITOS:",
            favoritos.length
        );

        return res.status(200).json(
            favoritos
        );

    } catch (error) {

        console.error(
            "❌ ERRO AO LISTAR FAVORITOS:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro ao listar favoritos.",
            detalhes:
                error.message
        });
    }
}

// ============================================================
// SALVAR FAVORITO
// ============================================================

async function salvar(req, res) {

    try {

        const usuarioId =
            normalizarId(
                req.usuario?.id ??
                req.usuario?._id ??
                req.usuario?.usuarioId
            );

        console.log(
            "========================================"
        );

        console.log(
            "❤️ FOODJET - SALVAR FAVORITO"
        );

        console.log(
            "USUÁRIO:",
            usuarioId
        );

        console.log(
            "BODY:",
            JSON.stringify(req.body)
        );

        // ------------------------------------------------------
        // VERIFICAR USUÁRIO
        // ------------------------------------------------------

        if (!usuarioId) {

            return res.status(401).json({
                erro:
                    "Usuário não identificado."
            });
        }

        // ------------------------------------------------------
        // DADOS DO RESTAURANTE
        // ------------------------------------------------------

        const restaurante =
            req.body || {};

        const restauranteId =
            normalizarId(
                restaurante.restauranteId ??
                restaurante.restaurantId ??
                restaurante.id ??
                restaurante._id
            );

        console.log(
            "RESTAURANTE ID:",
            restauranteId
        );

        // ------------------------------------------------------
        // VERIFICAR ID
        // ------------------------------------------------------

        if (!restauranteId) {

            return res.status(400).json({
                erro:
                    "ID do restaurante obrigatório."
            });
        }

        // ------------------------------------------------------
        // VERIFICAR DUPLICADO
        // ------------------------------------------------------

        const existe =
            await pool.query(
                `
                SELECT
                    id
                FROM favoritos
                WHERE usuario_id = $1
                  AND restaurante_id = $2
                LIMIT 1
                `,
                [
                    usuarioId,
                    restauranteId
                ]
            );

        if (
            existe.rows.length > 0
        ) {

            console.log(
                "❤️ RESTAURANTE JÁ É FAVORITO"
            );

            return res.status(200).json({
                sucesso: true,
                favorito: true,
                mensagem:
                    "Restaurante já está nos favoritos."
            });
        }

        // ------------------------------------------------------
        // CRIAR ID
        // ------------------------------------------------------

        const agora =
            new Date().toISOString();

        const novoFavorito = {

            id:
                `${usuarioId}_${restauranteId}`,

            usuarioId:
                usuarioId,

            restauranteId:
                restauranteId,

            nome:
                restaurante.nome
                    ?.toString()
                    .trim() ?? "",

            descricao:
                restaurante.descricao
                    ?.toString()
                    .trim() ?? "",

            avaliacao:
                restaurante.avaliacao
                    ?.toString()
                    .trim() || "5.0",

            logo:
                restaurante.logo
                    ?.toString()
                    .trim() ||
                restaurante.imagem
                    ?.toString()
                    .trim() ||
                "",

            imagem:
                restaurante.imagem
                    ?.toString()
                    .trim() ||
                restaurante.logo
                    ?.toString()
                    .trim() ||
                "",

            imagemUrl:
                restaurante.imagemUrl
                    ?.toString()
                    .trim() || "",

            logoBase64:
                restaurante.logoBase64
                    ?.toString()
                    .trim() || "",

            criadoEm:
                agora
        };

        // ------------------------------------------------------
        // SALVAR NO POSTGRESQL
        // ------------------------------------------------------

        await pool.query(
            `
            INSERT INTO favoritos (
                id,
                usuario_id,
                restaurante_id,
                criado_em,
                dados
            )
            VALUES (
                $1,
                $2,
                $3,
                $4,
                $5::jsonb
            )
            ON CONFLICT (id)
            DO UPDATE SET
                dados = EXCLUDED.dados
            `,
            [
                novoFavorito.id,

                novoFavorito.usuarioId,

                novoFavorito.restauranteId,

                novoFavorito.criadoEm,

                JSON.stringify(
                    novoFavorito
                )
            ]
        );

        console.log(
            "❤️ FAVORITO SALVO COM SUCESSO"
        );

        console.log(
            "FAVORITO:",
            JSON.stringify(
                novoFavorito,
                null,
                2
            )
        );

        console.log(
            "========================================"
        );

        return res.status(201).json({
            sucesso: true,
            favorito: true,
            mensagem:
                "Favorito salvo com sucesso.",
            dados:
                novoFavorito
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO SALVAR FAVORITO:"
        );

        console.error(error);

        return res.status(500).json({
            erro:
                "Erro ao salvar favorito.",
            detalhes:
                error.message
        });
    }
}

// ============================================================
// REMOVER FAVORITO
// ============================================================

async function remover(req, res) {

    try {

        const usuarioId =
            normalizarId(
                req.usuario?.id ??
                req.usuario?._id ??
                req.usuario?.usuarioId
            );

        const restauranteId =
            normalizarId(
                req.params.restauranteId
            );

        console.log(
            "========================================"
        );

        console.log(
            "🤍 FOODJET - REMOVER FAVORITO"
        );

        console.log(
            "USUÁRIO:",
            usuarioId
        );

        console.log(
            "RESTAURANTE:",
            restauranteId
        );

        if (!usuarioId) {

            return res.status(401).json({
                erro:
                    "Usuário não identificado."
            });
        }

        if (!restauranteId) {

            return res.status(400).json({
                erro:
                    "ID do restaurante obrigatório."
            });
        }

        const resultado =
            await pool.query(
                `
                DELETE FROM favoritos
                WHERE usuario_id = $1
                  AND restaurante_id = $2
                `,
                [
                    usuarioId,
                    restauranteId
                ]
            );

        console.log(
            "FAVORITOS REMOVIDOS:",
            resultado.rowCount
        );

        console.log(
            "🤍 FAVORITO REMOVIDO"
        );

        console.log(
            "========================================"
        );

        return res.status(200).json({
            sucesso: true,
            favorito: false,
            mensagem:
                "Favorito removido."
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO REMOVER FAVORITO:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro ao remover favorito.",
            detalhes:
                error.message
        });
    }
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
    listar,
    salvar,
    remover
};