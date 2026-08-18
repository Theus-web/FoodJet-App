const Restaurant = require("../models/restaurant");


// ==================================================
// ATIVAR DESTAQUE PAGO
// PUT /api/destaque/:id
// ==================================================

exports.ativar = async (req, res) => {

    try {

        const { id } = req.params;


        const dias =
            Number(req.body.dias) || 30;


        const plano =
            req.body.plano ||
            `${dias}_DIAS`;



        if (!id) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante obrigatório"

            });

        }



        const restaurante =
            await Restaurant.buscarPorId(id);



        if (!restaurante) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }



        const inicio =
            new Date();



        const fim =
            new Date();



        fim.setDate(
            fim.getDate() + dias
        );



        const dados = {


            destaquePago:
                true,


            planoDestaque:
                plano,


            inicioDestaque:
                inicio.toISOString(),


            fimDestaque:
                fim.toISOString(),


            atualizadoEm:
                new Date().toISOString()

        };



        const atualizado =
            await Restaurant.atualizar(
                id,
                dados
            );



        // ==================================================
        // AVISAR CLIENTES
        // ==================================================

        if (global.io) {


            global.io.emit(

                "restaurante_destaque_atualizado",

                atualizado

            );


        }



        return res.json({

            sucesso: true,

            mensagem:
                "Destaque ativado com sucesso",

            restaurante:
                atualizado

        });



    } catch (erro) {


        console.error(
            "ERRO ATIVAR DESTAQUE:",
            erro
        );



        return res.status(500).json({

            sucesso:false,

            erro:
                "Erro ao ativar destaque",

            detalhe:
                erro.message

        });


    }

};




// ==================================================
// REMOVER DESTAQUE
// DELETE /api/destaque/:id
// ==================================================

exports.remover = async (req,res)=>{


    try{


        const {id} =
            req.params;



        if(!id){


            return res.status(400).json({

                sucesso:false,

                erro:
                    "ID obrigatório"

            });


        }



        const restaurante =
            await Restaurant.buscarPorId(id);



        if(!restaurante){


            return res.status(404).json({

                sucesso:false,

                erro:
                    "Restaurante não encontrado"

            });


        }



        const atualizado =
            await Restaurant.atualizar(

                id,

                {

                    destaquePago:false,

                    planoDestaque:null,

                    inicioDestaque:null,

                    fimDestaque:null,

                    atualizadoEm:
                        new Date()
                        .toISOString()

                }

            );




        if(global.io){


            global.io.emit(

                "restaurante_destaque_removido",

                {

                    restauranteId:
                        String(id)

                }

            );


        }




        return res.json({

            sucesso:true,

            mensagem:
                "Destaque removido",

            restaurante:
                atualizado

        });



    }
    catch(erro){


        console.error(
            "ERRO REMOVER DESTAQUE:",
            erro
        );



        return res.status(500).json({

            sucesso:false,

            erro:
                "Erro ao remover destaque",

            detalhe:
                erro.message

        });


    }


};





// ==================================================
// VER STATUS DO DESTAQUE
// GET /api/destaque/:id
// ==================================================

exports.status = async(req,res)=>{


    try{


        const {id}=req.params;



        const restaurante =
            await Restaurant.buscarPorId(id);



        if(!restaurante){


            return res.status(404).json({

                sucesso:false,

                erro:
                    "Restaurante não encontrado"

            });


        }



        let ativo =
            restaurante.destaquePago === true;



        if(ativo && restaurante.fimDestaque){


            const validade =
                new Date(
                    restaurante.fimDestaque
                );



            if(validade < new Date()){


                ativo=false;


                await Restaurant.atualizar(

                    id,

                    {

                        destaquePago:false,

                        planoDestaque:null,

                        inicioDestaque:null,

                        fimDestaque:null

                    }

                );


            }

        }



        return res.json({


            sucesso:true,


            destaquePago:
                ativo,


            inicioDestaque:
                restaurante.inicioDestaque || null,


            fimDestaque:
                restaurante.fimDestaque || null,


            plano:
                restaurante.planoDestaque || null



        });



    }
    catch(erro){


        return res.status(500).json({

            sucesso:false,

            erro:
                "Erro ao consultar destaque",

            detalhe:
                erro.message

        });


    }


};