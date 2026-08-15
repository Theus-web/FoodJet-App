const bcrypt = require("bcryptjs");
const { db } = require("./src/config/database");

async function resetarSenha() {
    const email = "teste@foodjet.com";
    const novaSenha = "123456";

    await db.read();

    const usuario = db.data.usuarios.find(
        usuario => usuario.email === email
    );

    if (!usuario) {
        console.log("❌ Usuário não encontrado:", email);
        return;
    }

    usuario.senha = await bcrypt.hash(novaSenha, 10);

    await db.write();

    console.log("================================");
    console.log("✅ SENHA ALTERADA COM SUCESSO");
    console.log("📧 Email:", email);
    console.log("🔑 Nova senha:", novaSenha);
    console.log("================================");
}

resetarSenha();