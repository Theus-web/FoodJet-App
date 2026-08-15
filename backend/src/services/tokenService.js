const jwt = require("jsonwebtoken");

// ================================================
// CHAVE SECRETA DO JWT
// ================================================

const JWT_SECRET =
    process.env.JWT_SECRET ||
    "foodjet_chave_secreta_2026";

// ================================================
// CRIAR TOKEN
// ================================================

function criarToken(usuario) {

    if (!usuario) {
        throw new Error(
            "Usuário não informado para criar o token"
        );
    }

    const payload = {
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        tipo: usuario.tipo || "CLIENTE"
    };

    const token = jwt.sign(
        payload,
        JWT_SECRET,
        {
            expiresIn: "7d"
        }
    );

    console.log(
        "🔐 TOKEN JWT CRIADO PARA:",
        usuario.email
    );

    return token;
}

// ================================================
// GERAR TOKEN
// Compatibilidade com authController
// ================================================

function gerar(usuario) {
    return criarToken(usuario);
}

// ================================================
// VERIFICAR TOKEN
// ================================================

function verificarToken(token) {

    if (!token) {
        throw new Error(
            "Token não informado"
        );
    }

    return jwt.verify(
        token,
        JWT_SECRET
    );
}

// ================================================
// EXPORTAR
// ================================================

module.exports = {
    criarToken,
    gerar,
    verificarToken
};