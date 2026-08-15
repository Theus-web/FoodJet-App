
const express = require("express");

const router = express.Router();

const restaurantController =
    require("../controllers/restaurantController");

console.log("✅ ROTA RESTAURANTES CARREGADA");

// ==================================================
// CRIAR
// ==================================================

router.post(
    "/",
    restaurantController.create
);

// ==================================================
// LISTAR
// ==================================================

router.get(
    "/",
    restaurantController.list
);

// ==================================================
// BUSCAR POR ID
// ==================================================

router.get(
    "/:id",
    restaurantController.getById
);

// ==================================================
// ONLINE / OFFLINE
// ==================================================

router.put(
    "/:id/status",
    restaurantController.updateStatus
);

// ==================================================
// ATUALIZAR CONFIGURAÇÕES
// PUT /api/restaurants/:id
// ==================================================

router.put(
    "/:id",
    restaurantController.update
);

// ==================================================
// EXCLUIR CONTA
// DELETE /api/restaurants/:id
// ==================================================
//
// LGPD:
// Permite que o restaurante solicite a exclusão
// da própria conta.
//
// ==================================================

router.delete(
    "/:id",
    restaurantController.delete
);

module.exports = router;

