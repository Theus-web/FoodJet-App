require("dotenv").config();

console.log("========================================");
console.log("🔐 MERCADO PAGO");
console.log(
  "TOKEN CARREGADO:",
  process.env.MERCADOPAGO_ACCESS_TOKEN
    ? "SIM"
    : "NÃO"
);
console.log(
  "TIPO:",
  process.env.MERCADOPAGO_ACCESS_TOKEN?.startsWith("TEST-")
    ? "TESTE"
    : process.env.MERCADOPAGO_ACCESS_TOKEN?.startsWith("APP_USR-")
      ? "PRODUÇÃO"
      : "DESCONHECIDO"
);
console.log("========================================");

const http = require("http");
const app = require("./app");

const { Server } = require("socket.io");

const { conectar } = require("./config/database");

const promotionRoutes =  require("./routes/promotion");
    
const paymentRoutes = require("./routes/paymentRoutes");

app.use(
  "/api/pagamentos",
  paymentRoutes
);

console.log("🔥 ROTAS DE PROMOÇÃO CARREGADAS");

app.use(
 "/api/promocoes",
 promotionRoutes
);

const mercadoPagoWebhookRoutes =
  require("./routes/mercadoPagoWebhook");

app.use(
  "/api/mercadopago",
  mercadoPagoWebhookRoutes
);

// ============================================================
// CONFIGURAÇÕES
// ============================================================

const PORT = process.env.PORT || 3000;

// ============================================================
// ROTAS FINANCEIRAS
// ============================================================

const financeRoutes = require("./routes/finance");

app.use(
    "/api/finance",
    financeRoutes
);

// ============================================================
// SERVIDOR HTTP
// ============================================================

const server = http.createServer(app);

// ============================================================
// SOCKET.IO
// ============================================================

const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST", "PUT", "PATCH", "DELETE"]
    }
});

// ============================================================
// DISPONIBILIZAR SOCKET GLOBALMENTE
// ============================================================

global.io = io;

// ============================================================
// WEBSOCKET
// ============================================================

io.on("connection", (socket) => {

    console.log(
        "🟢 Cliente WebSocket conectado:",
        socket.id
    );

    // ========================================================
    // ENTRAR NA SALA DO RESTAURANTE
    // ========================================================

    socket.on(
        "entrar_restaurante",
        (restauranteId) => {

            if (!restauranteId) {
                console.log(
                    "⚠️ Restaurante tentou entrar sem ID"
                );

                return;
            }

            const sala =
                "restaurante_" +
                restauranteId;

            socket.join(sala);

            console.log(
                "🏪 Restaurante conectado na sala:",
                sala
            );
        }
    );

    // ========================================================
    // DESCONECTAR
    // ========================================================

    socket.on(
        "disconnect",
        () => {

            console.log(
                "🔴 Cliente desconectado:",
                socket.id
            );
        }
    );
});

// ============================================================
// INICIAR FOODJET
// ============================================================

async function iniciarServidor() {

    try {

        console.log(
            "================================"
        );

        console.log(
            "🚀 Iniciando FoodJet..."
        );

        console.log(
            "================================"
        );

        // ====================================================
        // CONECTAR BANCO
        // ====================================================

        await conectar();

        console.log(
            "✅ Banco de dados conectado"
        );

        // ====================================================
        // INICIAR SERVIDOR
        // ====================================================

        server.listen(
            PORT,
            "0.0.0.0",
            () => {

                console.log(
                    "================================"
                );

                console.log(
                    "🚀 FoodJet API iniciada"
                );

                console.log(
                    `🌐 Porta: ${PORT}`
                );

                console.log(
                    `🔗 API: http://localhost:${PORT}`
                );

                console.log(
                    "🔌 WebSocket ativo"
                );

                console.log(
                    "================================"
                );
            }
        );

    } catch (error) {

        console.error(
            "❌ ERRO AO INICIAR FOODJET:"
        );

        console.error(error);

        process.exit(1);
    }
}

// ============================================================
// EXECUTAR
// ============================================================

iniciarServidor();