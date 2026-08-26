require("dotenv").config();

const http = require("http");
const app = require("./app");

const { Server } = require("socket.io");
const { conectar } = require("./config/database");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const PORT = process.env.PORT || 3000;

// ============================================================
// MERCADO PAGO
// ============================================================

const mercadoPagoToken =
  process.env.MERCADOPAGO_ACCESS_TOKEN;

console.log("========================================");
console.log("🔐 FOODJET - MERCADO PAGO");
console.log("========================================");

console.log(
  "TOKEN CARREGADO:",
  mercadoPagoToken ? "SIM" : "NÃO"
);

console.log(
  "AMBIENTE:",
  process.env.MERCADOPAGO_ENVIRONMENT || "production"
);

console.log(
  "TIPO DO TOKEN:",
  mercadoPagoToken?.startsWith("TEST-")
    ? "⚠️ TESTE"
    : mercadoPagoToken?.startsWith("APP_USR-")
      ? "✅ PRODUÇÃO"
      : "❓ DESCONHECIDO"
);

console.log("========================================");

// ============================================================
// ROTAS ESPECIAIS
// ============================================================

// PAGAMENTOS
const paymentRoutes =
  require("./routes/paymentRoutes");

// FINANCEIRO
const financeRoutes =
  require("./routes/finance");

// WEBHOOK MERCADO PAGO
const mercadoPagoWebhookRoutes =
  require("./routes/mercadoPagoWebhook");

// ============================================================
// PAGAMENTOS
// ============================================================

app.use(
  "/api/pagamentos",
  paymentRoutes
);

console.log(
  "💳 ROTA /api/pagamentos REGISTRADA"
);

// ============================================================
// FINANCEIRO
// ============================================================

app.use(
  "/api/finance",
  financeRoutes
);

console.log(
  "💰 ROTA /api/finance REGISTRADA"
);

// ============================================================
// MERCADO PAGO WEBHOOK
// ============================================================

app.use(
  "/api/mercadopago",
  mercadoPagoWebhookRoutes
);

console.log(
  "🔔 WEBHOOK MERCADO PAGO CARREGADO"
);

console.log(
  "📍 POST /api/mercadopago/webhook"
);

// ============================================================
// SERVIDOR HTTP
// ============================================================

const server =
  http.createServer(app);

// ============================================================
// SOCKET.IO
// ============================================================

const io =
  new Server(server, {
    cors: {
      origin: "*",

      methods: [
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
        "OPTIONS",
      ],
    },
  });

// ============================================================
// SOCKET GLOBAL
// ============================================================

global.io = io;

// ============================================================
// WEBSOCKET
// ============================================================

io.on(
  "connection",
  (socket) => {

    console.log(
      "🟢 Cliente WebSocket conectado:",
      socket.id
    );

    // ========================================================
    // RESTAURANTE ENTRA NA SALA
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
          `restaurante_${restauranteId}`;

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
          "🔴 Cliente WebSocket desconectado:",
          socket.id
        );
      }
    );
  }
);

// ============================================================
// INICIAR SERVIDOR
// ============================================================

async function iniciarServidor() {

  try {

    console.log(
      "========================================"
    );

    console.log(
      "🚀 INICIANDO FOODJET"
    );

    console.log(
      "========================================"
    );

    // ========================================================
    // VALIDAR MERCADO PAGO
    // ========================================================

    if (!mercadoPagoToken) {

      console.warn(
        "⚠️ MERCADOPAGO_ACCESS_TOKEN NÃO CONFIGURADO"
      );

    } else {

      console.log(
        "✅ MERCADOPAGO_ACCESS_TOKEN CONFIGURADO"
      );
    }

    // ========================================================
    // VALIDAR WEBHOOK SECRET
    // ========================================================

    const webhookSecret =
      process.env.MERCADOPAGO_WEBHOOK_SECRET;

    if (!webhookSecret) {

      console.warn(
        "⚠️ MERCADOPAGO_WEBHOOK_SECRET NÃO CONFIGURADO"
      );

    } else {

      console.log(
        "✅ MERCADOPAGO_WEBHOOK_SECRET CONFIGURADO"
      );
    }

    // ========================================================
    // BANCO
    // ========================================================

    await conectar();

    console.log(
      "✅ Banco de dados conectado"
    );

    // ========================================================
    // SERVIDOR
    // ========================================================

    server.listen(
      PORT,
      "0.0.0.0",
      () => {

        console.log(
          "========================================"
        );

        console.log(
          "🚀 FOODJET API ONLINE"
        );

        console.log(
          `🌐 PORTA: ${PORT}`
        );

        console.log(
          "🌍 HOST: 0.0.0.0"
        );

        console.log(
          "🔌 SOCKET.IO: ATIVO"
        );

        console.log(
          mercadoPagoToken
            ? "💳 MERCADO PAGO: CONFIGURADO"
            : "💳 MERCADO PAGO: NÃO CONFIGURADO"
        );

        console.log(
          webhookSecret
            ? "🔔 WEBHOOK: ATIVO"
            : "🔔 WEBHOOK: SECRET NÃO CONFIGURADO"
        );

        console.log(
          "========================================"
        );
      }
    );

  } catch (error) {

    console.error(
      "========================================"
    );

    console.error(
      "❌ ERRO AO INICIAR FOODJET"
    );

    console.error(
      error
    );

    console.error(
      "========================================"
    );

    process.exit(1);
  }
}

// ============================================================
// EXECUTAR
// ============================================================

iniciarServidor();