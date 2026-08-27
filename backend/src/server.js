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

const asaasApiKey = process.env.ASAAS_API_KEY;
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

console.log("AMBIENTE:", asaasEnvironment);

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

const paymentRoutes = require("./routes/paymentRoutes");
const financeRoutes = require("./routes/finance");

// ============================================================
// WEBHOOK ASAAS (OPCIONAL)
// Não derruba o servidor caso o arquivo ainda não exista.
// ============================================================

let webhookAtivo = false;

try {
  const asaasWebhookRoutes = require("./routes/asaasWebhook");

  app.use("/api/asaas", asaasWebhookRoutes);

  webhookAtivo = true;

  console.log("🔔 ROTA /api/asaas/webhook REGISTRADA");
} catch (err) {
  console.warn("⚠️ WEBHOOK ASAAS NÃO ENCONTRADO");
  console.warn("⚠️ Servidor iniciado sem webhook.");
}

// ============================================================
// PAGAMENTOS
// ============================================================

app.use("/api/pagamentos", paymentRoutes);
console.log("💳 ROTA /api/pagamentos REGISTRADA");

// ============================================================
// FINANCEIRO
// ============================================================

app.use("/api/finance", financeRoutes);
console.log("💰 ROTA /api/finance REGISTRADA");

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
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  },
});

global.io = io;

// ============================================================
// WEBSOCKET
// ============================================================

io.on("connection", (socket) => {
  console.log("🟢 Cliente conectado:", socket.id);

  socket.on("entrar_restaurante", (restauranteId) => {
    if (!restauranteId) return;

    const sala = `restaurante_${restauranteId}`;
    socket.join(sala);

    console.log("🏪 Restaurante entrou:", sala);
  });

  socket.on("entrar_entregador", (entregadorId) => {
    if (!entregadorId) return;

    const sala = `entregador_${entregadorId}`;
    socket.join(sala);

    console.log("🏍️ Entregador entrou:", sala);
  });

  socket.on("entrar_pedido", (pedidoId) => {
    if (!pedidoId) return;

    const sala = `pedido_${pedidoId}`;
    socket.join(sala);

    console.log("📦 Cliente entrou:", sala);
  });

  socket.on("disconnect", () => {
    console.log("🔴 Cliente desconectado:", socket.id);
  });
});

// ============================================================
// INICIAR SERVIDOR
// ============================================================

async function iniciarServidor() {
  try {
    console.log("========================================");
    console.log("🚀 INICIANDO FOODJET");
    console.log("========================================");

    if (!asaasApiKey) {
      console.warn("⚠️ ASAAS_API_KEY NÃO CONFIGURADA");
    } else {
      console.log("✅ ASAAS_API_KEY CONFIGURADA");
    }

    if (!asaasWebhookToken) {
      console.warn("⚠️ ASAAS_WEBHOOK_TOKEN NÃO CONFIGURADO");
    } else {
      console.log("✅ ASAAS_WEBHOOK_TOKEN CONFIGURADO");
    }

    await conectar();

    console.log("✅ Banco de dados conectado");

    server.listen(PORT, "0.0.0.0", () => {
      console.log("========================================");
      console.log("🚀 FOODJET API ONLINE");
      console.log(`🌐 PORTA: ${PORT}`);
      console.log("🌍 HOST: 0.0.0.0");
      console.log("🔌 SOCKET.IO: ATIVO");

      console.log(
        asaasApiKey
          ? "💳 ASAAS: CONFIGURADO"
          : "💳 ASAAS: NÃO CONFIGURADO"
      );

      console.log(
        webhookAtivo
          ? "🔔 WEBHOOK ASAAS: ATIVO"
          : "⚠️ WEBHOOK ASAAS: DESABILITADO"
      );

      console.log("========================================");
    });
  } catch (error) {
    console.error("========================================");
    console.error("❌ ERRO AO INICIAR FOODJET");
    console.error("MENSAGEM:", error.message);
    console.error("STACK:", error.stack);
    console.error("========================================");

    process.exit(1);
  }
}

// ============================================================
// EXECUTAR
// ============================================================

iniciarServidor();