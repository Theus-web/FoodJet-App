const express = require("express");
const router = express.Router();

const deliveryController = require("../controllers/deliveryController");

console.log("✅ ROTA ENTREGADORES CARREGADA");

// Cadastro
router.post("/", deliveryController.create);

// Lista
router.get("/", deliveryController.list);

// Online / Offline
router.put("/:id/status", deliveryController.status);

// Pedido atual do entregador
router.get("/:id/orders", deliveryController.myOrders);

// Entregas disponíveis
router.get("/available/orders", deliveryController.availableOrders);

// Aceitar entrega
router.put("/:id/orders/:orderId/accept", deliveryController.acceptOrder);

// Chegou ao restaurante
router.put("/orders/:orderId/arrived", deliveryController.arrivedRestaurant);

// Saiu para entrega
router.put("/orders/:orderId/start", deliveryController.startDelivery);

// Finalizar entrega
router.put("/orders/:orderId/finish", deliveryController.finishDelivery);

module.exports = router;