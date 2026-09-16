const { pool } = require("../config/database");

// ============================================================
// FOODJET - MODEL ENTREGADORES
// Compatível com a estrutura PostgreSQL atual:
//
// id
// nome
// email
// telefone
// cpf
// status
// online
// dados JSONB
// ============================================================

function normalizarDados(entregador = {}) {
    const dadosExistentes =
        entregador.dados &&
        typeof entregador.dados === "object" &&
        !Array.isArray(entregador.dados)
            ? entregador.dados
            : {};

    return {
        ...dadosExistentes,

        veiculo: entregador.veiculo ?? dadosExistentes.veiculo ?? null,

        placa: entregador.placa ?? dadosExistentes.placa ?? null,

        renavam: entregador.renavam ?? dadosExistentes.renavam ?? null,

        cnh: entregador.cnh ?? dadosExistentes.cnh ?? null,

        categoriaCnh:
            entregador.categoriaCnh ??
            dadosExistentes.categoriaCnh ??
            null,

        dataNascimento:
            entregador.dataNascimento ??
            dadosExistentes.dataNascimento ??
            null,

        endereco:
            entregador.endereco ??
            dadosExistentes.endereco ??
            null,

        cep:
            entregador.cep ??
            dadosExistentes.cep ??
            null,

        rua:
            entregador.rua ??
            dadosExistentes.rua ??
            null,

        numero:
            entregador.numero ??
            dadosExistentes.numero ??
            null,

        complemento:
            entregador.complemento ??
            dadosExistentes.complemento ??
            null,

        bairro:
            entregador.bairro ??
            dadosExistentes.bairro ??
            null,

        cidade:
            entregador.cidade ??
            dadosExistentes.cidade ??
            null,

        estado:
            entregador.estado ??
            dadosExistentes.estado ??
            null,

        cnhFrente:
            entregador.cnhFrente ??
            dadosExistentes.cnhFrente ??
            null,

        cnhVerso:
            entregador.cnhVerso ??
            dadosExistentes.cnhVerso ??
            null,

        crlv:
            entregador.crlv ??
            dadosExistentes.crlv ??
            null,

        comprovanteEndereco:
            entregador.comprovanteEndereco ??
            dadosExistentes.comprovanteEndereco ??
            null,

        criadoEm:
            entregador.criadoEm ??
            dadosExistentes.criadoEm ??
            new Date().toISOString(),

        atualizadoEm:
            new Date().toISOString()
    };
}


// ============================================================
// CRIAR / ATUALIZAR ENTREGADOR
// ============================================================

async function criar(entregador) {
    if (!entregador || !entregador.id) {
        throw new Error("ID do entregador é obrigatório");
    }

    const dados = normalizarDados(entregador);

    const resultado = await pool.query(
        `
        INSERT INTO entregadores (
            id,
            nome,
            email,
            telefone,
            cpf,
            status,
            online,
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
            $8::jsonb
        )
        ON CONFLICT (id)
        DO UPDATE SET
            nome = EXCLUDED.nome,
            email = EXCLUDED.email,
            telefone = EXCLUDED.telefone,
            cpf = EXCLUDED.cpf,
            status = EXCLUDED.status,
            online = EXCLUDED.online,
            dados = EXCLUDED.dados
        RETURNING
            id,
            nome,
            email,
            telefone,
            cpf,
            status,
            online,
            dados
        `,
        [
            String(entregador.id),
            entregador.nome
                ? String(entregador.nome).trim()
                : null,

            entregador.email
                ? String(entregador.email).trim().toLowerCase()
                : null,

            entregador.telefone
                ? String(entregador.telefone).trim()
                : null,

            entregador.cpf
                ? String(entregador.cpf).trim()
                : null,

            entregador.status
                ? String(entregador.status).trim().toUpperCase()
                : "DISPONIVEL",

            entregador.online === true,

            JSON.stringify(dados)
        ]
    );

    return formatarEntregador(resultado.rows[0]);
}


// ============================================================
// LISTAR ENTREGADORES
// ============================================================

async function listar() {
    const resultado = await pool.query(`
        SELECT
            id,
            nome,
            email,
            telefone,
            cpf,
            status,
            online,
            dados
        FROM entregadores
        ORDER BY id DESC
    `);

    return resultado.rows.map(formatarEntregador);
}


// ============================================================
// BUSCAR POR ID
// ============================================================

async function buscarPorId(id) {
    const resultado = await pool.query(
        `
        SELECT
            id,
            nome,
            email,
            telefone,
            cpf,
            status,
            online,
            dados
        FROM entregadores
        WHERE id = $1
        LIMIT 1
        `,
        [String(id)]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return formatarEntregador(resultado.rows[0]);
}


// ============================================================
// ATUALIZAR STATUS
// ============================================================

async function atualizarStatus(id, status) {
    const resultado = await pool.query(
        `
        UPDATE entregadores
        SET status = $2
        WHERE id = $1
        RETURNING
            id,
            nome,
            email,
            telefone,
            cpf,
            status,
            online,
            dados
        `,
        [
            String(id),
            String(status).trim().toUpperCase()
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return formatarEntregador(resultado.rows[0]);
}


// ============================================================
// ATUALIZAR ONLINE
// ============================================================

async function atualizarOnline(id, online) {
    const resultado = await pool.query(
        `
        UPDATE entregadores
        SET online = $2
        WHERE id = $1
        RETURNING
            id,
            nome,
            email,
            telefone,
            cpf,
            status,
            online,
            dados
        `,
        [
            String(id),
            Boolean(online)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return formatarEntregador(resultado.rows[0]);
}


// ============================================================
// ATUALIZAR DADOS
// ============================================================

async function atualizarDados(id, novosDados = {}) {
    const atual = await buscarPorId(id);

    if (!atual) {
        return null;
    }

    const dadosAtuais =
        atual.dados &&
        typeof atual.dados === "object"
            ? atual.dados
            : {};

    const dadosAtualizados = {
        ...dadosAtuais,
        ...novosDados,
        atualizadoEm: new Date().toISOString()
    };

    const resultado = await pool.query(
        `
        UPDATE entregadores
        SET dados = $2::jsonb
        WHERE id = $1
        RETURNING
            id,
            nome,
            email,
            telefone,
            cpf,
            status,
            online,
            dados
        `,
        [
            String(id),
            JSON.stringify(dadosAtualizados)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return formatarEntregador(resultado.rows[0]);
}


// ============================================================
// FORMATAR ENTREGADOR
// ============================================================

function formatarEntregador(row) {
    if (!row) {
        return null;
    }

    const dados =
        row.dados &&
        typeof row.dados === "object"
            ? row.dados
            : {};

    return {
        id: row.id,
        nome: row.nome,
        email: row.email,
        telefone: row.telefone,
        cpf: row.cpf,
        status: row.status,
        online: row.online,

        // Dados específicos do entregador
        veiculo: dados.veiculo ?? null,
        placa: dados.placa ?? null,
        renavam: dados.renavam ?? null,

        cnh: dados.cnh ?? null,
        categoriaCnh: dados.categoriaCnh ?? null,

        dataNascimento: dados.dataNascimento ?? null,

        endereco: dados.endereco ?? null,
        cep: dados.cep ?? null,
        rua: dados.rua ?? null,
        numero: dados.numero ?? null,
        complemento: dados.complemento ?? null,
        bairro: dados.bairro ?? null,
        cidade: dados.cidade ?? null,
        estado: dados.estado ?? null,

        cnhFrente: dados.cnhFrente ?? null,
        cnhVerso: dados.cnhVerso ?? null,
        crlv: dados.crlv ?? null,
        comprovanteEndereco:
            dados.comprovanteEndereco ?? null,

        dados
    };
}


// ============================================================
// EXPORTS
// ============================================================

module.exports = {
    criar,
    listar,
    buscarPorId,
    atualizarStatus,
    atualizarOnline,
    atualizarDados
};