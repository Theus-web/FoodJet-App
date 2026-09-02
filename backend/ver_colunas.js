const { pool } = require("./src/config/database");

async function verificar() {
    try {
        const resultado = await pool.query(`
            SELECT
                column_name,
                data_type
            FROM information_schema.columns
            WHERE table_name = 'pagamentos_asaas'
            ORDER BY ordinal_position
        `);

        console.table(resultado.rows);

    } catch (erro) {
        console.error("ERRO:", erro);
    } finally {
        await pool.end();
    }
}

verificar();