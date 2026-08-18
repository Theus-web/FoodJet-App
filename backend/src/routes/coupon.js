const express = require("express");

const router = express.Router();

const couponController =
    require("../controllers/coupon_controller");

// Criar
router.post(
    "/",
    couponController.criar
);

// Listar por restaurante
router.get(
    "/restaurante/:restauranteId",
    couponController.listar
);

// Validar
router.post(
    "/validar",
    couponController.validar
);

// Atualizar
router.put(
    "/:id",
    couponController.atualizar
);

// Ativar / desativar
router.patch(
    "/:id/status",
    couponController.alterarStatus
);

// Excluir
router.delete(
    "/:id",
    couponController.excluir
);

module.exports = router;