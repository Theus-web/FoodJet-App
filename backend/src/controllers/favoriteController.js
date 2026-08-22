const { db } = require("../config/database");

// ============================================================
// GARANTIR FAVORITOS
// ============================================================

function garantirFavoritos() {
    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.favoritos)) {
        db.data.favoritos = [];
    }
}

// ============================================================
// NORMALIZAR ID
// ============================================================

function normalizarId(valor) {
    if (
        valor === null ||
        valor === undefined
    ) {
        return "";
    }

    return valor.toString().trim();
}

// ============================================================
// LISTAR FAVORITOS
// ============================================================

async function listar(req, res) {
    try {
        await db.read();

        garantirFavoritos();

        const usuarioId = normalizarId(
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
            "TOTAL FAVORITOS:",
            db.data.favoritos.length
        );

        console.log(
            "========================================"
        );

        if (!usuarioId) {
            return res.status(401).json({
                erro: "Usuário não identificado.",
            });
        }

        const favoritos =
            db.data.favoritos.filter(
                (item) =>
                    normalizarId(
                        item.usuarioId
                    ) === usuarioId
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
            erro: "Erro ao listar favoritos.",
            detalhes: error.message,
        });
    }
}

// ============================================================
// SALVAR FAVORITO
// ============================================================

async function salvar(req, res) {
    try {
        await db.read();

        garantirFavoritos();

        // ------------------------------------------------------
        // USUÁRIO
        // ------------------------------------------------------

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
                erro: "Usuário não identificado.",
            });
        }

        // ------------------------------------------------------
        // RESTAURANTE
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
                erro: "ID do restaurante obrigatório.",
            });
        }

        // ------------------------------------------------------
        // VERIFICAR DUPLICADO
        // ------------------------------------------------------

        const existe =
            db.data.favoritos.find(
                (favorito) =>
                    normalizarId(
                        favorito.usuarioId
                    ) === usuarioId &&
                    normalizarId(
                        favorito.restauranteId
                    ) === restauranteId
            );

        if (existe) {

            console.log(
                "❤️ RESTAURANTE JÁ É FAVORITO"
            );

            return res.status(200).json({
                sucesso: true,
                favorito: true,
                mensagem:
                    "Restaurante já está nos favoritos.",
            });
        }

        // ------------------------------------------------------
        // CRIAR FAVORITO
        // ------------------------------------------------------

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
                    .trim() ??
                restaurante.imagem
                    ?.toString()
                    .trim() ??
                "",

            imagem:
                restaurante.imagem
                    ?.toString()
                    .trim() ??
                restaurante.logo
                    ?.toString()
                    .trim() ??
                "",

            imagemUrl:
                restaurante.imagemUrl
                    ?.toString()
                    .trim() ??
                "",

            logoBase64:
                restaurante.logoBase64
                    ?.toString()
                    .trim() ??
                "",

            criadoEm:
                new Date().toISOString(),
        };

        // ------------------------------------------------------
        // SALVAR
        // ------------------------------------------------------

        db.data.favoritos.push(
            novoFavorito
        );

        await db.write();

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
            "TOTAL FAVORITOS:",
            db.data.favoritos.length
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
                novoFavorito,
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
                error.message,
        });
    }
}

// ============================================================
// REMOVER FAVORITO
// ============================================================

async function remover(req, res) {
    try {
        await db.read();

        garantirFavoritos();

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
                    "Usuário não identificado.",
            });
        }

        if (!restauranteId) {
            return res.status(400).json({
                erro:
                    "ID do restaurante obrigatório.",
            });
        }

        const quantidadeAntes =
            db.data.favoritos.length;

        db.data.favoritos =
            db.data.favoritos.filter(
                (item) =>
                    !(
                        normalizarId(
                            item.usuarioId
                        ) === usuarioId &&
                        normalizarId(
                            item.restauranteId
                        ) === restauranteId
                    )
            );

        const quantidadeDepois =
            db.data.favoritos.length;

        await db.write();

        console.log(
            "FAVORITOS ANTES:",
            quantidadeAntes
        );

        console.log(
            "FAVORITOS DEPOIS:",
            quantidadeDepois
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
                "Favorito removido.",
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
                error.message,
        });
    }
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
    listar,
    salvar,
    remover,
};