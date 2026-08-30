const express = require("express");

const router = express.Router();

const orderController =
    require("../controllers/orderController");

const autenticar =
    require("../middlewares/authMiddleware");

console.log("✅ ROTA PEDIDOS CARREGADA");

// ======================================================
// CRIAR PEDIDO
// ======================================================

router.post(
    "/",
    autenticar,
    orderController.create
);

// ======================================================
// LISTAR TODOS
// ======================================================

router.get(
    "/",
    orderController.list
);

// ======================================================
// PEDIDOS DO RESTAURANTE
// IMPORTANTE: ANTES DE /:id
// ======================================================

router.get(
    "/restaurante/:id",
    orderController.restaurantOrders
);

// ======================================================
// PEDIDOS DO CLIENTE
// ======================================================

router.get(
    "/cliente/:id",
    autenticar,
    orderController.clientOrders
);

// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ======================================================

router.get(
    "/delivery/available",
    orderController.availableDeliveries
);

// ======================================================
// BUSCAR PEDIDO PELO ID
// ======================================================

router.get(
    "/:id",
    orderController.getById
);

// ======================================================
// ATUALIZAR STATUS
// ======================================================

router.put(
    "/:id/status",
    orderController.updateStatus
);

// ======================================================
// RESTAURANTE ACEITA PEDIDO
// ======================================================

router.put(
    "/:id/accept",
    orderController.acceptRestaurant
);

// ======================================================
// RESTAURANTE RECUSA PEDIDO
// ======================================================

router.put(
    "/:id/reject",
    orderController.rejectRestaurant
);

// ======================================================
// ENTREGADOR ACEITA
// ======================================================

router.put(
    "/:id/accept-delivery",
    orderController.acceptDelivery
);

// ======================================================
// ENTREGADOR FINALIZA
// ======================================================

router.put(
    "/:id/complete",
    orderController.completeDelivery
);

// ======================================================
// CLIENTE/RESTAURANTE ABRE SUPORTE
// ======================================================

router.post(
    "/:id/support",
    orderController.openSupport
);

module.exports = router;