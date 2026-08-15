const { db } = require("../config/database");

// ============================================================
// PREPARAR BANCO
// ============================================================

async function prepararBanco() {
    await db.read();

    db.data ||= {};
    db.data.usuarios ||= [];
}

// ============================================================
// CRIAR USUÁRIO
// ============================================================

async function criar(usuario) {
    await prepararBanco();

    db.data.usuarios.push(usuario);

    await db.write();

    console.log("👤 USUÁRIO SALVO:", usuario.email);

    return usuario;
}

// ============================================================
// LISTAR USUÁRIOS
// ============================================================

async function listar() {
    await prepararBanco();

    return db.data.usuarios;
}

// ============================================================
// BUSCAR POR EMAIL
// ============================================================

async function buscarPorEmail(email) {
    await prepararBanco();

    if (!email) {
        return null;
    }

    const emailNormalizado = String(email)
        .trim()
        .toLowerCase();

    return (
        db.data.usuarios.find((usuario) => {
            if (!usuario.email) {
                return false;
            }

            return (
                String(usuario.email)
                    .trim()
                    .toLowerCase() === emailNormalizado
            );
        }) || null
    );
}

// ============================================================
// BUSCAR POR ID
// ============================================================

async function buscarPorId(id) {
    await prepararBanco();

    if (id === undefined || id === null) {
        return null;
    }

    return (
        db.data.usuarios.find((usuario) => {
            return String(usuario.id) === String(id);
        }) || null
    );
}

// ============================================================
// ATUALIZAR SENHA
// ============================================================

async function atualizarSenha(id, senha) {
    await prepararBanco();

    const usuario = db.data.usuarios.find((usuario) => {
        return String(usuario.id) === String(id);
    });

    if (!usuario) {
        return false;
    }

    usuario.senha = String(senha);

    usuario.atualizadoEm = new Date().toISOString();

    await db.write();

    console.log(
        "🔑 SENHA ATUALIZADA:",
        usuario.email
    );

    return true;
}

// ============================================================
// ATUALIZAR PERFIL
// ============================================================

async function atualizarPerfil(id, dados) {
    await prepararBanco();

    const usuario = db.data.usuarios.find((usuario) => {
        return String(usuario.id) === String(id);
    });

    if (!usuario) {
        return null;
    }

    if (dados.nome !== undefined) {
        usuario.nome = dados.nome;
    }

    if (dados.telefone !== undefined) {
        usuario.telefone = dados.telefone;
    }

    if (dados.email !== undefined) {
        usuario.email = String(dados.email)
            .trim()
            .toLowerCase();
    }

    if (dados.cpf !== undefined) {
        usuario.cpf = dados.cpf;
    }

    usuario.atualizadoEm = new Date().toISOString();

    await db.write();

    return usuario;
}

// ============================================================
// ATUALIZAR ENDEREÇO
// ============================================================

async function atualizarEndereco(id, endereco) {
    await prepararBanco();

    const usuario = db.data.usuarios.find((usuario) => {
        return String(usuario.id) === String(id);
    });

    if (!usuario) {
        return null;
    }

    usuario.endereco = {
        ...(usuario.endereco || {}),
        ...endereco,
    };

    usuario.atualizadoEm = new Date().toISOString();

    await db.write();

    return usuario;
}

// ============================================================
// EXCLUIR CONTA
// ============================================================

async function excluir(id) {
    await prepararBanco();

    const antes = db.data.usuarios.length;

    db.data.usuarios = db.data.usuarios.filter((usuario) => {
        return String(usuario.id) !== String(id);
    });

    const removido =
        db.data.usuarios.length < antes;

    if (removido) {
        await db.write();
    }

    return removido;
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

    const usuario = db.data.usuarios.find((usuario) => {
        return String(usuario.id) === String(id);
    });

    if (!usuario) {
        console.log(
            "❌ USUÁRIO NÃO ENCONTRADO PARA SALVAR CÓDIGO:",
            id
        );

        return false;
    }

    // --------------------------------------------------------
    // NORMALIZAR CÓDIGO
    // --------------------------------------------------------

    const codigoNormalizado = String(codigo)
        .trim();

    // --------------------------------------------------------
    // NORMALIZAR EXPIRAÇÃO
    // --------------------------------------------------------

    const expiracaoNormalizada = Number(expiracao);

    if (
        !codigoNormalizado ||
        codigoNormalizado.length !== 6
    ) {
        console.log(
            "❌ CÓDIGO INVÁLIDO AO SALVAR:",
            codigo
        );

        return false;
    }

    if (
        !Number.isFinite(expiracaoNormalizada)
    ) {
        console.log(
            "❌ EXPIRAÇÃO INVÁLIDA:",
            expiracao
        );

        return false;
    }

    // --------------------------------------------------------
    // SALVAR
    // --------------------------------------------------------

    usuario.codigoRecuperacao =
        codigoNormalizado;

    usuario.codigoRecuperacaoExpira =
        expiracaoNormalizada;

    await db.write();

    console.log("");
    console.log(
        "=========================================="
    );
    console.log(
        "💾 CÓDIGO DE RECUPERAÇÃO SALVO"
    );
    console.log(
        "=========================================="
    );

    console.log(
        "👤 Usuário:",
        usuario.email
    );

    console.log(
        "🆔 ID:",
        usuario.id
    );

    console.log(
        "🔢 Código:",
        usuario.codigoRecuperacao
    );

    console.log(
        "⏰ Expiração:",
        usuario.codigoRecuperacaoExpira
    );

    console.log(
        "📅 Expira em:",
        new Date(
            usuario.codigoRecuperacaoExpira
        ).toLocaleString()
    );

    console.log(
        "=========================================="
    );

    return true;
}

// ============================================================
// BUSCAR POR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function buscarPorCodigoRecuperacao(
    email,
    codigo
) {
    await prepararBanco();

    // --------------------------------------------------------
    // NORMALIZAR EMAIL
    // --------------------------------------------------------

    const emailNormalizado = String(email || "")
        .trim()
        .toLowerCase();

    // --------------------------------------------------------
    // NORMALIZAR CÓDIGO
    // --------------------------------------------------------

    const codigoNormalizado = String(codigo || "")
        .trim();

    console.log("");
    console.log(
        "=========================================="
    );
    console.log(
        "🔎 VALIDANDO CÓDIGO DE RECUPERAÇÃO"
    );
    console.log(
        "=========================================="
    );

    console.log(
        "📧 Email recebido:",
        emailNormalizado
    );

    console.log(
        "🔢 Código recebido:",
        codigoNormalizado
    );

    if (
        !emailNormalizado ||
        !codigoNormalizado
    ) {
        console.log(
            "❌ EMAIL OU CÓDIGO VAZIO"
        );

        return null;
    }

    // --------------------------------------------------------
    // LOCALIZAR USUÁRIO PELO EMAIL
    // --------------------------------------------------------

    const usuario = db.data.usuarios.find(
        (usuario) => {

            if (!usuario.email) {
                return false;
            }

            const emailUsuario =
                String(usuario.email)
                    .trim()
                    .toLowerCase();

            return (
                emailUsuario ===
                emailNormalizado
            );
        }
    );

    if (!usuario) {
        console.log(
            "❌ USUÁRIO NÃO ENCONTRADO"
        );

        return null;
    }

    console.log(
        "✅ USUÁRIO ENCONTRADO:",
        usuario.id
    );

    // --------------------------------------------------------
    // VERIFICAR SE EXISTE CÓDIGO
    // --------------------------------------------------------

    if (
        usuario.codigoRecuperacao ===
        undefined ||
        usuario.codigoRecuperacao ===
        null
    ) {
        console.log(
            "❌ USUÁRIO NÃO POSSUI CÓDIGO"
        );

        return null;
    }

    // --------------------------------------------------------
    // NORMALIZAR CÓDIGO SALVO
    // --------------------------------------------------------

    const codigoSalvo =
        String(
            usuario.codigoRecuperacao
        ).trim();

    console.log(
        "🔢 Código salvo:",
        codigoSalvo
    );

    // --------------------------------------------------------
    // COMPARAR CÓDIGOS
    // --------------------------------------------------------

    const codigoCorreto =
        codigoSalvo ===
        codigoNormalizado;

    console.log(
        "🔢 Código correto:",
        codigoCorreto
    );

    if (!codigoCorreto) {
        console.log(
            "❌ CÓDIGO NÃO CONFERE"
        );

        return null;
    }

    // --------------------------------------------------------
    // VERIFICAR EXPIRAÇÃO
    // --------------------------------------------------------

    const expiracao =
        Number(
            usuario.codigoRecuperacaoExpira
        );

    console.log(
        "⏰ Expiração:",
        expiracao
    );

    console.log(
        "⏰ Agora:",
        Date.now()
    );

    if (
        !Number.isFinite(expiracao)
    ) {
        console.log(
            "❌ EXPIRAÇÃO INVÁLIDA"
        );

        return null;
    }

    if (
        Date.now() >= expiracao
    ) {
        console.log(
            "❌ CÓDIGO EXPIRADO"
        );

        return null;
    }

    // --------------------------------------------------------
    // CÓDIGO VÁLIDO
    // --------------------------------------------------------

    console.log(
        "=========================================="
    );

    console.log(
        "✅ CÓDIGO VÁLIDO"
    );

    console.log(
        "=========================================="
    );

    return usuario;
}

// ============================================================
// LIMPAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function limparCodigoRecuperacao(id) {
    await prepararBanco();

    const usuario = db.data.usuarios.find((usuario) => {
        return String(usuario.id) === String(id);
    });

    if (!usuario) {
        return false;
    }

    delete usuario.codigoRecuperacao;

    delete usuario.codigoRecuperacaoExpira;

    await db.write();

    console.log(
        "🧹 CÓDIGO DE RECUPERAÇÃO REMOVIDO:",
        usuario.email
    );

    return true;
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
    criar,
    criarUsuario: criar,
    listar,
    buscarPorEmail,
    buscarPorId,
    atualizarSenha,
    atualizarPerfil,
    atualizarEndereco,
    excluir,
    salvarCodigoRecuperacao,
    buscarPorCodigoRecuperacao,
    limparCodigoRecuperacao,
};