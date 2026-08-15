const { db } = require("../config/database");

// ============================================================
// CRIAR
// ============================================================

async function criar(produto) {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
    }

    db.data.produtos.push(produto);

    await db.write();

    return produto;
}

// ============================================================
// LISTAR
// ============================================================

async function listar() {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
        await db.write();
    }

    return db.data.produtos;
}

// ============================================================
// BUSCAR POR ID
// ============================================================

async function buscarPorId(id) {
    await db.read();

    if (!db.data.produtos) {
        return null;
    }

    return db.data.produtos.find(
        (produto) =>
            produto.id.toString() === id.toString()
    ) || null;
}

// ============================================================
// ATUALIZAR
// ============================================================

async function atualizar(id, dados) {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
    }

    const indice =
        db.data.produtos.findIndex(
            (produto) =>
                produto.id.toString() ===
                id.toString()
        );

    if (indice === -1) {
        return null;
    }

    db.data.produtos[indice] = {
        ...db.data.produtos[indice],
        ...dados,
        id: db.data.produtos[indice].id,
    };

    await db.write();

    return db.data.produtos[indice];
}

// ============================================================
// ATUALIZAR IMAGEM
// ============================================================

async function atualizarImagem(id, imagem) {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
    }

    const indice =
        db.data.produtos.findIndex(
            (produto) =>
                produto.id.toString() ===
                id.toString()
        );

    if (indice === -1) {
        return null;
    }

    db.data.produtos[indice].imagem = imagem;

    await db.write();

    return db.data.produtos[indice];
}

// ============================================================
// DISPONIBILIDADE
// ============================================================

async function atualizarDisponibilidade(
    id,
    disponivel
) {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
    }

    const indice =
        db.data.produtos.findIndex(
            (produto) =>
                produto.id.toString() ===
                id.toString()
        );

    if (indice === -1) {
        return null;
    }

    db.data.produtos[indice].disponivel =
        Boolean(disponivel);

    await db.write();

    return db.data.produtos[indice];
}

// ============================================================
// EXCLUIR
// ============================================================

async function excluir(id) {
    await db.read();

    if (!db.data.produtos) {
        return null;
    }

    const indice =
        db.data.produtos.findIndex(
            (produto) =>
                produto.id.toString() ===
                id.toString()
        );

    if (indice === -1) {
        return null;
    }

    const removido =
        db.data.produtos.splice(
            indice,
            1
        )[0];

    await db.write();

    return removido;
}

module.exports = {
    criar,
    listar,
    buscarPorId,
    atualizar,
    atualizarImagem,
    atualizarDisponibilidade,
    excluir,
};

// ============================================================
// LISTAR POR RESTAURANTE
// ============================================================

async function listarPorRestaurante(restauranteId) {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
    }

    return db.data.produtos.filter(
        (produto) =>
            Number(produto.restauranteId) ===
            Number(restauranteId)
    );
}

// ============================================================
// BUSCAR POR CATEGORIA
// ============================================================

async function listarPorCategoria(
    restauranteId,
    categoria
) {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
    }

    return db.data.produtos.filter(
        (produto) =>
            Number(produto.restauranteId) ===
                Number(restauranteId) &&
            produto.categoria === categoria
    );
}

// ============================================================
// CONTAR PRODUTOS
// ============================================================

async function contar(restauranteId) {
    await db.read();

    if (!db.data.produtos) {
        db.data.produtos = [];
    }

    return db.data.produtos.filter(
        (produto) =>
            Number(produto.restauranteId) ===
            Number(restauranteId)
    ).length;
}

async function atualizarDestaque(
    id,
    destaque
) {

    await db.read();

    const indice =
        db.data.produtos.findIndex(

            p =>
            p.id.toString() ===
            id.toString()

        );

    if(indice == -1){

        return null;

    }

    db.data.produtos[indice].destaque =
        destaque;

    await db.write();

    return db.data.produtos[indice];

}

module.exports = {

    criar,
    listar,
    buscarPorId,
    atualizar,
    atualizarImagem,
    atualizarDisponibilidade,
    atualizarDestaque,
    excluir

};