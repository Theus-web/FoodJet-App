const express = require("express");
const cors = require("cors");
const path = require("path");

const authRoutes = require("./routes/auth");
const restaurantRoutes = require("./routes/restaurant");
const productRoutes = require("./routes/product");
const orderRoutes = require("./routes/order");
const deliveryRoutes = require("./routes/delivery");
const adminRoutes = require("./routes/admin");
const dashboardRoutes = require("./routes/dashboard");
const supportRoutes = require("./routes/support");
const complaintRoutes = require("./routes/complaint");
const promotionRoutes = require("./routes/promotion");
const couponRoutes = require("./routes/coupon");
const favoriteRoutes = require("./routes/favorite");

const app = express();

// ======================================================
// MIDDLEWARES
// ======================================================

app.use(
    cors({
        origin: "*",
        methods: [
            "GET",
            "POST",
            "PUT",
            "DELETE",
            "OPTIONS"
        ],
        allowedHeaders: [
            "Content-Type",
            "Authorization"
        ]
    })
);

// IMPORTANTE:
// express.json() precisa vir ANTES das rotas.
app.use(express.json());

// Arquivos enviados
app.use(
    "/uploads",
    express.static(
        path.join(
            process.cwd(),
            "uploads"
        )
    )
);

// ======================================================
// ROTAS
// ======================================================

app.use(
    "/api/auth",
    authRoutes
);

app.use(
    "/api/restaurants",
    restaurantRoutes
);

app.use(
    "/api/products",
    productRoutes
);

app.use(
    "/api/orders",
    orderRoutes
);

app.use(
    "/api/delivery",
    deliveryRoutes
);

app.use(
    "/api/admin",
    adminRoutes
);

app.use(
    "/api/dashboard",
    dashboardRoutes
);

// ======================================================
// SUPORTE
// ======================================================

app.use(
    "/api/support",
    supportRoutes
);

app.use(
    "/api/complaints",
    complaintRoutes
);

// ======================================================
// CUPONS / PROMOÇÕES
// ======================================================

app.use(
    "/api/coupons",
    couponRoutes
);

app.use(
    "/api/promotions",
    promotionRoutes
);

// ======================================================
// FAVORITOS
// ======================================================

app.use(
    "/api/favoritos",
    favoriteRoutes
);

console.log(
    "❤️ ROTA /api/favoritos REGISTRADA"
);

console.log(
    "🏆 ROTA /api/coupons REGISTRADA"
);

console.log(
    "🏆 ROTA /api/promotions REGISTRADA"
);

console.log(
    "✅ ROTA /api/auth REGISTRADA"
);

console.log(
    "✅ ROTA /api/restaurants REGISTRADA"
);

console.log(
    "✅ ROTA /api/products REGISTRADA"
);

console.log(
    "✅ ROTA /api/orders REGISTRADA"
);

console.log(
    "✅ ROTA /api/delivery REGISTRADA"
);

console.log(
    "✅ ROTA /api/admin REGISTRADA"
);

console.log(
    "✅ ROTA /api/dashboard REGISTRADA"
);

console.log(
    "✅ ROTA /api/support REGISTRADA"
);

console.log(
    "✅ ROTA /api/complaints REGISTRADA"
);

// ======================================================
// ROTA PRINCIPAL
// ======================================================

app.get(
    "/",
    (req, res) => {
        res.json({
            app: "FoodJet",
            status: "online"
        });
    }
);

// ======================================================
// EXPORTAR
// ======================================================

module.exports = app;