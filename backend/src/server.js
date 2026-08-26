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
// ASAAS
// ============================================================

const asaasApiKey =
  process.env.ASAAS_API_KEY;

const asaasEnvironment =
  process.env.ASAAS_ENVIRONMENT || "production";

const asaasWebhookToken =
  process.env.ASAAS_WEBHOOK_TOKEN;

console.log("========================================");
console.log("🔐 FOODJET - ASAAS");
console.log("========================================");

console.log(
  "API KEY CARREGADA:",
  asaasApiKey ? "SIM" : "NÃO"
);

console.log(
  "AMBIENTE:",
  asaasEnvironment
);

console.log(
  "TIPO:",
  asaasEnvironment === "production"
    ? "✅ PRODUÇÃO"
    : "⚠️ SANDBOX"
);

console.log(
  "API:",
  asaasEnvironment === "production"
    ? "https://api.asaas.com"
    : "https://api-sandbox.asaas.com"
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

// WEBHOOK ASAAS
const asaasWebhookRoutes =
  require("./routes/asaasWebhook");

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
// ASAAS WEBHOOK
// ============================================================
//
// Endpoint:
// POST /api/asaas/webhook
//
// O processamento da assinatura e dos eventos fica
// dentro de routes/asaasWebhook.js
// ============================================================

app.use(
  "/api/asaas",
  asaasWebhookRoutes
);

console.log(
  "🔔 ROTA /api/asaas/webhook REGISTRADA"
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
    // ENTREGADOR ENTRA NA SALA
    // ========================================================

    socket.on(
      "entrar_entregador",
      (entregadorId) => {

        if (!entregadorId) {

          console.log(
            "⚠️ Entregador tentou entrar sem ID"
          );

          return;
        }

        const sala =
          `entregador_${entregadorId}`;

        socket.join(sala);

        console.log(
          "🏍️ Entregador conectado na sala:",
          sala
        );
      }
    );

    // ========================================================
    // CLIENTE ENTRA NA SALA DO PEDIDO
    // ========================================================

    socket.on(
      "entrar_pedido",
      (pedidoId) => {

        if (!pedidoId) {

          console.log(
            "⚠️ Cliente tentou entrar no pedido sem ID"
          );

          return;
        }

        const sala =
          `pedido_${pedidoId}`;

        socket.join(sala);

        console.log(
          "📦 Cliente conectado na sala:",
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
    // VALIDAR ASAAS
    // ========================================================

    if (!asaasApiKey) {

      console.warn(
        "⚠️ ASAAS_API_KEY NÃO CONFIGURADA"
      );

    } else {

      console.log(
        "✅ ASAAS_API_KEY CONFIGURADA"
      );
    }

    // ========================================================
    // VALIDAR WEBHOOK
    // ========================================================

    if (!asaasWebhookToken) {

      console.warn(
        "⚠️ ASAAS_WEBHOOK_TOKEN NÃO CONFIGURADO"
      );

    } else {

      console.log(
        "✅ ASAAS_WEBHOOK_TOKEN CONFIGURADO"
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
          asaasApiKey
            ? "💳 ASAAS: CONFIGURADO"
            : "💳 ASAAS: NÃO CONFIGURADO"
        );

        console.log(
          asaasWebhookToken
            ? "🔔 WEBHOOK ASAAS: ATIVO"
            : "🔔 WEBHOOK ASAAS: TOKEN NÃO CONFIGURADO"
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
      "MENSAGEM:",
      error?.message
    );

    console.error(
      "STACK:",
      error?.stack
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