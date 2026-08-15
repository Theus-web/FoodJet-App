const express = require("express");

const router = express.Router();


const dashboardController =
require("../controllers/dashboard_controller");



router.get(
    "/:restauranteId",
    dashboardController.resumo
);



module.exports = router;