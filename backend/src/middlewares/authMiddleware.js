const Token = require("../services/tokenService");


// ================================================
// AUTENTICAR USUÁRIO
// ================================================

function autenticar(req, res, next) {

    try {

        const authHeader =
            req.headers.authorization;


        // ========================================
        // VERIFICAR SE TOKEN FOI ENVIADO
        // ========================================

        if (!authHeader) {

            return res.status(401).json({
                erro:
                    "Token não informado"
            });

        }


        // ========================================
        // VERIFICAR FORMATO
        // ========================================

        if (
            !authHeader.startsWith("Bearer ")
        ) {

            return res.status(401).json({
                erro:
                    "Formato de token inválido"
            });

        }


        // ========================================
        // PEGAR TOKEN
        // ========================================

        const token =
            authHeader
                .replace("Bearer ", "")
                .trim();


        if (!token) {

            return res.status(401).json({
                erro:
                    "Token não informado"
            });

        }


        // ========================================
        // VALIDAR TOKEN
        // ========================================

        const usuario =
            Token.verificarToken(
                token
            );


        // ========================================
        // VERIFICAR ID
        // ========================================

        if (!usuario.id) {

            return res.status(401).json({
                erro:
                    "Token não possui usuário válido"
            });

        }


        // ========================================
        // SALVAR USUÁRIO NA REQUISIÇÃO
        // ========================================

        req.usuario = usuario;


        console.log(
            "USUÁRIO AUTENTICADO:",
            usuario.email
        );

        console.log(
            "ID DO USUÁRIO:",
            usuario.id
        );


        // ========================================
        // CONTINUAR
        // ========================================

        next();


    } catch (error) {

        console.error(
            "ERRO AO VALIDAR TOKEN:",
            error.message
        );


        return res.status(401).json({
            erro:
                "Token inválido ou expirado"
        });

    }
}


module.exports = autenticar;