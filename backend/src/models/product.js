const { pool } = require("../config/database");

// ============================================================
// CRIAR
// ============================================================

async function criar(produto) {

    if (!produto || typeof produto !== "object") {
        throw new Error("Dados do produto são obrigatórios.");
    }

    const id = produto.id
        ? String(produto.id)
        : String(Date.now());

    const restauranteId =
        produto.restauranteId !== undefined &&
        produto.restauranteId !== null
            ? String(produto.restauranteId)
            : null;

    const nome =
        produto.nome !== undefined &&
        produto.nome !== null
            ? String(produto.nome)
            : null;

    const descricao =
        produto.descricao !== undefined &&
        produto.descricao !== null
            ? String(produto.descricao)
            : null;

    const preco =
        produto.preco !== undefined &&
        produto.preco !== null
            ? Number(produto.preco)
            : 0;

    const categoria =
        produto.categoria !== undefined &&
        produto.categoria !== null
            ? String(produto.categoria)
            : null;

    const imagem =
        produto.imagem !== undefined &&
        produto.imagem !== null
            ? produto.imagem
            : null;

    const disponivel =
        produto.disponivel !== undefined
            ? Boolean(produto.disponivel)
            : true;

    const destaque =
        produto.destaque !== undefined
            ? Boolean(produto.destaque)
            : false;

    const criadoEm =
        produto.criadoEm
            ? new Date(produto.criadoEm)
            : new Date();

    const atualizadoEm =
        produto.atualizadoEm
            ? new Date(produto.atualizadoEm)
            : new Date();

    const dados = {
        ...produto,
        id,
        restauranteId,
        nome,
        descricao,
        preco,
        categoria,
        imagem,
        disponivel,
        destaque,
        criadoEm: criadoEm.toISOString(),
        atualizadoEm: atualizadoEm.toISOString(),
    };

    const resultado = await pool.query(
        `
        INSERT INTO produtos (
            id,
            restaurante_id,
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
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
            $11
        )
        RETURNING
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        `,
        [
            id,
            restauranteId,
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criadoEm,
            dados,
        ]
    );

    const novoProduto = montarProduto(resultado.rows[0]);

    console.log("🍕 PRODUTO CRIADO:", novoProduto.id);

    return novoProduto;
}

// ============================================================
// LISTAR
// ============================================================

async function listar() {

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        FROM produtos
        ORDER BY criado_em ASC NULLS LAST
        `
    );

    return resultado.rows.map(montarProduto);
}

// ============================================================
// BUSCAR POR ID
// ============================================================

async function buscarPorId(id) {

    if (
        id === undefined ||
        id === null ||
        String(id).trim() === ""
    ) {
        return null;
    }

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        FROM produtos
        WHERE id = $1
        LIMIT 1
        `,
        [String(id)]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarProduto(resultado.rows[0]);
}

// ============================================================
// ATUALIZAR
// ============================================================

async function atualizar(id, dados) {

    const produto = await buscarPorId(id);

    if (!produto) {
        return null;
    }

    if (!dados || typeof dados !== "object") {
        return produto;
    }

    const produtoAtualizado = {
        ...produto,
        ...dados,
        id: produto.id,
    };

    const atualizadoEm = new Date();

    produtoAtualizado.atualizadoEm =
        atualizadoEm.toISOString();

    const restauranteId =
        produtoAtualizado.restauranteId !== undefined &&
        produtoAtualizado.restauranteId !== null
            ? String(produtoAtualizado.restauranteId)
            : null;

    const nome =
        produtoAtualizado.nome !== undefined &&
        produtoAtualizado.nome !== null
            ? String(produtoAtualizado.nome)
            : null;

    const descricao =
        produtoAtualizado.descricao !== undefined &&
        produtoAtualizado.descricao !== null
            ? String(produtoAtualizado.descricao)
            : null;

    const preco =
        produtoAtualizado.preco !== undefined &&
        produtoAtualizado.preco !== null
            ? Number(produtoAtualizado.preco)
            : 0;

    const categoria =
        produtoAtualizado.categoria !== undefined &&
        produtoAtualizado.categoria !== null
            ? String(produtoAtualizado.categoria)
            : null;

    const imagem =
        produtoAtualizado.imagem !== undefined
            ? produtoAtualizado.imagem
            : null;

    const disponivel =
        produtoAtualizado.disponivel !== undefined
            ? Boolean(produtoAtualizado.disponivel)
            : true;

    const destaque =
        produtoAtualizado.destaque !== undefined
            ? Boolean(produtoAtualizado.destaque)
            : false;

    const dadosAtualizados = {
        ...(produto.dados || {}),
        ...produtoAtualizado,

        id: produto.id,
        restauranteId,
        nome,
        descricao,
        preco,
        categoria,
        imagem,
        disponivel,
        destaque,
        atualizadoEm: atualizadoEm.toISOString(),
    };

    const resultado = await pool.query(
        `
        UPDATE produtos
        SET
            restaurante_id = $1,
            nome = $2,
            descricao = $3,
            preco = $4,
            categoria = $5,
            imagem = $6,
            disponivel = $7,
            destaque = $8,
            dados = $9
        WHERE id = $10
        RETURNING
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        `,
        [
            restauranteId,
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            dadosAtualizados,
            String(id),
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarProduto(resultado.rows[0]);
}

// ============================================================
// ATUALIZAR IMAGEM
// ============================================================

async function atualizarImagem(id, imagem) {

    const produto = await buscarPorId(id);

    if (!produto) {
        return null;
    }

    const atualizadoEm = new Date();

    const dadosAtualizados = {
        ...(produto.dados || {}),
        imagem,
        atualizadoEm: atualizadoEm.toISOString(),
    };

    const resultado = await pool.query(
        `
        UPDATE produtos
        SET
            imagem = $1,
            dados = $2
        WHERE id = $3
        RETURNING
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        `,
        [
            imagem,
            dadosAtualizados,
            String(id),
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarProduto(resultado.rows[0]);
}

// ============================================================
// DISPONIBILIDADE
// ============================================================

async function atualizarDisponibilidade(id, disponivel) {

    const produto = await buscarPorId(id);

    if (!produto) {
        return null;
    }

    const novaDisponibilidade = Boolean(disponivel);
    const atualizadoEm = new Date();

    const dadosAtualizados = {
        ...(produto.dados || {}),
        disponivel: novaDisponibilidade,
        atualizadoEm: atualizadoEm.toISOString(),
    };

    const resultado = await pool.query(
        `
        UPDATE produtos
        SET
            disponivel = $1,
            dados = $2
        WHERE id = $3
        RETURNING
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        `,
        [
            novaDisponibilidade,
            dadosAtualizados,
            String(id),
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarProduto(resultado.rows[0]);
}

// ============================================================
// ATUALIZAR DESTAQUE
// ============================================================

async function atualizarDestaque(id, destaque) {

    const produto = await buscarPorId(id);

    if (!produto) {
        return null;
    }

    const novoDestaque = Boolean(destaque);
    const atualizadoEm = new Date();

    const dadosAtualizados = {
        ...(produto.dados || {}),
        destaque: novoDestaque,
        atualizadoEm: atualizadoEm.toISOString(),
    };

    const resultado = await pool.query(
        `
        UPDATE produtos
        SET
            destaque = $1,
            dados = $2
        WHERE id = $3
        RETURNING
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        `,
        [
            novoDestaque,
            dadosAtualizados,
            String(id),
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarProduto(resultado.rows[0]);
}

// ============================================================
// EXCLUIR
// ============================================================

async function excluir(id) {

    const resultado = await pool.query(
        `
        DELETE FROM produtos
        WHERE id = $1
        RETURNING
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        `,
        [String(id)]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarProduto(resultado.rows[0]);
}

// ============================================================
// LISTAR POR RESTAURANTE
// ============================================================

async function listarPorRestaurante(restauranteId) {

    if (
        restauranteId === undefined ||
        restauranteId === null ||
        String(restauranteId).trim() === ""
    ) {
        return [];
    }

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        FROM produtos
        WHERE restaurante_id = $1
        ORDER BY criado_em ASC NULLS LAST
        `,
        [String(restauranteId)]
    );

    return resultado.rows.map(montarProduto);
}

// ============================================================
// BUSCAR POR CATEGORIA
// ============================================================

async function listarPorCategoria(restauranteId, categoria) {

    if (
        restauranteId === undefined ||
        restauranteId === null ||
        String(restauranteId).trim() === ""
    ) {
        return [];
    }

    const resultado = await pool.query(
        `
        SELECT
            id,
            restaurante_id AS "restauranteId",
            nome,
            descricao,
            preco,
            categoria,
            imagem,
            disponivel,
            destaque,
            criado_em AS "criadoEm",
            dados
        FROM produtos
        WHERE restaurante_id = $1
          AND categoria = $2
        ORDER BY criado_em ASC NULLS LAST
        `,
        [
            String(restauranteId),
            categoria,
        ]
    );

    return resultado.rows.map(montarProduto);
}

// ============================================================
// CONTAR PRODUTOS
// ============================================================

async function contar(restauranteId) {

    if (
        restauranteId === undefined ||
        restauranteId === null ||
        String(restauranteId).trim() === ""
    ) {
        return 0;
    }

    const resultado = await pool.query(
        `
        SELECT COUNT(*)::int AS total
        FROM produtos
        WHERE restaurante_id = $1
        `,
        [String(restauranteId)]
    );

    return resultado.rows[0].total;
}

// ============================================================
// MONTAR PRODUTO
// ============================================================

function montarProduto(row) {

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
            row.restauranteId,

        nome:
            row.nome,

        descricao:
            row.descricao,

        preco:
            row.preco !== null
                ? Number(row.preco)
                : 0,

        categoria:
            row.categoria,

        imagem:
            row.imagem,

        disponivel:
            row.disponivel,

        destaque:
            row.destaque,

        criadoEm:
            row.criadoEm
                ? new Date(row.criadoEm).toISOString()
                : null,

        atualizadoEm:
            dados.atualizadoEm || null,
    };
}

// ============================================================
// EXPORTAÇÕES
// ============================================================

module.exports = {

    criar,

    listar,

    buscarPorId,

    atualizar,

    atualizarImagem,

    atualizarDisponibilidade,

    atualizarDestaque,

    excluir,

    listarPorRestaurante,

    listarPorCategoria,

    contar,
};