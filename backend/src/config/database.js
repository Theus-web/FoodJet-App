
const { Pool } = require("pg");

require("dotenv").config();

// ============================================================
// CONFIGURAÇÃO POSTGRESQL
// ============================================================

if (!process.env.DATABASE_URL) {
    throw new Error(
        "❌ DATABASE_URL não encontrada nas variáveis de ambiente."
    );
}

// ============================================================
// POOL POSTGRESQL
// ============================================================

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,

    // Neon / PostgreSQL remoto
    ssl: {
        rejectUnauthorized: false,
    },

    // Quantidade máxima de conexões simultâneas
    max: 10,

    // Tempo que uma conexão pode ficar parada
    idleTimeoutMillis: 30000,

    // Tempo máximo para conseguir conexão
    connectionTimeoutMillis: 20000,
});

// ============================================================
// STATUS DA CONEXÃO
// ============================================================

let bancoConectado = false;

// ============================================================
// CONECTAR
// ============================================================

async function conectar() {
    try {
        console.log("");
        console.log("========================================");
        console.log("🗄️ FOODJET - POSTGRESQL");
        console.log("========================================");
        console.log("🔄 Testando conexão com PostgreSQL...");

        await pool.query("SELECT NOW()");

        if (!bancoConectado) {
            bancoConectado = true;

            console.log("✅ PostgreSQL conectado");

            // ====================================================
            // CONTAGEM DAS TABELAS
            // ====================================================

            try {
                const usuarios = await pool.query(
                    "SELECT COUNT(*)::int AS total FROM usuarios"
                );

                const restaurantes = await pool.query(
                    "SELECT COUNT(*)::int AS total FROM restaurantes"
                );

                const produtos = await pool.query(
                    "SELECT COUNT(*)::int AS total FROM produtos"
                );

                const pedidos = await pool.query(
                    "SELECT COUNT(*)::int AS total FROM pedidos"
                );

                const entregadores = await pool.query(
                    "SELECT COUNT(*)::int AS total FROM entregadores"
                );

                const pagamentos = await pool.query(
                    "SELECT COUNT(*)::int AS total FROM pagamentos"
                );

                const favoritos = await pool.query(
                    "SELECT COUNT(*)::int AS total FROM favoritos"
                );

                console.log("");
                console.log(
                    "👥 USUÁRIOS NO POSTGRESQL:",
                    usuarios.rows[0].total
                );

                console.log(
                    "🏪 RESTAURANTES NO POSTGRESQL:",
                    restaurantes.rows[0].total
                );

                console.log(
                    "🍕 PRODUTOS NO POSTGRESQL:",
                    produtos.rows[0].total
                );

                console.log(
                    "📦 PEDIDOS NO POSTGRESQL:",
                    pedidos.rows[0].total
                );

                console.log(
                    "🏍️ ENTREGADORES NO POSTGRESQL:",
                    entregadores.rows[0].total
                );

                console.log(
                    "💳 PAGAMENTOS NO POSTGRESQL:",
                    pagamentos.rows[0].total
                );

                console.log(
                    "❤️ FAVORITOS NO POSTGRESQL:",
                    favoritos.rows[0].total
                );

                console.log("");
                console.log("========================================");
                console.log("✅ BANCO FOODJET PRONTO");
                console.log("========================================");
                console.log("");

            } catch (erroContagem) {

                console.error("");
                console.error(
                    "⚠️ PostgreSQL conectou, mas houve erro ao consultar as tabelas."
                );

                console.error(
                    "Mensagem:",
                    erroContagem.message
                );

                console.error("");
            }
        }

        return pool;

    } catch (erro) {

        bancoConectado = false;

        console.error("");
        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO AO CONECTAR BANCO FOODJET"
        );

        console.error(
            "========================================"
        );

        console.error(
            "Mensagem:",
            erro.message
        );

        if (erro.code) {
            console.error(
                "Código:",
                erro.code
            );
        }

        console.error(
            "Detalhes:",
            erro
        );

        console.error(
            "========================================"
        );

        console.error("");

        throw erro;
    }
}

// ============================================================
// ERROS DO POOL
// ============================================================

pool.on("error", (erro) => {

    bancoConectado = false;

    console.error("");
    console.error(
        "❌ ERRO INESPERADO NO POOL POSTGRESQL:"
    );

    console.error(
        "Mensagem:",
        erro.message
    );

    if (erro.code) {
        console.error(
            "Código:",
            erro.code
        );
    }

    console.error("");
});

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
    pool,
    conectar,
};
