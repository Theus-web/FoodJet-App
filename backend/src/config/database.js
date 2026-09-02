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

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,

    ssl: {
        rejectUnauthorized: false,
    },

    max: 10,

    idleTimeoutMillis: 30000,

    connectionTimeoutMillis: 10000,
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
        await pool.query("SELECT NOW()");

        if (!bancoConectado) {
            bancoConectado = true;

            console.log("");
            console.log("========================================");
            console.log("🗄️ BANCO FOODJET");
            console.log("========================================");
            console.log("✅ PostgreSQL conectado");

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

                console.log(
                    "========================================"
                );

                console.log("");

            } catch (erroContagem) {

                console.error(
                    "⚠️ PostgreSQL conectado, mas não foi possível consultar todas as tabelas."
                );

                console.error(
                    erroContagem.message
                );
            }
        }

        return pool;

    } catch (erro) {

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

        console.error(erro);

        console.error("");

        throw erro;
    }
}

// ============================================================
// ERROS DO POOL
// ============================================================

pool.on("error", (erro) => {

    console.error(
        "❌ Erro inesperado no pool PostgreSQL:"
    );

    console.error(erro);

});

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
    pool,
    conectar,
};