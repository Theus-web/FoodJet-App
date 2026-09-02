const { pool } = require("../config/database");

// ============================================================
// BUSCAR USUÁRIO POR ID
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
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM usuarios
        WHERE id = $1
        LIMIT 1
        `,
        [String(id)]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// BUSCAR USUÁRIO POR E-MAIL
// ============================================================

async function buscarPorEmail(email) {

    const emailNormalizado =
        String(email || "")
            .trim()
            .toLowerCase();

    if (!emailNormalizado) {
        return null;
    }

    const resultado = await pool.query(
        `
        SELECT
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM usuarios
        WHERE LOWER(TRIM(email)) = $1
        LIMIT 1
        `,
        [emailNormalizado]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// ALIAS
// Mantém compatibilidade com código antigo
// ============================================================

async function buscarEmail(email) {
    return buscarPorEmail(email);
}

// ============================================================
// CRIAR USUÁRIO
// ============================================================

async function criar(usuario) {

    if (
        !usuario ||
        typeof usuario !== "object"
    ) {
        throw new Error(
            "Dados do usuário são obrigatórios."
        );
    }

    const id =
        usuario.id
            ? String(usuario.id)
            : `user_${Date.now()}`;

    const nome =
        usuario.nome !== undefined &&
        usuario.nome !== null
            ? String(usuario.nome).trim()
            : null;

    const email =
        usuario.email !== undefined &&
        usuario.email !== null
            ? String(usuario.email)
                .trim()
                .toLowerCase()
            : null;

    const agora =
        new Date();

    const dadosExtras = {
        ...usuario,
        id,
        nome,
        email
    };

    const resultado = await pool.query(
        `
        INSERT INTO usuarios (
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id,
            telefone,
            cpf,
            endereco,
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
            $12
        )
        RETURNING
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            id,
            nome,
            email,
            usuario.senha || null,
            usuario.tipo || null,
            usuario.restauranteId !== undefined &&
            usuario.restauranteId !== null
                ? String(usuario.restauranteId)
                : null,
            usuario.telefone || null,
            usuario.cpf || null,
            usuario.endereco || null,
            usuario.criadoEm
                ? new Date(usuario.criadoEm)
                : agora,
            agora,
            dadosExtras
        ]
    );

    const novoUsuario =
        montarUsuario(resultado.rows[0]);

    console.log(
        "👤 USUÁRIO CRIADO:",
        novoUsuario.id
    );

    return novoUsuario;
}

// ============================================================
// ATUALIZAR SENHA
// ============================================================

async function atualizarSenha(
    id,
    novaSenhaHash
) {

    const usuario =
        await buscarPorId(id);

    if (!usuario) {
        return null;
    }

    const agora =
        new Date();

    const dadosAtualizados = {
        ...(usuario.dados || {}),
        senha: novaSenhaHash
    };

    const resultado = await pool.query(
        `
        UPDATE usuarios
        SET
            senha = $1,
            atualizado_em = $2,
            dados = $3
        WHERE id = $4
        RETURNING
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            novaSenhaHash,
            agora,
            dadosAtualizados,
            String(id)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// ATUALIZAR PERFIL
// ============================================================

async function atualizarPerfil(
    id,
    dados
) {

    const usuario =
        await buscarPorId(id);

    if (!usuario) {
        return null;
    }

    const nome =
        dados?.nome !== undefined &&
        dados?.nome !== null
            ? String(dados.nome).trim()
            : usuario.nome;

    const telefone =
        dados?.telefone !== undefined &&
        dados?.telefone !== null
            ? String(dados.telefone).trim()
            : usuario.telefone;

    const email =
        dados?.email !== undefined &&
        dados?.email !== null
            ? String(dados.email)
                .trim()
                .toLowerCase()
            : usuario.email;

    const cpf =
        dados?.cpf !== undefined &&
        dados?.cpf !== null
            ? String(dados.cpf).trim()
            : usuario.cpf;

    const agora =
        new Date();

    const dadosAtualizados = {
        ...(usuario.dados || {}),
        nome,
        telefone,
        email,
        cpf
    };

    const resultado = await pool.query(
        `
        UPDATE usuarios
        SET
            nome = $1,
            telefone = $2,
            email = $3,
            cpf = $4,
            atualizado_em = $5,
            dados = $6
        WHERE id = $7
        RETURNING
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            nome,
            telefone,
            email,
            cpf,
            agora,
            dadosAtualizados,
            String(id)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// ATUALIZAR ENDEREÇO
// ============================================================

async function atualizarEndereco(
    id,
    endereco
) {

    const usuario =
        await buscarPorId(id);

    if (!usuario) {
        return null;
    }

    const novoEndereco = {
        cep:
            endereco?.cep || "",

        rua:
            endereco?.rua || "",

        numero:
            endereco?.numero || "",

        bairro:
            endereco?.bairro || "",

        complemento:
            endereco?.complemento || "",

        cidade:
            endereco?.cidade || "",

        estado:
            endereco?.estado || ""
    };

    const agora =
        new Date();

    const dadosAtualizados = {
        ...(usuario.dados || {}),
        endereco: novoEndereco
    };

    const resultado = await pool.query(
        `
        UPDATE usuarios
        SET
            endereco = $1,
            atualizado_em = $2,
            dados = $3
        WHERE id = $4
        RETURNING
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            novoEndereco,
            agora,
            dadosAtualizados,
            String(id)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// SALVAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function salvarCodigoRecuperacao(
    id,
    codigo,
    expiracao
) {

    const usuario =
        await buscarPorId(id);

    if (!usuario) {
        return null;
    }

    const agora =
        new Date();

    const dadosAtualizados = {
        ...(usuario.dados || {}),
        codigoRecuperacao:
            String(codigo),
        codigoRecuperacaoExpiracao:
            Number(expiracao)
    };

    const resultado = await pool.query(
        `
        UPDATE usuarios
        SET
            atualizado_em = $1,
            dados = $2
        WHERE id = $3
        RETURNING
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            agora,
            dadosAtualizados,
            String(id)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// BUSCAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function buscarPorCodigoRecuperacao(
    email,
    codigo
) {

    const emailNormalizado =
        String(email || "")
            .trim()
            .toLowerCase();

    const codigoNormalizado =
        String(codigo || "").trim();

    if (
        !emailNormalizado ||
        !codigoNormalizado
    ) {
        return null;
    }

    const agora =
        Date.now();

    const resultado = await pool.query(
        `
        SELECT
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM usuarios
        WHERE LOWER(TRIM(email)) = $1
          AND dados->>'codigoRecuperacao' = $2
          AND (
              dados->>'codigoRecuperacaoExpiracao'
          )::BIGINT > $3
        LIMIT 1
        `,
        [
            emailNormalizado,
            codigoNormalizado,
            agora
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// LIMPAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function limparCodigoRecuperacao(
    id
) {

    const usuario =
        await buscarPorId(id);

    if (!usuario) {
        return null;
    }

    const dadosAtualizados = {
        ...(usuario.dados || {})
    };

    delete dadosAtualizados.codigoRecuperacao;
    delete dadosAtualizados.codigoRecuperacaoExpiracao;

    const resultado = await pool.query(
        `
        UPDATE usuarios
        SET
            atualizado_em = $1,
            dados = $2
        WHERE id = $3
        RETURNING
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        `,
        [
            new Date(),
            dadosAtualizados,
            String(id)
        ]
    );

    if (resultado.rows.length === 0) {
        return null;
    }

    return montarUsuario(resultado.rows[0]);
}

// ============================================================
// EXCLUIR USUÁRIO
// ============================================================

async function excluir(id) {

    const resultado = await pool.query(
        `
        DELETE FROM usuarios
        WHERE id = $1
        `,
        [String(id)]
    );

    if (resultado.rowCount === 0) {
        return false;
    }

    console.log(
        "🗑️ USUÁRIO EXCLUÍDO:",
        id
    );

    return true;
}

// ============================================================
// LISTAR USUÁRIOS
// ============================================================

async function listar() {

    const resultado = await pool.query(
        `
        SELECT
            id,
            nome,
            email,
            senha,
            tipo,
            restaurante_id AS "restauranteId",
            telefone,
            cpf,
            endereco,
            criado_em AS "criadoEm",
            atualizado_em AS "atualizadoEm",
            dados
        FROM usuarios
        ORDER BY criado_em ASC NULLS LAST
        `
    );

    return resultado.rows.map(
        montarUsuario
    );
}

// ============================================================
// MONTAR USUÁRIO
// ============================================================

function montarUsuario(row) {

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
        email: row.email,
        senha: row.senha,
        tipo: row.tipo,
        restauranteId:
            row.restauranteId,
        telefone: row.telefone,
        cpf: row.cpf,
        endereco: row.endereco,
        criadoEm:
            row.criadoEm
                ? new Date(row.criadoEm)
                    .toISOString()
                : null,
        atualizadoEm:
            row.atualizadoEm
                ? new Date(row.atualizadoEm)
                    .toISOString()
                : null
    };
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

    criar,

    listar,

    buscarPorId,

    buscarPorEmail,

    buscarEmail,

    atualizarSenha,

    atualizarPerfil,

    atualizarEndereco,

    salvarCodigoRecuperacao,

    buscarPorCodigoRecuperacao,

    limparCodigoRecuperacao,

    excluir

};