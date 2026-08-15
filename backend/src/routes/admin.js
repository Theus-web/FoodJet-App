const express = require("express");

const router = express.Router();

const autenticar = require("../middlewares/authMiddleware");
const admin = require("../middlewares/admin");
const adminController = require("../controllers/adminController");

console.log("✅ ROTA ADMIN CARREGADA");

router.get(
    "/dashboard",
    autenticar,
    admin,
    adminController.dashboard
);

router.get("/users", autenticar, admin, adminController.users);
router.get(
    "/restaurants",
    autenticar,
    admin,
    adminController.restaurants
);

module.exports = router;
