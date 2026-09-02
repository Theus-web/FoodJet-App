const { pool } = require("../config/database");

// ============================================================
// CRIAR ENTREGADOR
// ============================================================

async function criar(entregador) {

    if (!entregador || typeof entregador !== "object") {
        throw new Error("Entregador inválido.");
    }

    if (!entregador.id) {
        throw new Error("ID do entregador é obrigatório.");
    }

    const id = String(entregador.id);

    const nome =
        entregador.nome ||
        entregador.name ||
        null;

    const telefone =
        entregador.telefone ||
        entregador.phone ||
        null;

    const email =
        entregador.email ||
        null;

    const status =
        entregador.status ||
        "DISPONIVEL";

    const online =
        entregador.online === true;

    const veiculo =
        entregador.veiculo ||
        null;

    const placa =
        entregador.placa ||
        null;

    await pool.query(
        `
        INSERT INTO entregadores (
            id,
            nome,
            telefone,
            email,
            status,
            online,
            veiculo,
            placa,
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
            $9::jsonb
        )
        ON CONFLICT (id)
        DO UPDATE SET
            nome = EXCLUDED.nome,
            telefone = EXCLUDED.telefone,
            email = EXCLUDED.email,
            status = EXCLUDED.status,
            online = EXCLUDED.online,
            veiculo = EXCLUDED.veiculo,
            placa = EXCLUDED.placa,
            dados = EXCLUDED.dados,
            atualizado_em = NOW()
        `,
        [
            id,
            nome,
            telefone,
            email,
            status,
            online,
            veiculo,
            placa,
            JSON.stringify(entregador),
        ]
    );

    return entregador;
}

// ============================================================
// LISTAR ENTREGADORES
// ============================================================

async function listar() {

    const resultado = await pool.query(
        `
        SELECT
            id,
            nome,
            telefone,
            email,
            status,
            online,
            veiculo,
            placa,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM entregadores
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
            nome: row.nome,
            telefone: row.telefone,
            email: row.email,
            status: row.status,
            online: row.online,
            veiculo: row.veiculo,
            placa: row.placa,
            criadoEm: row.criadoEm,
            atualizadoEm: row.atualizadoEm,
        };

    });
}

// ============================================================
// BUSCAR POR ID
// ============================================================

async function buscarPorId(id) {

    if (!id) {
        return null;
    }

    const resultado = await pool.query(
        `
        SELECT
            id,
            nome,
            telefone,
            email,
            status,
            online,
            veiculo,
            placa,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM entregadores
        WHERE id = $1
        LIMIT 1
        `,
        [String(id)]
    );

    if (resultado.rowCount === 0) {
        return null;
    }

    const row = resultado.rows[0];

    const dados =
        row.dados &&
        typeof row.dados === "object"
            ? row.dados
            : {};

    return {
        ...dados,

        id: row.id,
        nome: row.nome,
        telefone: row.telefone,
        email: row.email,
        status: row.status,
        online: row.online,
        veiculo: row.veiculo,
        placa: row.placa,
        criadoEm: row.criadoEm,
        atualizadoEm: row.atualizadoEm,
    };
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
    criar,
    listar,
    buscarPorId,
};