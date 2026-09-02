const bcrypt = require("bcryptjs");
const { pool } = require("./src/config/database");

async function resetarSenha() {
    const email = "teste@foodjet.com";
    const novaSenha = "123456";

    try {
        const resultado = await pool.query(
            `SELECT id, email
             FROM usuarios
             WHERE LOWER(TRIM(email)) = $1
             LIMIT 1`,
            [email.trim().toLowerCase()]
        );

        if (resultado.rows.length === 0) {
            console.log("❌ Usuário não encontrado:", email);
            return;
        }

        const usuario = resultado.rows[0];

        const senhaHash = await bcrypt.hash(novaSenha, 10);

        await pool.query(
            `UPDATE usuarios
             SET senha = $1,
                 atualizado_em = NOW()
             WHERE id = $2`,
            [senhaHash, usuario.id]
        );

        console.log("================================");
        console.log("✅ SENHA ALTERADA COM SUCESSO");
        console.log("📧 Email:", usuario.email);
        console.log("🔑 Nova senha:", novaSenha);
        console.log("🗄️ Banco: PostgreSQL");
        console.log("================================");

    } catch (erro) {
        console.error("❌ ERRO AO RESETAR SENHA:");
        console.error(erro);
    } finally {
        await pool.end();
    }
}

resetarSenha();