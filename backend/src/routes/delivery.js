const express = require("express");

const router = express.Router();

const deliveryController = require("../controllers/deliveryController");


console.log("✅ ROTA ENTREGADORES CARREGADA");


router.post("/", deliveryController.create);


router.get("/", deliveryController.list);


// Entregador fica online/offline
router.put("/:id/status", deliveryController.status);


// Buscar entrega atual do entregador
router.get("/:id/orders", deliveryController.myOrders);


module.exports = router;
