const express = require("express");
const router = express.Router();

const autenticar = require("../middlewares/authMiddleware");
const favoriteController = require("../controllers/favoriteController");

// LISTAR FAVORITOS DO USUÁRIO
router.get("/", autenticar, favoriteController.listar);

// ADICIONAR FAVORITO
router.post("/", autenticar, favoriteController.salvar);

// REMOVER FAVORITO
router.delete("/:restauranteId", autenticar, favoriteController.remover);

module.exports = router;