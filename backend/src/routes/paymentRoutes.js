const express = require("express");

const router = express.Router();

const autenticar =
  require("../middlewares/authMiddleware");

const paymentController =
  require("../controllers/paymentController");

router.post(
  "/pix",
  autenticar,
  paymentController.gerarPix
);

router.get(
  "/:pagamentoId",
  autenticar,
  paymentController.consultar
);

module.exports = router;