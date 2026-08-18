const path = require("path");

const { Low } = require("lowdb");
const { JSONFile } = require("lowdb/node");

// ============================================================
// CAMINHO DO BANCO
// ============================================================

const caminhoBanco = path.join(
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
// ADAPTER
// ============================================================

const adapter = new JSONFile(
    caminhoBanco
);

// ============================================================
// DADOS PADRÃO
// ============================================================

const dadosPadrao = {

    usuarios: [],

    restaurantes: [],

    produtos: [],

    pedidos: [],

    entregadores: [],

    pagamentos: [],

    promocoes: [],

};

// ============================================================
// BANCO LOWDB
// ============================================================

const db = new Low(
    adapter,
    dadosPadrao
);

// ============================================================
// GARANTIR ESTRUTURA DO BANCO
// ============================================================

function garantirEstrutura() {

    if (!db.data) {
        db.data = {};
    }

    if (!Array.isArray(db.data.usuarios)) {
        db.data.usuarios = [];
    }

    if (!Array.isArray(db.data.restaurantes)) {
        db.data.restaurantes = [];
    }

    if (!Array.isArray(db.data.produtos)) {
        db.data.produtos = [];
    }

    if (!Array.isArray(db.data.pedidos)) {
        db.data.pedidos = [];
    }

    if (!Array.isArray(db.data.entregadores)) {
        db.data.entregadores = [];
    }

    if (!Array.isArray(db.data.pagamentos)) {
        db.data.pagamentos = [];
    }

    if (!Array.isArray(db.data.promocoes)) {
    db.data.promocoes = [];
}

}

// ============================================================
// CONECTAR BANCO
// ============================================================

let bancoConectado = false;

async function conectar() {

    try {

        // ====================================================
        // LER BANCO
        // ====================================================

        await db.read();

        // ====================================================
        // GARANTIR ESTRUTURA
        // ====================================================

        garantirEstrutura();

        // ====================================================
        // VERIFICAR SE BANCO PRECISA SER CRIADO
        // ====================================================

        if (!bancoConectado) {

            await db.write();

            bancoConectado = true;

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

        }

        return db;

    } catch (error) {

        console.error(
            "❌ ERRO AO CONECTAR BANCO FOODJET:"
        );

        console.error(error);

        throw error;

    }

}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

    db,

    conectar,

    garantirEstrutura

};