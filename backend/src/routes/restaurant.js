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

router.delete(
    "/:id",
    restaurantController.delete
);

// ==================================================
// UPLOAD DA CAPA
// POST /api/restaurants/:id/capa
// ==================================================

router.post(
    "/:id/capa",
    restaurantController.uploadCapa
);

// ==================================================
// REMOVER CAPA
// DELETE /api/restaurants/:id/capa
// ==================================================

router.delete(
    "/:id/capa",
    restaurantController.deleteCapa
);

// ==================================================
// UPLOAD DA LOGO
// POST /api/restaurants/:id/logo
// ==================================================

router.post(
    "/:id/logo",
    restaurantController.uploadLogo
);

// ==================================================
// REMOVER LOGO
// DELETE /api/restaurants/:id/logo
// ==================================================

router.delete(
    "/:id/logo",
    restaurantController.deleteLogo
);

module.exports = router;