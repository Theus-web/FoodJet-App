const bcrypt = require("bcryptjs");
const { pool } = require("./src/config/database");

async function resetarSenha() {
    const email = "teste@foodjet.com";
    const novaSenha = "123456";

    try {
        // ==========================================
        // BUSCAR USUÁRIO NO POSTGRESQL
        // ==========================================

        const resultado = await pool.query(
            `
            SELECT id, email
            FROM usuarios
            WHERE LOWER(TRIM(email)) = $1
            LIMIT 1
            `,
            [email.trim().toLowerCase()]
        );

        if (resultado.rows.length === 0) {
            console.log(
                "❌ Usuário não encontrado:",
                email
            );

            return;
        }

        const usuario = resultado.rows[0];

        // ==========================================
        // GERAR NOVA SENHA
        // ==========================================

        const senhaHash = await bcrypt.hash(
            novaSenha,
            10
        );

        // ==========================================
        // ATUALIZAR SENHA
        // ==========================================

        await pool.query(
            `
            UPDATE usuarios
            SET
                senha = $1,
                atualizado_em = NOW()
            WHERE id = $2
            `,
            [
                senhaHash,
                usuario.id
            ]
        );

        // ==========================================
        // RESULTADO
        // ==========================================

        console.log("================================");
        console.log("✅ SENHA ALTERADA COM SUCESSO");
        console.log("📧 Email:", usuario.email);
        console.log("🔑 Nova senha:", novaSenha);
        console.log("🗄️ Banco: PostgreSQL");
        console.log("================================");

    } catch (erro) {

        console.error(
            "❌ ERRO AO RESETAR SENHA:"
        );

        console.error(
            erro
        );

    } finally {

        await pool.end();

    }
}

resetarSenha();