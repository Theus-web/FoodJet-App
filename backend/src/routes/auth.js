const express = require("express");

const router = express.Router();

const authController = require("../controllers/authController");
const autenticar = require("../middlewares/authMiddleware");


// ============================================================
// VERIFICAR CONTROLLER
// ============================================================

console.log("🔐 AUTH CONTROLLER CARREGADO");

console.log(
    "Funções disponíveis:",
    Object.keys(authController)
);


// ============================================================
// EXCLUIR CONTA
// ============================================================

router.delete(
    "/excluir-conta",
    autenticar,
    authController.excluirConta
);


// ============================================================
// TESTE
// ============================================================

router.get("/", (req, res) => {
    res.json({
        sucesso: true,
        mensagem: "AUTH FUNCIONANDO"
    });
});


// ============================================================
// CADASTRO
// ============================================================

router.post(
    "/register",
    authController.register
);


// ============================================================
// LOGIN
// ============================================================

router.post(
    "/login",
    authController.login
);


// ============================================================
// VALIDAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

router.post(
    "/validar-codigo",
    authController.validarCodigoRecuperacao
);


// ============================================================
// REDEFINIR SENHA
// ============================================================

router.post(
    "/redefinir-senha",
    authController.redefinirSenha
);


// ============================================================
// ALTERAR SENHA
// ============================================================

router.put(
    "/alterar-senha",
    autenticar,
    authController.alterarSenha
);


// ============================================================
// PERFIL
// ============================================================

router.get(
    "/perfil",
    autenticar,
    authController.perfil
);


// ============================================================
// ATUALIZAR PERFIL
// ============================================================

router.put(
    "/perfil",
    autenticar,
    authController.atualizarPerfil
);

router.post(
"/solicitar-recuperacao",
authController.solicitarRecuperacao
);


// ============================================================
// ATUALIZAR ENDEREÇO
// ============================================================

router.put(
    "/endereco",
    autenticar,
    authController.atualizarEndereco
);


// ============================================================
// EXPORTAR
// ============================================================

module.exports = router;