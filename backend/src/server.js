require("dotenv").config();

const http = require("http");
const app = require("./app");

const { Server } = require("socket.io");

const { conectar } = require("./config/database");

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