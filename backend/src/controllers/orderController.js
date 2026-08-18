const Order = require("../models/order");
const Restaurant = require("../models/restaurant");


// ======================================================
// FUNÇÃO AUXILIAR
// NORMALIZAR ID
// ======================================================

function normalizarId(id) {

    if (
        id === undefined ||
        id === null
    ) {
        return "";
    }

    return String(id).trim();
}


// ======================================================
// SALVAR PEDIDOS
// ======================================================

async function salvarPedidos(pedidos) {

    const { db } =
        require("../config/database");


    if (!db.data) {

        db.data = {};

    }


    db.data.pedidos =
        Array.isArray(pedidos)
            ? pedidos
            : [];


    await db.write();

}



// ======================================================
// CRIAR PEDIDO
// POST /api/orders
// ======================================================

exports.create = async (
    req,
    res
) => {


    try {


        const restauranteId =
            normalizarId(
                req.body.restauranteId
            );


        const clienteId =
            normalizarId(
                req.body.clienteId
            );


        const itens =
            Array.isArray(
                req.body.itens
            )
            ? req.body.itens
            : [];



        if (!restauranteId) {

            return res.status(400).json({

                sucesso:false,

                erro:
                "restauranteId é obrigatório"

            });

        }



        const restaurante =
            await Restaurant.buscarPorId(
                restauranteId
            );



        if (!restaurante) {


            return res.status(404).json({

                sucesso:false,

                erro:
                "Restaurante não encontrado"

            });


        }



        const statusRestaurante =
            String(
                restaurante.status || ""
            )
            .toUpperCase();



        const online =
            restaurante.online === true ||
            String(
                restaurante.online
            )
            .toLowerCase() === "true";



        const aberto =
            restaurante.aberto === true ||
            String(
                restaurante.aberto
            )
            .toLowerCase() === "true";




        const disponivel =
            statusRestaurante === "ABERTO" &&
            online &&
            aberto;



        if (!disponivel) {


            return res.status(409).json({

                sucesso:false,

                restauranteOffline:true,

                erro:
                "Restaurante offline"

            });


        }



        if (
            itens.length === 0
        ) {


            return res.status(400).json({

                sucesso:false,

                erro:
                "Pedido sem itens"

            });


        }




        const pedido = {


            id:
            Date.now(),



            clienteId,



            restauranteId,



            itens,



            endereco:
            req.body.endereco || {},



            pagamento:
            req.body.pagamento || "PIX",



            subtotal:
            Number(
                req.body.subtotal
            ) || 0,



            taxaEntrega:
            Number(
                req.body.taxaEntrega
            ) || 0,



            total:
            Number(
                req.body.total
            ) || 0,



            status:
            "AGUARDANDO_RESTAURANTE",



            criadoEm:
            new Date().toISOString()


        };





        await Order.criar(
            pedido
        );





        // =============================================
        // SOCKET NOVO PEDIDO
        // =============================================


        if (global.io) {


            const sala =
            `restaurante_${restauranteId}`;



            global.io
            .to(sala)
            .emit(
                "novo_pedido",
                pedido
            );



            console.log(
                "🔔 Pedido enviado:",
                sala
            );


        }





        return res.status(201).json({

            sucesso:true,

            mensagem:
            "Pedido criado com sucesso",

            pedido


        });





    } catch(error) {


        console.error(
            "❌ ERRO CREATE PEDIDO:",
            error
        );



        return res.status(500).json({

            sucesso:false,

            erro:
            "Erro ao criar pedido",

            detalhes:
            error.message


        });


    }


};




// ======================================================
// LISTAR TODOS OS PEDIDOS
// ======================================================

exports.list = async (
    req,
    res
)=>{


    try{


        const pedidos =
        await Order.listar();



        return res.json(

            Array.isArray(pedidos)
            ? pedidos
            : []

        );



    }catch(error){


        return res.status(500).json({

            erro:
            "Erro ao listar pedidos"

        });


    }


};




// ======================================================
// BUSCAR PEDIDO POR ID
// ======================================================

exports.getById = async (
    req,
    res
)=>{


    try{


        const id =
        Number(
            req.params.id
        );



        const pedido =
        await Order.buscarPorId(
            id
        );



        if(!pedido){


            return res.status(404).json({

                erro:
                "Pedido não encontrado"

            });


        }



        return res.json(
            pedido
        );



    }catch(error){


        return res.status(500).json({

            erro:
            "Erro ao buscar pedido"

        });


    }


};

// ======================================================
// ATUALIZAR STATUS DO PEDIDO
// PUT /api/orders/:id/status
// ======================================================

exports.updateStatus = async (
    req,
    res
) => {

    try {

        const id =
            Number(
                req.params.id
            );


        const novoStatus =
            String(
                req.body.status || ""
            ).trim();



        if (!Number.isFinite(id)) {

            return res.status(400).json({

                sucesso:false,

                erro:
                "ID inválido"

            });

        }



        const pedido =
            await Order.buscarPorId(
                id
            );



        if (!pedido) {

            return res.status(404).json({

                sucesso:false,

                erro:
                "Pedido não encontrado"

            });

        }



        pedido.status =
            novoStatus;


        pedido.atualizadoEm =
            new Date().toISOString();



        const pedidos =
            await Order.listar();



        const index =
            pedidos.findIndex(
                item =>
                Number(item.id) === id
            );



        if(index !== -1){

            pedidos[index] =
                pedido;

        }



        await salvarPedidos(
            pedidos
        );



        if(global.io){

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

        }



        return res.json({

            sucesso:true,

            mensagem:
            "Status atualizado",

            pedido

        });



    }catch(error){


        console.error(error);


        return res.status(500).json({

            erro:
            "Erro atualizar status"

        });


    }

};




// ======================================================
// PEDIDOS DO RESTAURANTE
// GET /api/orders/restaurante/:id
// ======================================================

exports.restaurantOrders = async (
    req,
    res
)=>{


    try{


        const restauranteId =
            normalizarId(
                req.params.id
            );



        const pedidos =
            await Order.listar();



        const resultado =
            pedidos.filter(
                pedido =>
                normalizarId(
                    pedido.restauranteId
                )
                === restauranteId
            );



        return res.json(
            resultado
        );



    }catch(error){


        return res.status(500).json({

            erro:
            "Erro buscar pedidos restaurante"

        });


    }


};




// ======================================================
// PEDIDOS DISPONÍVEIS PARA ENTREGA
// ======================================================

exports.availableDeliveries =
async (
    req,
    res
)=>{


    try{


        const pedidos =
            await Order.listar();



        const resultado =
        pedidos.filter(

            pedido =>

            String(
                pedido.status
            )
            .toUpperCase()
            ===
            "PRONTO"

        );



        return res.json(
            resultado
        );



    }catch(error){


        return res.status(500).json({

            erro:
            "Erro buscar entregas"

        });


    }


};




// ======================================================
// ENTREGADOR ACEITA PEDIDO
// ======================================================

exports.acceptDelivery =
async (
    req,
    res
)=>{


    try{


        const id =
            Number(
                req.params.id
            );


        const entregadorId =
            normalizarId(
                req.body.entregadorId
            );



        const pedido =
            await Order.buscarPorId(
                id
            );



        if(!pedido){

            return res.status(404).json({

                erro:
                "Pedido não encontrado"

            });

        }



        pedido.entregadorId =
            entregadorId;



        pedido.status =
            "EM_ENTREGA";



        const pedidos =
            await Order.listar();



        const index =
            pedidos.findIndex(
                p =>
                Number(p.id)===id
            );



        pedidos[index] =
            pedido;



        await salvarPedidos(
            pedidos
        );



        if(global.io){

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

        }



        return res.json({

            sucesso:true,

            pedido

        });



    }catch(error){


        return res.status(500).json({

            erro:
            "Erro aceitar entrega"

        });


    }


};




// ======================================================
// FINALIZAR ENTREGA
// ======================================================

exports.completeDelivery =
async (
    req,
    res
)=>{


    try{


        const id =
            Number(
                req.params.id
            );



        const pedido =
            await Order.buscarPorId(
                id
            );



        if(!pedido){

            return res.status(404).json({

                erro:
                "Pedido não encontrado"

            });

        }



        pedido.status =
            "ENTREGUE";



        pedido.entregueEm =
            new Date().toISOString();



        const pedidos =
            await Order.listar();



        const index =
            pedidos.findIndex(
                p =>
                Number(p.id)===id
            );



        pedidos[index] =
            pedido;



        await salvarPedidos(
            pedidos
        );



        if(global.io){

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

        }



        return res.json({

            sucesso:true,

            mensagem:
            "Entrega finalizada",

            pedido

        });



    }catch(error){


        return res.status(500).json({

            erro:
            "Erro finalizar entrega"

        });


    }


};

// ======================================================
// PEDIDOS DO CLIENTE
// GET /api/orders/cliente/:id
// ======================================================

exports.clientOrders = async (req, res) => {

    try {

        const clienteId =
            normalizarId(
                req.params.id
            );


        if (!clienteId) {

            return res.status(400).json({

                sucesso:false,

                erro:
                "Cliente não informado"

            });

        }


        const pedidos =
            await Order.listar();


        const resultado =
            pedidos.filter(
                pedido =>
                    normalizarId(
                        pedido.clienteId
                    ) === clienteId
            );


        return res.status(200).json(
            resultado
        );


    } catch(error) {

        console.error(
            "Erro pedidos cliente:",
            error
        );


        return res.status(500).json({

            sucesso:false,

            erro:
            "Erro ao buscar pedidos do cliente"

        });

    }

};



// ======================================================
// RESTAURANTE ACEITA PEDIDO
// PUT /api/orders/:id/accept
// ======================================================

exports.acceptRestaurant = async(req,res)=>{

    try{

        const id =
            Number(req.params.id);


        const pedido =
            await Order.buscarPorId(id);


        if(!pedido){

            return res.status(404).json({

                erro:
                "Pedido não encontrado"

            });

        }


        pedido.status =
            "EM_PREPARO";


        pedido.aceitoRestauranteEm =
            new Date().toISOString();



        const pedidos =
            await Order.listar();



        const index =
            pedidos.findIndex(
                p =>
                Number(p.id)===id
            );


        pedidos[index]=pedido;


        await salvarPedidos(
            pedidos
        );


        if(global.io){

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

        }



        return res.json({

            sucesso:true,

            pedido

        });



    }catch(error){

        return res.status(500).json({

            erro:
            error.message

        });

    }

};



// ======================================================
// RESTAURANTE RECUSA PEDIDO
// PUT /api/orders/:id/reject
// ======================================================

exports.rejectRestaurant = async(req,res)=>{

    try{


        const id =
            Number(req.params.id);



        const pedido =
            await Order.buscarPorId(id);



        if(!pedido){

            return res.status(404).json({

                erro:
                "Pedido não encontrado"

            });

        }



        pedido.status =
            "CANCELADO";


        pedido.canceladoEm =
            new Date().toISOString();



        const pedidos =
            await Order.listar();



        const index =
            pedidos.findIndex(
                p =>
                Number(p.id)===id
            );



        pedidos[index]=pedido;



        await salvarPedidos(
            pedidos
        );



        if(global.io){

            global.io.emit(
                "status_pedido_atualizado",
                pedido
            );

        }



        return res.json({

            sucesso:true,

            mensagem:
            "Pedido recusado",

            pedido

        });



    }catch(error){


        return res.status(500).json({

            erro:
            error.message

        });

    }

};




// ======================================================
// ABRIR SUPORTE DO PEDIDO
// POST /api/orders/:id/support
// ======================================================

exports.openSupport = async(req,res)=>{


    try{


        const id =
            Number(req.params.id);



        const pedido =
            await Order.buscarPorId(id);



        if(!pedido){

            return res.status(404).json({

                erro:
                "Pedido não encontrado"

            });

        }



        pedido.suporte = {

            aberto:true,

            mensagem:
            req.body.mensagem || 
            "Solicitação de suporte",

            criadoEm:
            new Date().toISOString()

        };



        const pedidos =
            await Order.listar();



        const index =
            pedidos.findIndex(
                p =>
                Number(p.id)===id
            );



        pedidos[index]=pedido;



        await salvarPedidos(
            pedidos
        );



        return res.json({

            sucesso:true,

            mensagem:
            "Suporte aberto",

            pedido

        });



    }catch(error){


        return res.status(500).json({

            erro:
            error.message

        });

    }

};
