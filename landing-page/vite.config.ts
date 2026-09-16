
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import fs from "node:fs";
import path from "node:path";
import { defineConfig, type Plugin, type ViteDevServer } from "vite";
import { vitePluginManusRuntime } from "vite-plugin-manus-runtime";

const PROJECT_ROOT = import.meta.dirname;
const LOG_DIR = path.resolve(PROJECT_ROOT, "logs");

// ============================================================
// DEBUG COLLECTOR
// ============================================================

function vitePluginManusDebugCollector(): Plugin {
  return {
    name: "vite-plugin-manus-debug-collector",

    configureServer(server: ViteDevServer) {
      server.middlewares.use("/__manus_debug", (req, res, next) => {
        if (req.method !== "POST") {
          next();
          return;
        }

        let body = "";

        req.on("data", (chunk) => {
          body += chunk;
        });

        req.on("end", () => {
          try {
            fs.mkdirSync(LOG_DIR, { recursive: true });

            const file = path.join(LOG_DIR, "debug.log");

            fs.appendFileSync(
              file,
              `[${new Date().toISOString()}] ${body}\n`,
              "utf8",
            );

            res.statusCode = 200;
            res.setHeader("Content-Type", "application/json");
            res.end(JSON.stringify({ success: true }));
          } catch (error) {
            console.error("Erro ao salvar debug:", error);

            res.statusCode = 500;
            res.setHeader("Content-Type", "application/json");
            res.end(JSON.stringify({ success: false }));
          }
        });
      });
    },
  };
}

// ============================================================
// STORAGE PROXY
// ============================================================

function vitePluginStorageProxy(): Plugin {
  return {
    name: "vite-plugin-storage-proxy",

    configureServer(server: ViteDevServer) {
      server.middlewares.use("/__storage", (req, res, next) => {
        if (req.method !== "GET") {
          next();
          return;
        }

        res.statusCode = 200;
        res.setHeader("Content-Type", "application/json");
        res.end(JSON.stringify({ success: true }));
      });
    },
  };
}

// ============================================================
// PLUGINS
// ============================================================

const plugins = [
  react(),
  tailwindcss(),
  vitePluginManusRuntime(),
  vitePluginManusDebugCollector(),
  vitePluginStorageProxy(),
];

// ============================================================
// VITE CONFIG
// ============================================================

export default defineConfig({
  plugins,

  resolve: {
    alias: {
      "@": path.resolve(PROJECT_ROOT, "src"),
      "@shared": path.resolve(PROJECT_ROOT, "shared"),
      "@assets": path.resolve(PROJECT_ROOT, "attached_assets"),
    },
  },

  envDir: PROJECT_ROOT,

  root: PROJECT_ROOT,

  build: {
    outDir: path.resolve(PROJECT_ROOT, "dist"),
    emptyOutDir: true,
  },

  server: {
    port: 3000,
    strictPort: false,
    host: true,

    allowedHosts: [
      ".manuspre.computer",
      ".manus.computer",
      ".manus-asia.computer",
      ".manuscomputer.ai",
      ".manusvm.computer",
      "localhost",
      "127.0.0.1",
    ],

    fs: {
      strict: true,
      deny: ["**/.*"],
    },
  },
});

