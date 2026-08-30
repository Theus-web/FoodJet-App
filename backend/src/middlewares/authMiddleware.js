const Token = require("../services/tokenService");
const User = require("../models/user");

// ================================================
// AUTENTICAR USUÁRIO
// ================================================

async function autenticar(req, res, next) {
try {


    const authHeader =
        req.headers.authorization;

    if (!authHeader) {
        return res.status(401).json({
            sucesso: false,
            erro: "Token não informado"
        });
    }

    if (!authHeader.startsWith("Bearer ")) {
        return res.status(401).json({
            sucesso: false,
            erro: "Formato de token inválido"
        });
    }

    const token =
        authHeader
            .replace("Bearer ", "")
            .trim();

    if (!token) {
        return res.status(401).json({
            sucesso: false,
            erro: "Token não informado"
        });
    }

    // ========================================
    // VALIDAR TOKEN
    // ========================================

    const usuarioToken =
        Token.verificarToken(token);

    if (
        !usuarioToken ||
        !usuarioToken.id
    ) {
        return res.status(401).json({
            sucesso: false,
            erro: "Token não possui usuário válido"
        });
    }

    // ========================================
    // BUSCAR USUÁRIO NO BANCO
    // ========================================

    let usuarioBanco = null;

    if (
        typeof User.buscarId === "function"
    ) {
        usuarioBanco =
            await User.buscarId(
                usuarioToken.id
            );
    }

    if (
        !usuarioBanco &&
        usuarioToken.email &&
        typeof User.buscarEmail === "function"
    ) {
        usuarioBanco =
            await User.buscarEmail(
                usuarioToken.email
            );
    }

    // ========================================
    // USUÁRIO NÃO ENCONTRADO
    // ========================================

    if (!usuarioBanco) {

        console.error(
            "❌ USUÁRIO NÃO ENCONTRADO:",
            usuarioToken.id
        );

        return res.status(401).json({
            sucesso: false,
            erro: "Usuário não encontrado."
        });
    }

    // ========================================
    // USUÁRIO AUTENTICADO
    // ========================================

    const usuarioAutenticado = {

        id:
            usuarioBanco.id ||
            usuarioToken.id,

        nome:
            usuarioBanco.nome ||
            usuarioToken.nome ||
            "",

        email:
            usuarioBanco.email ||
            usuarioToken.email ||
            "",

        telefone:
            usuarioBanco.telefone ||
            usuarioBanco.celular ||
            usuarioToken.telefone ||
            "",

        cpf:
            usuarioBanco.cpf ||
            usuarioBanco.cpfCnpj ||
            usuarioToken.cpf ||
            "",

        cpfCnpj:
            usuarioBanco.cpfCnpj ||
            usuarioBanco.cpf ||
            usuarioToken.cpfCnpj ||
            usuarioToken.cpf ||
            "",

        tipo:
            usuarioBanco.tipo ||
            usuarioToken.tipo ||
            ""
    };

    // ========================================
    // IMPORTANTE
    //
    // req.usuario = padrão atual
    // req.user = compatibilidade
    // ========================================

    req.usuario =
        usuarioAutenticado;

    req.user =
        usuarioAutenticado;

    // ========================================
    // LOG
    // ========================================

    console.log(
        "========================================"
    );

    console.log(
        "✅ USUÁRIO AUTENTICADO"
    );

    console.log(
        "ID:",
        req.usuario.id
    );

    console.log(
        "NOME:",
        req.usuario.nome
    );

    console.log(
        "EMAIL:",
        req.usuario.email
    );

    console.log(
        "CPF:",
        req.usuario.cpf
            ? "CADASTRADO"
            : "NÃO CADASTRADO"
    );

    console.log(
        "TELEFONE:",
        req.usuario.telefone
            ? "CADASTRADO"
            : "NÃO CADASTRADO"
    );

    console.log(
        "TIPO:",
        req.usuario.tipo
    );

    console.log(
        "========================================"
    );

    next();

} catch (error) {

    console.error(
        "❌ ERRO AO VALIDAR TOKEN:",
        error.message
    );

    return res.status(401).json({
        sucesso: false,
        erro: "Token inválido ou expirado"
    });
}


}

module.exports = autenticar;
