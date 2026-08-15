const path = require("path");
const { Low } = require("lowdb");
const { JSONFile } = require("lowdb/node");

// ============================================================
// CAMINHO DO BANCO
// ============================================================

const caminhoBanco = path.resolve(
    __dirname,
    "..",
    "..",
    "foodjet.json"
);

console.log(
    "📂 BANCO UTILIZADO:",
    caminhoBanco
);

// ============================================================
// ADAPTER LOWDB
// ============================================================

const adapter = new JSONFile(caminhoBanco);

const db = new Low(adapter, {
    usuarios: [],
    restaurantes: [],
    produtos: [],
    pedidos: [],
    entregadores: [],
    pagamentos: [],
    repasses: []
});

// ============================================================
// CONECTAR BANCO
// ============================================================

async function conectar() {

    try {

        await db.read();

        // ====================================================
        // GARANTIR ESTRUTURA PRINCIPAL
        // ====================================================

        if (!db.data) {
            db.data = {};
        }

        db.data.usuarios ||= [];
        db.data.restaurantes ||= [];
        db.data.produtos ||= [];
        db.data.pedidos ||= [];
        db.data.entregadores ||= [];
        db.data.pagamentos ||= [];
        db.data.repasses ||= [];

        // ====================================================
        // SALVAR
        // ====================================================

        await db.write();

        // ====================================================
        // LOGS
        // ====================================================

        console.log(
            "🗄️ Banco FoodJet conectado"
        );

        console.log(
            "👥 USUÁRIOS NO BANCO:",
            db.data.usuarios.length
        );

        console.log(
            "🏪 RESTAURANTES NO BANCO:",
            db.data.restaurantes.length
        );

        console.log(
            "🍕 PRODUTOS NO BANCO:",
            db.data.produtos.length
        );

        console.log(
            "📦 PEDIDOS NO BANCO:",
            db.data.pedidos.length
        );

        console.log(
            "🏍️ ENTREGADORES NO BANCO:",
            db.data.entregadores.length
        );

        console.log(
            "💳 PAGAMENTOS NO BANCO:",
            db.data.pagamentos.length
        );

        console.log(
            "💰 REPASSES NO BANCO:",
            db.data.repasses.length
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO CONECTAR AO BANCO:"
        );

        console.error(erro);

        throw erro;
    }
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {
    db,
    conectar
};