const { pool } = require("../src/config/database");

async function verificar() {
    try {
        console.log("\n========================================");
        console.log("🔎 ESTRUTURA DA TABELA ENTREGADORES");
        console.log("========================================\n");

        const resultado = await pool.query(`
            SELECT
                column_name,
                data_type,
                is_nullable,
                column_default
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'entregadores'
            ORDER BY ordinal_position;
        `);

        if (resultado.rows.length === 0) {
            console.log("❌ A tabela entregadores não foi encontrada.");
        } else {
            console.table(resultado.rows);
        }

        console.log("\n========================================");
        console.log("🏍️ REGISTROS ATUAIS");
        console.log("========================================\n");

        const entregadores = await pool.query(`
            SELECT *
            FROM entregadores
            ORDER BY id;
        `);

        console.table(entregadores.rows);

    } catch (erro) {
        console.error("\n❌ ERRO:");
        console.error(erro);
    } finally {
        await pool.end();
    }
}

verificar();