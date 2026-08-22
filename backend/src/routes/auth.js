const express = require("express");

const router = express.Router();

const authController = require("../controllers/authController");
const autenticar = require("../middlewares/authMiddleware");

// ============================================================
// STATUS
// GET /api/auth
// ============================================================

router.get("/", (req, res) => {
    res.json({
        sucesso: true,
        mensagem: "AUTH FUNCIONANDO"
    });
});

// ============================================================
// CADASTRO
// POST /api/auth/register
// ============================================================

router.post(
    "/register",
    authController.register
);

// ============================================================
// LOGIN
// POST /api/auth/login
// ============================================================

router.post(
    "/login",
    authController.login
);

// ============================================================
// VALIDAR CÓDIGO DE RECUPERAÇÃO
// POST /api/auth/validar-codigo-recuperacao
// ============================================================

router.post(
    "/validar-codigo-recuperacao",
    authController.validarCodigoRecuperacao
);

// ============================================================
// REDEFINIR SENHA
// POST /api/auth/redefinir-senha
// ============================================================

router.post(
    "/redefinir-senha",
    authController.redefinirSenha
);

// ============================================================
// ALTERAR SENHA LOGADO
// PUT /api/auth/alterar-senha
// ============================================================

router.put(
    "/alterar-senha",
    autenticar,
    authController.alterarSenha
);

// ============================================================
// PERFIL
// GET /api/auth/perfil
// ============================================================

router.get(
    "/perfil",
    autenticar,
    authController.perfil
);

// ============================================================
// ATUALIZAR PERFIL
// PUT /api/auth/perfil
// ============================================================

router.put(
    "/perfil",
    autenticar,
    authController.atualizarPerfil
);

// ============================================================
// RECUPERAR SENHA
// POST /api/auth/recuperar-senha
// ============================================================

router.post(
    "/recuperar-senha",
    authController.solicitarRecuperacao
);

// ============================================================
// ENDEREÇO
// PUT /api/auth/endereco
// ============================================================

router.put(
    "/endereco",
    autenticar,
    authController.atualizarEndereco
);

// ============================================================
// EXCLUIR CONTA
// DELETE /api/auth/conta
// ============================================================

router.delete(
    "/conta",
    autenticar,
    authController.excluirConta
);

// ============================================================
// EXPORTAR
// ============================================================

module.exports = router;