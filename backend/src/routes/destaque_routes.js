const express = require("express");

const router = express.Router();

const destaqueController = require("../controllers/destaque_controller");


// ==================================================
// ATIVAR DESTAQUE
// PUT /api/destaque/:id
//
// Body:
// {
//   "dias": 30,
//   "plano": "30_DIAS"
// }
// ==================================================

router.put(
    "/:id",
    destaqueController.ativar
);



// ==================================================
// REMOVER DESTAQUE
// DELETE /api/destaque/:id
// ==================================================

router.delete(
    "/:id",
    destaqueController.remover
);



// ==================================================
// VER STATUS
// GET /api/destaque/:id
// ==================================================

router.get(
    "/:id",
    destaqueController.status
);



module.exports = router;