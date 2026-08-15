module.exports = (req, res, next) => {

    if (!req.usuario) {
        return res.status(401).json({
            mensagem: "Não autenticado"
        });
    }

    if (req.usuario.tipo !== "ADMIN") {
        return res.status(403).json({
            mensagem: "Acesso permitido apenas para administradores"
        });
    }

    next();

};

