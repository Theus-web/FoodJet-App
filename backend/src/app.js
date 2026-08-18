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

app.use(express.json());

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
// Cliente ↔ Restaurante
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
// CUPONS
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
// LOGS
// ======================================================

console.log(
    "🏆 ROTA /api/coupons REGISTRADA"
);

console.log(
    "🏆 ROTA /api/ranking REGISTRADA"
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
// EXPORTAR APP
// ======================================================

module.exports = app;