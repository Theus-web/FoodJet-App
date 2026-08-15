const express = require("express");

const router = express.Router();

const complaintController =
    require("../controllers/complaintController");

console.log(
    "✅ ROTA RECLAMAÇÕES CARREGADA"
);

// ======================================================
// CRIAR RECLAMAÇÃO
// ======================================================

router.post(
    "/",
    complaintController.create
);

// ======================================================
// LISTAR TODAS
// ======================================================

router.get(
    "/",
    complaintController.list
);

// ======================================================
// RECLAMAÇÕES DO PEDIDO
// ======================================================

router.get(
    "/pedido/:id",
    complaintController.byOrder
);

// ======================================================
// RECLAMAÇÕES DO RESTAURANTE
// ======================================================

router.get(
    "/restaurante/:id",
    complaintController.byRestaurant
);

// ======================================================
// ATUALIZAR STATUS
// ======================================================

router.put(
    "/:id",
    complaintController.updateStatus
);

module.exports = router;