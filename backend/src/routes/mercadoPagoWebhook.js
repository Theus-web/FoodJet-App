const express = require("express");

const router =
  express.Router();

const controller =
  require("../controllers/mercadoPagoWebhookController");

// ============================================================
// MERCADO PAGO WEBHOOK
// POST /api/mercadopago/webhook
// ============================================================

router.post(
  "/webhook",
  controller.webhook
);

module.exports = router;