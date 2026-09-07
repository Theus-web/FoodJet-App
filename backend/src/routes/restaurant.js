const express = require("express");

const router = express.Router();

const restaurantController =
    require("../controllers/restaurantController");

console.log(
    "✅ ROTA RESTAURANTES CARREGADA"
);

// ============================================================
// CRIAR RESTAURANTE
// ============================================================

router.post(
    "/",
    restaurantController.create
);

// ============================================================
// LISTAR RESTAURANTES
// ============================================================

router.get(
    "/",
    restaurantController.list
);

// ============================================================
// BUSCAR RESTAURANTE POR ID
// ============================================================

router.get(
    "/:id",
    restaurantController.getById
);

// ============================================================
// ONLINE / OFFLINE
// ============================================================

router.put(
    "/:id/status",
    restaurantController.updateStatus
);

// ============================================================
// ATUALIZAR CONFIGURAÇÕES
// ============================================================

router.put(
    "/:id",
    restaurantController.update
);

// ============================================================
// UPLOAD DA CAPA
// ============================================================

router.post(
    "/:id/capa",
    restaurantController.uploadCapa
);

// ============================================================
// REMOVER CAPA
// ============================================================

router.delete(
    "/:id/capa",
    restaurantController.deleteCapa
);

// ============================================================
// UPLOAD DO LOGO
// ============================================================

router.post(
    "/:id/logo",
    restaurantController.uploadLogo
);

// ============================================================
// REMOVER LOGO
// ============================================================

router.delete(
    "/:id/logo",
    restaurantController.deleteLogo
);

// ============================================================
// EXCLUIR CONTA DO RESTAURANTE
// ============================================================

router.delete(
    "/:id",
    restaurantController.delete
);

module.exports = router;