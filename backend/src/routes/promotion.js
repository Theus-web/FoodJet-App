const express = require("express");

const router = express.Router();

const controller =
require("../controllers/promotionController");



router.post(
    "/",
    controller.create
);


router.get(
    "/restaurante/:id",
    controller.listarRestaurante
);


router.get(
    "/",
    controller.listarAtivas
);


router.put(
    "/:id/status",
    controller.status
);


router.delete(
    "/:id",
    controller.delete
);



module.exports = router;