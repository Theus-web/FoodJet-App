const { db } = require("../config/database");

// ============================================================
// GARANTIR ESTRUTURA DO BANCO
// ============================================================

async function prepararBanco() {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    db.data.usuarios ||= [];
    db.data.restaurantes ||= [];
    db.data.produtos ||= [];
    db.data.pedidos ||= [];
    db.data.entregadores ||= [];
    db.data.pagamentos ||= [];

    await db.write();
}

// ============================================================
// CRIAR RESTAURANTE
// ============================================================

exports.criar = async (restaurante) => {

    await prepararBanco();

    if (!restaurante || typeof restaurante !== "object") {
        throw new Error(
            "Dados do restaurante são obrigatórios."
        );
    }

    if (!restaurante.id) {
        restaurante.id = `rest_${Date.now()}`;
    }

    db.data.restaurantes.push(restaurante);

    await db.write();

    console.log(
        "🏪 RESTAURANTE CRIADO:",
        restaurante.id
    );

    return restaurante;
};

// ============================================================
// LISTAR RESTAURANTES
// ============================================================

exports.listar = async () => {

    await prepararBanco();

    return db.data.restaurantes;
};

// ============================================================
// BUSCAR POR ID
// ============================================================

exports.buscarPorId = async (id) => {

    await prepararBanco();

    if (
        id === undefined ||
        id === null ||
        String(id).trim() === ""
    ) {
        return null;
    }

    const restaurante =
        db.data.restaurantes.find(
            restaurante =>
                restaurante &&
                String(restaurante.id) ===
                String(id)
        );

    return restaurante || null;
};

// ============================================================
// ATUALIZAR STATUS
// ============================================================

exports.atualizarStatus = async (
    id,
    status
) => {

    await prepararBanco();

    const restaurante =
        db.data.restaurantes.find(
            restaurante =>
                restaurante &&
                String(restaurante.id) ===
                String(id)
        );

    if (!restaurante) {
        return null;
    }

    restaurante.status = status;

    restaurante.online =
        status === "ABERTO";

    restaurante.aberto =
        status === "ABERTO";

    restaurante.atualizadoEm =
        new Date().toISOString();

    await db.write();

    return restaurante;
};

// ============================================================
// ATUALIZAR DADOS
// ============================================================

exports.atualizar = async (
    id,
    dados
) => {

    await prepararBanco();

    const restaurante =
        db.data.restaurantes.find(
            restaurante =>
                restaurante &&
                String(restaurante.id) ===
                String(id)
        );

    if (!restaurante) {
        return null;
    }

    if (
        dados &&
        typeof dados === "object"
    ) {

        Object.keys(dados).forEach(
            chave => {

                if (
                    dados[chave] !==
                    undefined
                ) {

                    restaurante[chave] =
                        dados[chave];
                }
            }
        );
    }

    restaurante.atualizadoEm =
        new Date().toISOString();

    await db.write();

    return restaurante;
};

// ============================================================
// EXCLUIR RESTAURANTE E TODOS OS DADOS VINCULADOS
// ============================================================
//
// Remove:
//
// - restaurante
// - usuário(s) da conta do restaurante
// - produtos
// - pedidos
// - pagamentos
// - outras coleções vinculadas
//
// NÃO remove:
//
// - clientes sem vínculo
// - entregadores sem vínculo
// - outros restaurantes
//
// ============================================================

exports.excluir = async (id) => {

    await prepararBanco();

    const restauranteId =
        String(id || "").trim();

    // ========================================================
    // VALIDAR ID
    // ========================================================

    if (!restauranteId) {

        throw new Error(
            "ID do restaurante é obrigatório."
        );
    }

    // ========================================================
    // LOCALIZAR RESTAURANTE
    // ========================================================

    const restaurante =
        db.data.restaurantes.find(
            item =>
                item &&
                String(item.id) ===
                restauranteId
        );

    if (!restaurante) {

        return null;
    }

    // ========================================================
    // CONTADORES
    // ========================================================

    const removidos = {

        restaurante: 0,

        usuarios: 0,

        produtos: 0,

        pedidos: 0,

        pagamentos: 0,

        outros: 0
    };

    // ========================================================
    // REMOVER RESTAURANTE
    // ========================================================

    const restaurantesAntes =
        db.data.restaurantes.length;

    db.data.restaurantes =
        db.data.restaurantes.filter(
            item =>
                !item ||
                String(item.id) !==
                restauranteId
        );

    removidos.restaurante =
        restaurantesAntes -
        db.data.restaurantes.length;

    // ========================================================
    // REMOVER USUÁRIOS VINCULADOS
    // ========================================================

    const usuariosAntes =
        db.data.usuarios.length;

    db.data.usuarios =
        db.data.usuarios.filter(
            usuario => {

                // Usuário inválido permanece
                if (
                    !usuario ||
                    typeof usuario !==
                    "object"
                ) {
                    return true;
                }

                // --------------------------------------------
                // restauranteId
                // --------------------------------------------

                if (
                    usuario.restauranteId !==
                    undefined &&
                    usuario.restauranteId !==
                    null
                ) {

                    return (
                        String(
                            usuario.restauranteId
                        ) !==
                        restauranteId
                    );
                }

                // --------------------------------------------
                // restaurantId
                // --------------------------------------------

                if (
                    usuario.restaurantId !==
                    undefined &&
                    usuario.restaurantId !==
                    null
                ) {

                    return (
                        String(
                            usuario.restaurantId
                        ) !==
                        restauranteId
                    );
                }

                // --------------------------------------------
                // restaurante.id
                // --------------------------------------------

                if (
                    usuario.restaurante &&
                    typeof usuario.restaurante ===
                    "object"
                ) {

                    const idAninhado =
                        usuario.restaurante.id;

                    if (
                        idAninhado !==
                        undefined &&
                        idAninhado !==
                        null
                    ) {

                        return (
                            String(idAninhado) !==
                            restauranteId
                        );
                    }
                }

                // Usuário sem vínculo
                // permanece no banco.

                return true;
            }
        );

    removidos.usuarios =
        usuariosAntes -
        db.data.usuarios.length;

    // ========================================================
    // REMOVER PRODUTOS
    // ========================================================

    if (
        Array.isArray(
            db.data.produtos
        )
    ) {

        const antes =
            db.data.produtos.length;

        db.data.produtos =
            db.data.produtos.filter(
                produto => {

                    if (
                        !produto ||
                        typeof produto !==
                        "object"
                    ) {
                        return true;
                    }

                    const vinculo =
                        produto.restauranteId ??
                        produto.restaurantId;

                    if (
                        vinculo ===
                        undefined ||
                        vinculo ===
                        null
                    ) {
                        return true;
                    }

                    return (
                        String(vinculo) !==
                        restauranteId
                    );
                }
            );

        removidos.produtos =
            antes -
            db.data.produtos.length;
    }

    // ========================================================
    // REMOVER PEDIDOS
    // ========================================================

    if (
        Array.isArray(
            db.data.pedidos
        )
    ) {

        const antes =
            db.data.pedidos.length;

        db.data.pedidos =
            db.data.pedidos.filter(
                pedido => {

                    if (
                        !pedido ||
                        typeof pedido !==
                        "object"
                    ) {
                        return true;
                    }

                    const vinculo =
                        pedido.restauranteId ??
                        pedido.restaurantId;

                    if (
                        vinculo ===
                        undefined ||
                        vinculo ===
                        null
                    ) {
                        return true;
                    }

                    return (
                        String(vinculo) !==
                        restauranteId
                    );
                }
            );

        removidos.pedidos =
            antes -
            db.data.pedidos.length;
    }

    // ========================================================
    // REMOVER PAGAMENTOS
    // ========================================================

    if (
        Array.isArray(
            db.data.pagamentos
        )
    ) {

        const antes =
            db.data.pagamentos.length;

        db.data.pagamentos =
            db.data.pagamentos.filter(
                pagamento => {

                    if (
                        !pagamento ||
                        typeof pagamento !==
                        "object"
                    ) {
                        return true;
                    }

                    const vinculo =
                        pagamento.restauranteId ??
                        pagamento.restaurantId;

                    if (
                        vinculo ===
                        undefined ||
                        vinculo ===
                        null
                    ) {
                        return true;
                    }

                    return (
                        String(vinculo) !==
                        restauranteId
                    );
                }
            );

        removidos.pagamentos =
            antes -
            db.data.pagamentos.length;
    }

    // ========================================================
    // OUTRAS COLEÇÕES
    // ========================================================

    const colecoesIgnoradas = [

        "restaurantes",

        "usuarios",

        "produtos",

        "pedidos",

        "pagamentos",

        "entregadores"
    ];

    Object.keys(db.data).forEach(
        nomeColecao => {

            if (
                colecoesIgnoradas.includes(
                    nomeColecao
                )
            ) {
                return;
            }

            if (
                !Array.isArray(
                    db.data[nomeColecao]
                )
            ) {
                return;
            }

            const antes =
                db.data[nomeColecao].length;

            db.data[nomeColecao] =
                db.data[nomeColecao].filter(
                    item => {

                        if (
                            !item ||
                            typeof item !==
                            "object"
                        ) {
                            return true;
                        }

                        const vinculo =
                            item.restauranteId ??
                            item.restaurantId;

                        if (
                            vinculo ===
                            undefined ||
                            vinculo ===
                            null
                        ) {
                            return true;
                        }

                        return (
                            String(vinculo) !==
                            restauranteId
                        );
                    }
                );

            removidos.outros +=
                antes -
                db.data[nomeColecao].length;
        }
    );

    // ========================================================
    // SALVAR
    // ========================================================

    await db.write();

    // ========================================================
    // LOG
    // ========================================================

    console.log(
        "============================================"
    );

    console.log(
        "🗑️ CONTA DO RESTAURANTE EXCLUÍDA"
    );

    console.log(
        "RESTAURANTE:",
        restauranteId
    );

    console.log(
        "Restaurantes:",
        removidos.restaurante
    );

    console.log(
        "Usuários:",
        removidos.usuarios
    );

    console.log(
        "Produtos:",
        removidos.produtos
    );

    console.log(
        "Pedidos:",
        removidos.pedidos
    );

    console.log(
        "Pagamentos:",
        removidos.pagamentos
    );

    console.log(
        "Outros:",
        removidos.outros
    );

    console.log(
        "============================================"
    );

    // ========================================================
    // RETORNO
    // ========================================================

    return {

        sucesso: true,

        restauranteId,

        removidos
    };
};