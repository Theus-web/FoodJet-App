const Delivery = require("../models/delivery");


exports.create = async (req, res) => {

    const entregador = {

        id: Date.now(),

        nome: req.body.nome,

        telefone: req.body.telefone,

        veiculo: req.body.veiculo,

        online: false

    };


    await Delivery.criar(entregador);


    res.json({

        mensagem: "Entregador cadastrado",

        entregador

    });

};



exports.list = async (req, res) => {

    const entregadores = await Delivery.listar();

    res.json(entregadores);

};

// Atualizar status online/offline do entregador
exports.status = async (req, res) => {

    const id = Number(req.params.id);

    const online = req.body.online;


    const entregadores = await Delivery.listar();


    const entregador = entregadores.find(
        e => e.id === id
    );


    if(!entregador){

        return res.status(404).json({
            mensagem:"Entregador não encontrado"
        });

    }


    entregador.online = online;


    res.json({

        mensagem:"Status atualizado",

        entregador

    });

};



// Buscar pedidos do entregador
exports.myOrders = async (req,res)=>{


    const Order = require("../models/order");


    const id = Number(req.params.id);


    const pedidos = await Order.listar();


    const minhas = pedidos.filter(
        p => p.entregadorId === id
    );


    res.json(minhas);


};
