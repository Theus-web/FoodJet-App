const express = require("express");

const router = express.Router();

const financeController = require("../controllers/finance_controller");

// =====================================================
// RESUMO FINANCEIRO
// GET /api/finance/:restauranteId
// =====================================================

router.get(
    "/:restauranteId",
    financeController.resumo
);

// =====================================================
// SOLICITAR SAQUE AUTOMÁTICO
// POST /api/finance/:restauranteId/saque
// =====================================================

router.post(
    "/:restauranteId/saque",
    financeController.solicitarSaque
);

module.exports = router;