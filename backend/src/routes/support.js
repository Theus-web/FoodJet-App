const express = require("express");

const router = express.Router();

const supportController =
    require("../controllers/supportController");

console.log(
    "✅ ROTA SUPORTE CARREGADA"
);

// ======================================================
// CRIAR CHAMADO
// POST /api/support
// ======================================================

router.post(
    "/",
    supportController.create
);

// ======================================================
// LISTAR TODOS
// GET /api/support
// ======================================================

router.get(
    "/",
    supportController.list
);

// ======================================================
// SUPORTES DO CLIENTE
// GET /api/support/cliente/:id
// ======================================================

router.get(
    "/cliente/:id",
    supportController.byCliente
);

// ======================================================
// SUPORTES DO RESTAURANTE
// GET /api/support/restaurante/:id
// ======================================================

router.get(
    "/restaurante/:id",
    supportController.byRestaurante
);

// ======================================================
// SUPORTES DO PEDIDO
// GET /api/support/pedido/:id
// ======================================================

router.get(
    "/pedido/:id",
    supportController.byPedido
);

// ======================================================
// BUSCAR CHAMADO
// GET /api/support/:id
// ======================================================

router.get(
    "/:id",
    supportController.getById
);

// ======================================================
// ATUALIZAR CHAMADO
// PUT /api/support/:id
// ======================================================

router.put(
    "/:id",
    supportController.update
);

// ======================================================
// ADICIONAR MENSAGEM
// POST /api/support/:id/mensagem
// ======================================================

router.post(
    "/:id/mensagem",
    supportController.addMessage
);

module.exports = router;