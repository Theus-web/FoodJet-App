const express = require("express");

const router = express.Router();

const autenticar =
  require("../middlewares/authMiddleware");

const paymentController =
  require("../controllers/paymentController");

// ============================================================
// PIX
// ============================================================

router.post(
  "/pix",

  (req, res, next) => {

    console.log("");
    console.log(
      "========================================"
    );
    console.log(
      "🚨 CHEGOU NA ROTA POST /pix"
    );
    console.log(
      "URL:",
      req.originalUrl
    );
    console.log(
      "BODY:",
      JSON.stringify(
        req.body || {},
        null,
        2
      )
    );
    console.log(
      "AUTHORIZATION:",
      req.headers.authorization
        ? "SIM"
        : "NÃO"
    );
    console.log(
      "========================================"
    );

    next();
  },

  autenticar,

  paymentController.gerarPix
);

router.post(
  "/cartao",
  autenticar,
  paymentController.gerarCartao
);


// ============================================================
// STATUS DA CONTA ASAAS
// TEMPORÁRIO - REMOVER APÓS O TESTE
// ============================================================

router.get(
    "/status-conta-asaas",
    autenticar,
    paymentController.statusContaAsaas
);


// ============================================================
// CONSULTAR PAGAMENTO
// ============================================================

router.get(
  "/:pagamentoId",
  autenticar,
  paymentController.consultar
);

module.exports = router;