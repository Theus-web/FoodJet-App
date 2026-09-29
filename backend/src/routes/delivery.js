
const express = require("express");

const router = express.Router();

const deliveryController = require("../controllers/deliveryController");

console.log("✅ ROTA ENTREGADORES CARREGADA");

// ============================================================
// CADASTRAR ENTREGADOR
// ============================================================

router.post(
    "/",
    deliveryController.create
);

// ============================================================
// LISTAR ENTREGADORES
// ============================================================

router.get(
    "/",
    deliveryController.list
);

// ============================================================
// PEDIDOS DISPONÍVEIS
//
// IMPORTANTE:
// Esta rota precisa ficar ANTES de /:id/orders
// para não ser interpretada como um ID.
// ============================================================

router.get(
    "/available/orders",
    deliveryController.availableOrders
);

// ============================================================
// PEDIDOS DO ENTREGADOR
// ============================================================

router.get(
    "/:id/orders",
    deliveryController.myOrders
);

// ============================================================
// ONLINE / OFFLINE
// ============================================================

router.put(
    "/:id/status",
    deliveryController.status
);

// ============================================================
// ACEITAR PEDIDO
// ============================================================

router.put(
    "/:id/orders/:orderId/accept",
    deliveryController.acceptOrder
);

// ============================================================
// CHEGOU AO RESTAURANTE
// ============================================================

router.put(
    "/orders/:orderId/arrived",
    deliveryController.arrivedRestaurant
);

// ============================================================
// INICIAR ENTREGA
// ============================================================

router.put(
    "/orders/:orderId/start",
    deliveryController.startDelivery
);

// ============================================================
// FINALIZAR ENTREGA
// ============================================================

router.put(
    "/orders/:orderId/finish",
    deliveryController.finishDelivery
);

module.exports = router;

