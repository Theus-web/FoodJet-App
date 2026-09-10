const { pool } = require("../config/database");

// ============================================================
// CRIAR RESTAURANTE
// ============================================================

exports.criar = async (restaurante) => {
    if (!restaurante || typeof restaurante !== "object") {
        throw new Error("Dados do restaurante são obrigatórios.");
    }

    const id = restaurante.id
        ? String(restaurante.id)
        : `rest_${Date.now()}`;

    const nome = restaurante.nome ? String(restaurante.nome).trim() : null;
    const cnpj = restaurante.cnpj ? String(restaurante.cnpj).trim() : null;
    const categoria = restaurante.categoria
        ? String(restaurante.categoria).trim()
        : null;

    const status = restaurante.status
        ? String(restaurante.status)
        : "ABERTO";

    const online =
        restaurante.online !== undefined
            ? Boolean(restaurante.online)
            : status === "ABERTO";

    const aberto =
        restaurante.aberto !== undefined
            ? Boolean(restaurante.aberto)
            : status === "ABERTO";

    const criadoEm = restaurante.criadoEm
        ? new Date(restaurante.criadoEm)
        : new Date();

    const atualizadoEm = restaurante.atualizadoEm
        ? new Date(restaurante.atualizadoEm)
        : new Date();

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
            capa,
            status,
            online,
            aberto,
            criado_em,
            atualizado_em,
            dados
        )
        VALUES (
            $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14
        )
        RETURNING
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            capa,
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
            restaurante.capa || null,
            status,
            online,
            aberto,
            criadoEm,
            atualizadoEm,
            dados,
        ]
    );

    const novoRestaurante = montarRestaurante(resultado.rows[0]);

    console.log("🏪 RESTAURANTE CRIADO:", novoRestaurante.id);

    return novoRestaurante;
};

// ============================================================
// LISTAR RESTAURANTES
// ============================================================

exports.listar = async () => {
    const resultado = await pool.query(`
        SELECT
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            capa,
            status,
            online,
            aberto,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM restaurantes
        ORDER BY criado_em ASC NULLS LAST
    `);

    return resultado.rows.map(montarRestaurante);
};

// ============================================================
// BUSCAR POR ID
// ============================================================

exports.buscarPorId = async (id) => {
    if (!id) return null;

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
            capa,
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
        [String(id)]
    );

    if (!resultado.rows.length) return null;

    return montarRestaurante(resultado.rows[0]);
};

// ============================================================
// ATUALIZAR STATUS
// ============================================================

exports.atualizarStatus = async (id, status) => {
    const restaurante = await exports.buscarPorId(id);

    if (!restaurante) {
        return null;
    }

    const novoStatus =
        status !== undefined && status !== null
            ? String(status)
            : restaurante.status;

    const online = novoStatus === "ABERTO";
    const aberto = novoStatus === "ABERTO";
    const atualizadoEm = new Date();

    const dadosAtualizados = {
        ...(restaurante.dados || {}),
        status: novoStatus,
        online,
        aberto,
        atualizadoEm: atualizadoEm.toISOString(),
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
            capa,
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

    if (!resultado.rows.length) {
        return null;
    }

    return montarRestaurante(resultado.rows[0]);
};

// ============================================================
// ATUALIZAR DADOS
// ============================================================

exports.atualizar = async (id, dados) => {
    const restaurante = await exports.buscarPorId(id);

    if (!restaurante) {
        return null;
    }

    if (!dados || typeof dados !== "object") {
        return restaurante;
    }

    const restauranteAtualizado = {
        ...restaurante,
        ...dados,
    };

    const atualizadoEm = new Date();

    restauranteAtualizado.atualizadoEm =
        atualizadoEm.toISOString();

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
            capa = $7,
            status = $8,
            online = $9,
            aberto = $10,
            atualizado_em = $11,
            dados = $12
        WHERE id = $13
        RETURNING
            id,
            nome,
            cnpj,
            categoria,
            endereco,
            pagamento,
            imagem,
            capa,
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

            restauranteAtualizado.capa !== undefined
                ? restauranteAtualizado.capa
                : null,

            status,
            online,
            aberto,
            atualizadoEm,
            dadosAtualizados,
            String(id),
        ]
    );

    if (!resultado.rows.length) {
        return null;
    }

    return montarRestaurante(resultado.rows[0]);
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

        await client.query("BEGIN");

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

        try {

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

        } catch (error) {

            console.log(
                "⚠️ pagamentos_asaas não removido:",
                error.message
            );
        }

        // ====================================================
        // PAGAMENTOS
        // ====================================================

        try {

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

        } catch (error) {

            console.log(
                "⚠️ pagamentos não removido:",
                error.message
            );
        }

        // ====================================================
        // PEDIDOS
        // ====================================================

        try {

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

        } catch (error) {

            console.log(
                "⚠️ pedidos não removido:",
                error.message
            );
        }

        // ====================================================
        // PRODUTOS
        // ====================================================

        try {

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

        } catch (error) {

            console.log(
                "⚠️ produtos não removido:",
                error.message
            );
        }

        // ====================================================
        // USUÁRIOS
        // ====================================================

        try {

            const usuarios =
                await client.query(
                    `
                    DELETE FROM usuarios
                    WHERE restaurante_id = $1
                       OR dados->>'restaurantId' = $1
                       OR dados->>'restauranteId' = $1
                       OR dados->'restaurante'->>'id' = $1
                    `,
                    [
                        restauranteId
                    ]
                );

            removidos.usuarios =
                usuarios.rowCount;

        } catch (error) {

            console.log(
                "⚠️ usuários não removidos:",
                error.message
            );
        }

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

        await client.query("COMMIT");

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

        await client.query("ROLLBACK");

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

    // ========================================================
    // DADOS JSON
    // ========================================================

    const dados =
        row.dados &&
        typeof row.dados === "object"
            ? row.dados
            : {};

    // ========================================================
    // RESTAURANTE FINAL
    // ========================================================

    return {

        ...dados,

        // ====================================================
        // IDENTIFICAÇÃO
        // ====================================================

        id: row.id,

        nome: row.nome,

        cnpj: row.cnpj,

        categoria: row.categoria,

        // ====================================================
        // DADOS DE CONTATO / PAGAMENTO
        // ====================================================

        endereco: row.endereco,

        pagamento: row.pagamento,

        // ====================================================
        // IMAGENS
        // ====================================================

        // Logo
        imagem: row.imagem,

        // Capa
        capa: row.capa,

        // ====================================================
        // STATUS
        // ====================================================

        status: row.status,

        online: row.online,

        aberto: row.aberto,

        // ====================================================
        // DATAS
        // ====================================================

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