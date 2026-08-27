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

// ============================================================
// LOG ASAAS
// ============================================================

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
// ROTAS
// ============================================================

const paymentRoutes =
  require("./routes/paymentRoutes");

const financeRoutes =
  require("./routes/finance");

// ============================================================
// WEBHOOK ASAAS
// ============================================================
//
// IMPORTANTE:
//
// O arquivo asaasWebhook.js NÃO é um Router.
// Ele exporta:
//   webhook
//   registrarWebhook
//
// Portanto usamos registrarWebhook(app).
// ============================================================

let webhookAtivo = false;

try {

  const asaasWebhook =
    require("./routes/asaasWebhook");

  if (
    !asaasWebhook ||
    typeof asaasWebhook.registrarWebhook !== "function"
  ) {

    throw new Error(
      "registrarWebhook não foi encontrado em routes/asaasWebhook.js"
    );

  }

  asaasWebhook.registrarWebhook(app);

  webhookAtivo = true;

  console.log(
    "🔔 WEBHOOK ASAAS: ROTA REGISTRADA"
  );

  console.log(
    "🔔 URL:"
  );

  console.log(
    "https://foodjet-backend.onrender.com/api/asaas/webhook"
  );

} catch (err) {

  console.error(
    "========================================"
  );

  console.error(
    "❌ ERRO AO REGISTRAR WEBHOOK ASAAS"
  );

  console.error(
    "========================================"
  );

  console.error(
    "ERRO:",
    err.message
  );

  console.error(
    "STACK:",
    err.stack
  );

  console.error(
    "========================================"
  );

}

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
        "OPTIONS"
      ],

    },

  });

// ============================================================
// GLOBAL IO
// ============================================================

global.io = io;

// ============================================================
// WEBSOCKET
// ============================================================

io.on(
  "connection",
  (socket) => {

    console.log(
      "🟢 Cliente conectado:",
      socket.id
    );

    // ========================================================
    // RESTAURANTE
    // ========================================================

    socket.on(
      "entrar_restaurante",
      (restauranteId) => {

        if (!restauranteId) {
          return;
        }

        const sala =
          `restaurante_${restauranteId}`;

        socket.join(sala);

        console.log(
          "🏪 Restaurante entrou:",
          sala
        );

      }
    );

    // ========================================================
    // ENTREGADOR
    // ========================================================

    socket.on(
      "entrar_entregador",
      (entregadorId) => {

        if (!entregadorId) {
          return;
        }

        const sala =
          `entregador_${entregadorId}`;

        socket.join(sala);

        console.log(
          "🏍️ Entregador entrou:",
          sala
        );

      }
    );

    // ========================================================
    // PEDIDO
    // ========================================================

    socket.on(
      "entrar_pedido",
      (pedidoId) => {

        if (!pedidoId) {
          return;
        }

        const sala =
          `pedido_${pedidoId}`;

        socket.join(sala);

        console.log(
          "📦 Cliente entrou:",
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

  }
);

// ============================================================
// INICIAR SERVIDOR
// ============================================================

async function iniciarServidor() {

  try {

    console.log("========================================");
    console.log("🚀 INICIANDO FOODJET");
    console.log("========================================");

    // ========================================================
    // ASAAS API KEY
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
    // WEBHOOK TOKEN
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

        console.log("========================================");
        console.log("🚀 FOODJET API ONLINE");
        console.log("========================================");

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
          webhookAtivo
            ? "🔔 WEBHOOK ASAAS: ATIVO"
            : "❌ WEBHOOK ASAAS: DESABILITADO"
        );

        console.log(
          "🔔 WEBHOOK:"
        );

        console.log(
          "https://foodjet-backend.onrender.com/api/asaas/webhook"
        );

        console.log("========================================");

      }
    );

  } catch (error) {

    console.error("========================================");

    console.error(
      "❌ ERRO AO INICIAR FOODJET"
    );

    console.error(
      "MENSAGEM:",
      error.message
    );

    console.error(
      "STACK:",
      error.stack
    );

    console.error("========================================");

    process.exit(1);

  }

}

// ============================================================
// EXECUTAR
// ============================================================

iniciarServidor();