const { pool } = require("../config/database");

// ============================================================
// CRIAR RESTAURANTE
// ============================================================

exports.criar = async (restaurante) => {

    if (!restaurante || typeof restaurante !== "object") {
        throw new Error(
            "Dados do restaurante são obrigatórios."
        );
    }

    // ========================================================
    // ID
    // ========================================================

    const id = restaurante.id
        ? String(restaurante.id)
        : `rest_${Date.now()}`;

    // ========================================================
    // DADOS PRINCIPAIS
    // ========================================================

    const nome =
        restaurante.nome !== undefined &&
        restaurante.nome !== null
            ? String(restaurante.nome).trim()
            : null;

    const cnpj =
        restaurante.cnpj !== undefined &&
        restaurante.cnpj !== null
            ? String(restaurante.cnpj).trim()
            : null;

    const categoria =
        restaurante.categoria !== undefined &&
        restaurante.categoria !== null
            ? String(restaurante.categoria).trim()
            : null;

    const status =
        restaurante.status !== undefined &&
        restaurante.status !== null
            ? String(restaurante.status)
            : null;

    const online =
        restaurante.online !== undefined
            ? Boolean(restaurante.online)
            : status === "ABERTO";

    const aberto =
        restaurante.aberto !== undefined
            ? Boolean(restaurante.aberto)
            : status === "ABERTO";

    // ========================================================
    // DATAS
    // ========================================================

    const criadoEm =
        restaurante.criadoEm
            ? new Date(restaurante.criadoEm)
            : new Date();

    const atualizadoEm =
        restaurante.atualizadoEm
            ? new Date(restaurante.atualizadoEm)
            : new Date();

    // ========================================================
    // PRESERVAR REGISTRO COMPLETO
    // ========================================================

    const dados = {
        ...restaurante,
        id,
        nome,
        cnpj,
        categoria,
        status,
        online,
        aberto,
        criadoEm: criadoEm.toISOString(),
        atualizadoEm: atualizadoEm.toISOString(),
    };

    // ========================================================
    // INSERT
    // ========================================================

    const resultado = await pool.query(
        `
        INSERT INTO restaurantes (
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            status,
            online,
            aberto,
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
            $8,
            $9,
            $10,
            $11,
            $12,
            $13
        )
        RETURNING
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            status,
            online,
            aberto,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            id,
            nome,
            cnpj,
            categoria,

            restaurante.endereco
                ? JSON.stringify(restaurante.endereco)
                : null,

            restaurante.pagamento
                ? JSON.stringify(restaurante.pagamento)
                : null,

            restaurante.imagem || null,

            status,
            online,
            aberto,

            criadoEm,
            atualizadoEm,

            dados,
        ]
    );

    const novoRestaurante =
        montarRestaurante(resultado.rows[0]);

    console.log(
        "🏪 RESTAURANTE CRIADO:",
        novoRestaurante.id
    );

    return novoRestaurante;
};

// ============================================================
// LISTAR RESTAURANTES
// ============================================================

exports.listar = async () => {

    const resultado = await pool.query(
        `
        SELECT
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            status,
            online,
            aberto,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM restaurantes
        ORDER BY criado_em ASC NULLS LAST
        `
    );

    return resultado.rows.map(
        montarRestaurante
    );
};

// ============================================================
// BUSCAR POR ID
// ============================================================

exports.buscarPorId = async (id) => {

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
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            status,
            online,
            aberto,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM restaurantes
        WHERE id = $1
        LIMIT 1
        `,
        [
            String(id)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarRestaurante(
        resultado.rows[0]
    );
};

// ============================================================
// ATUALIZAR STATUS
// ============================================================

exports.atualizarStatus = async (
    id,
    status
) => {

    const restaurante =
        await exports.buscarPorId(id);

    if (!restaurante) {
        return null;
    }

    const novoStatus =
        status !== undefined &&
        status !== null
            ? String(status)
            : restaurante.status;

    const online =
        novoStatus === "ABERTO";

    const aberto =
        novoStatus === "ABERTO";

    const atualizadoEm =
        new Date();

    const dadosAtualizados = {
        ...(restaurante.dados || {}),
        status: novoStatus,
        online,
        aberto,
        atualizadoEm:
            atualizadoEm.toISOString(),
    };

    const resultado = await pool.query(
        `
        UPDATE restaurantes
        SET
            status = $1,
            online = $2,
            aberto = $3,
            atualizado_em = $4,
            dados = $5
        WHERE id = $6
        RETURNING
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            status,
            online,
            aberto,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            novoStatus,
            online,
            aberto,
            atualizadoEm,
            dadosAtualizados,
            String(id),
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarRestaurante(
        resultado.rows[0]
    );
};

// ============================================================
// ATUALIZAR DADOS
// ============================================================

exports.atualizar = async (
    id,
    dados
) => {

    const restaurante =
        await exports.buscarPorId(id);

    if (!restaurante) {
        return null;
    }

    if (
        !dados ||
        typeof dados !== "object"
    ) {
        return restaurante;
    }

    // ========================================================
    // MESMO COMPORTAMENTO DO LOWDB:
    // todos os campos definidos são atualizados
    // ========================================================

    const restauranteAtualizado = {
        ...restaurante,
        ...dados,
    };

    const atualizadoEm =
        new Date();

    restauranteAtualizado.atualizadoEm =
        atualizadoEm.toISOString();

    // ========================================================
    // CAMPOS PRINCIPAIS
    // ========================================================

    const nome =
        restauranteAtualizado.nome !== undefined &&
        restauranteAtualizado.nome !== null
            ? String(restauranteAtualizado.nome).trim()
            : null;

    const cnpj =
        restauranteAtualizado.cnpj !== undefined &&
        restauranteAtualizado.cnpj !== null
            ? String(restauranteAtualizado.cnpj).trim()
            : null;

    const categoria =
        restauranteAtualizado.categoria !== undefined &&
        restauranteAtualizado.categoria !== null
            ? String(restauranteAtualizado.categoria).trim()
            : null;

    const status =
        restauranteAtualizado.status !== undefined &&
        restauranteAtualizado.status !== null
            ? String(restauranteAtualizado.status)
            : null;

    const online =
        restauranteAtualizado.online !== undefined
            ? Boolean(restauranteAtualizado.online)
            : status === "ABERTO";

    const aberto =
        restauranteAtualizado.aberto !== undefined
            ? Boolean(restauranteAtualizado.aberto)
            : status === "ABERTO";

    // ========================================================
    // DADOS COMPLETOS
    // ========================================================

    const dadosAtualizados = {
        ...(restaurante.dados || {}),
        ...restauranteAtualizado,
        id: restaurante.id,
        nome,
        cnpj,
        categoria,
        status,
        online,
        aberto,
        atualizadoEm:
            atualizadoEm.toISOString(),
    };

    // ========================================================
    // UPDATE
    // ========================================================

    const resultado = await pool.query(
        `
        UPDATE restaurantes
        SET
            nome = $1,
            cnpj = $2,
            categoria = $3,
            endereco = $4,
            pagamento = $5,
            imagem = $6,
            status = $7,
            online = $8,
            aberto = $9,
            atualizado_em = $10,
            dados = $11
        WHERE id = $12
        RETURNING
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            status,
            online,
            aberto,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            nome,
            cnpj,
            categoria,

            restauranteAtualizado.endereco !== undefined
                ? JSON.stringify(restauranteAtualizado.endereco)
                : null,

            restauranteAtualizado.pagamento !== undefined
                ? JSON.stringify(restauranteAtualizado.pagamento)
                : null,

            restauranteAtualizado.imagem !== undefined
                ? restauranteAtualizado.imagem
                : null,

            status,
            online,
            aberto,
            atualizadoEm,
            dadosAtualizados,
            String(id),
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarRestaurante(
        resultado.rows[0]
    );
};

// ============================================================
// EXCLUIR RESTAURANTE E DADOS VINCULADOS
// ============================================================

exports.excluir = async (id) => {

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
    // VERIFICAR RESTAURANTE
    // ========================================================

    const restaurante =
        await exports.buscarPorId(
            restauranteId
        );

    if (!restaurante) {
        return null;
    }

    // ========================================================
    // TRANSAÇÃO
    // ========================================================

    const client =
        await pool.connect();

    try {

        await client.query(
            "BEGIN"
        );

        // ====================================================
        // CONTADORES
        // ====================================================

        const removidos = {

            restaurante: 0,

            usuarios: 0,

            produtos: 0,

            pedidos: 0,

            pagamentos: 0,

            outros: 0,
        };

        // ====================================================
        // PAGAMENTOS ASAAS
        // ====================================================

        const pagamentosAsaas =
            await client.query(
                `
                DELETE FROM pagamentos_asaas
                WHERE restaurante_id = $1
                `,
                [
                    restauranteId
                ]
            );

        removidos.pagamentos +=
            pagamentosAsaas.rowCount;

        // ====================================================
        // PAGAMENTOS
        // ====================================================

        const pagamentos =
            await client.query(
                `
                DELETE FROM pagamentos
                WHERE restaurante_id = $1
                `,
                [
                    restauranteId
                ]
            );

        removidos.pagamentos +=
            pagamentos.rowCount;

        // ====================================================
        // PEDIDOS
        // ====================================================

        const pedidos =
            await client.query(
                `
                DELETE FROM pedidos
                WHERE restaurante_id = $1
                `,
                [
                    restauranteId
                ]
            );

        removidos.pedidos =
            pedidos.rowCount;

        // ====================================================
        // PRODUTOS
        // ====================================================

        const produtos =
            await client.query(
                `
                DELETE FROM produtos
                WHERE restaurante_id = $1
                `,
                [
                    restauranteId
                ]
            );

        removidos.produtos =
            produtos.rowCount;

        // ====================================================
        // USUÁRIOS
        // ====================================================

        const usuarios =
            await client.query(
                `
                DELETE FROM usuarios
                WHERE restaurante_id = $1
                   OR dados->>'restaurantId' = $1
                   OR dados->'restaurante'->>'id' = $1
                `,
                [
                    restauranteId
                ]
            );

        removidos.usuarios =
            usuarios.rowCount;

        // ====================================================
        // OUTRAS COLEÇÕES
        // ====================================================
        //
        // No momento as tabelas principais são as acima.
        // As demais serão migradas individualmente.
        //
        // ====================================================

        // ====================================================
        // RESTAURANTE
        // ====================================================

        const restauranteRemovido =
            await client.query(
                `
                DELETE FROM restaurantes
                WHERE id = $1
                `,
                [
                    restauranteId
                ]
            );

        removidos.restaurante =
            restauranteRemovido.rowCount;

        // ====================================================
        // COMMIT
        // ====================================================

        await client.query(
            "COMMIT"
        );

        // ====================================================
        // LOG
        // ====================================================

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

        return {

            sucesso: true,

            restauranteId,

            removidos,
        };

    } catch (error) {

        await client.query(
            "ROLLBACK"
        );

        console.error(
            "❌ ERRO AO EXCLUIR RESTAURANTE:"
        );

        console.error(error);

        throw error;

    } finally {

        client.release();
    }
};

// ============================================================
// MONTAR RESTAURANTE
// ============================================================

function montarRestaurante(row) {

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

        nome: row.nome,

        cnpj: row.cnpj,

        categoria: row.categoria,

        endereco: row.endereco,

        pagamento: row.pagamento,

        imagem: row.imagem,

        status: row.status,

        online: row.online,

        aberto: row.aberto,

        criadoEm:
            row.criadoEm
                ? new Date(
                    row.criadoEm
                ).toISOString()
                : null,

        atualizadoEm:
            row.atualizadoEm
                ? new Date(
                    row.atualizadoEm
                ).toISOString()
                : null,
    };
}