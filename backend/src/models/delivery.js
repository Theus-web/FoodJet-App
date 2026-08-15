const { db } = require("../config/database");


async function criar(entregador){

    await db.read();

    db.data.entregadores.push(entregador);

    await db.write();

}


async function listar(){

    await db.read();

    return db.data.entregadores;

}


module.exports = {
    criar,
    listar
};

