const { db } = require("../config/database");

exports.dashboard = async (req, res) => {

    await db.read();

    res.json({
        sistema: "FoodJet",
        usuarios: db.data.usuarios.length,
        restaurantes: db.data.restaurantes.length,
        produtos: db.data.produtos.length,
        pedidos: db.data.pedidos.length,
        entregadores: db.data.entregadores.length
    });

};

exports.users = async (req, res) => {

    const { db } = require("../config/database");

    await db.read();

    const usuarios = db.data.usuarios.map(usuario => ({
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        tipo: usuario.tipo
    }));

    res.json(usuarios);

};

exports.restaurants = async (req, res) => {

    const { db } = require("../config/database");

    await db.read();

    res.json(db.data.restaurantes);

};
