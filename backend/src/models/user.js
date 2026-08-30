
const { db } = require("../config/database");

// ============================================================
// PREPARAR BANCO
// ============================================================

async function prepararBanco() {

    await db.read();

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.usuarios)) {
        db.data.usuarios = [];
    }
}

// ============================================================
// BUSCAR USUÁRIO POR ID
// ============================================================

async function buscarPorId(id) {

    await prepararBanco();

    if (
        id === undefined ||
        id === null ||
        String(id).trim() === ""
    ) {
        return null;
    }

    return db.data.usuarios.find(
        usuario =>
            usuario &&
            String(usuario.id) === String(id)
    ) || null;
}

// ============================================================
// BUSCAR USUÁRIO POR E-MAIL
// ============================================================

async function buscarPorEmail(email) {

    await prepararBanco();

    const emailNormalizado =
        String(email || "")
            .trim()
            .toLowerCase();

    if (!emailNormalizado) {
        return null;
    }

    return db.data.usuarios.find(
        usuario =>
            usuario &&
            String(usuario.email || "")
                .trim()
                .toLowerCase() ===
            emailNormalizado
    ) || null;
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

    await prepararBanco();

    if (
        !usuario ||
        typeof usuario !== "object"
    ) {
        throw new Error(
            "Dados do usuário são obrigatórios."
        );
    }

    if (!usuario.id) {
        usuario.id =
            `user_${Date.now()}`;
    }

    db.data.usuarios.push(usuario);

    await db.write();

    console.log(
        "👤 USUÁRIO CRIADO:",
        usuario.id
    );

    return usuario;
}

// ============================================================
// ATUALIZAR SENHA
// ============================================================

async function atualizarSenha(
    id,
    novaSenhaHash
) {

    await prepararBanco();

    const usuario =
        db.data.usuarios.find(
            item =>
                item &&
                String(item.id) ===
                String(id)
        );

    if (!usuario) {
        return null;
    }

    usuario.senha =
        novaSenhaHash;

    usuario.atualizadoEm =
        new Date().toISOString();

    await db.write();

    return usuario;
}

// ============================================================
// ATUALIZAR PERFIL
// ============================================================

async function atualizarPerfil(
    id,
    dados
) {

    await prepararBanco();

    const usuario =
        db.data.usuarios.find(
            item =>
                item &&
                String(item.id) ===
                String(id)
        );

    if (!usuario) {
        return null;
    }

    if (
        dados &&
        typeof dados === "object"
    ) {

        if (
            dados.nome !== undefined &&
            dados.nome !== null
        ) {
            usuario.nome =
                String(dados.nome).trim();
        }

        if (
            dados.telefone !== undefined &&
            dados.telefone !== null
        ) {
            usuario.telefone =
                String(dados.telefone).trim();
        }

        if (
            dados.email !== undefined &&
            dados.email !== null
        ) {
            usuario.email =
                String(dados.email)
                    .trim()
                    .toLowerCase();
        }

        if (
            dados.cpf !== undefined &&
            dados.cpf !== null
        ) {
            usuario.cpf =
                String(dados.cpf).trim();
        }
    }

    usuario.atualizadoEm =
        new Date().toISOString();

    await db.write();

    return usuario;
}

// ============================================================
// ATUALIZAR ENDEREÇO
// ============================================================

async function atualizarEndereco(
    id,
    endereco
) {

    await prepararBanco();

    const usuario =
        db.data.usuarios.find(
            item =>
                item &&
                String(item.id) ===
                String(id)
        );

    if (!usuario) {
        return null;
    }

    usuario.endereco = {
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

    usuario.atualizadoEm =
        new Date().toISOString();

    await db.write();

    return usuario;
}

// ============================================================
// SALVAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function salvarCodigoRecuperacao(
    id,
    codigo,
    expiracao
) {

    await prepararBanco();

    const usuario =
        db.data.usuarios.find(
            item =>
                item &&
                String(item.id) ===
                String(id)
        );

    if (!usuario) {
        return null;
    }

    usuario.codigoRecuperacao =
        String(codigo);

    usuario.codigoRecuperacaoExpiracao =
        Number(expiracao);

    usuario.atualizadoEm =
        new Date().toISOString();

    await db.write();

    return usuario;
}

// ============================================================
// BUSCAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function buscarPorCodigoRecuperacao(
    email,
    codigo
) {

    await prepararBanco();

    const emailNormalizado =
        String(email || "")
            .trim()
            .toLowerCase();

    const codigoNormalizado =
        String(codigo || "").trim();

    const agora = Date.now();

    const usuario =
        db.data.usuarios.find(
            item =>
                item &&
                String(item.email || "")
                    .trim()
                    .toLowerCase() ===
                    emailNormalizado &&

                String(
                    item.codigoRecuperacao || ""
                ) ===
                    codigoNormalizado &&

                Number(
                    item.codigoRecuperacaoExpiracao || 0
                ) > agora
        );

    return usuario || null;
}

// ============================================================
// LIMPAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function limparCodigoRecuperacao(
    id
) {

    await prepararBanco();

    const usuario =
        db.data.usuarios.find(
            item =>
                item &&
                String(item.id) ===
                String(id)
        );

    if (!usuario) {
        return null;
    }

    delete usuario.codigoRecuperacao;
    delete usuario.codigoRecuperacaoExpiracao;

    usuario.atualizadoEm =
        new Date().toISOString();

    await db.write();

    return usuario;
}

// ============================================================
// EXCLUIR USUÁRIO
// ============================================================

async function excluir(id) {

    await prepararBanco();

    const indice =
        db.data.usuarios.findIndex(
            usuario =>
                usuario &&
                String(usuario.id) ===
                String(id)
        );

    if (indice === -1) {
        return false;
    }

    db.data.usuarios.splice(
        indice,
        1
    );

    await db.write();

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

    await prepararBanco();

    return db.data.usuarios;
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

