const { v4: uuid } = require("uuid");
const { db } = require("../config/database");


// ======================================================
// CRIAR PROMOÇÃO
// POST /api/promocoes
// ======================================================

exports.create = async (req, res) => {

    try {

        const promocao = {

            id: uuid(),

            restauranteId:
                req.body.restauranteId,

            produtoId:
                req.body.produtoId || null,

            titulo:
                req.body.titulo,

            descricao:
                req.body.descricao || "",

            precoOriginal:
                Number(req.body.precoOriginal || 0),

            precoPromocional:
                Number(req.body.precoPromocional || 0),

            desconto:
                Number(req.body.desconto || 0),

            inicio:
                req.body.inicio || null,

            fim:
                req.body.fim || null,

            ativa:
                true,

            criadoEm:
                new Date()

        };


        if(!promocao.restauranteId){

            return res.status(400).json({

                erro:
                "restauranteId obrigatório"

            });

        }



        if(!db.data.promocoes){

            db.data.promocoes = [];

        }



        db.data.promocoes.push(
            promocao
        );


        await db.write();



        return res.status(201).json(
            promocao
        );


    } catch(error){


        console.log(error);


        return res.status(500).json({

            erro:
            "Erro ao criar promoção"

        });

    }

};





// ======================================================
// LISTAR PROMOÇÕES DO RESTAURANTE
// GET /api/promocoes/restaurante/:id
// ======================================================

exports.listarRestaurante = async (req,res)=>{


    try {


        const id =
            req.params.id;



        const promocoes =
            (db.data.promocoes || [])
            .filter(
                p =>
                p.restauranteId == id
            );



        return res.json(
            promocoes
        );


    } catch(error){


        return res.status(500).json({

            erro:
            "Erro ao buscar promoções"

        });


    }

};





// ======================================================
// LISTAR PROMOÇÕES ATIVAS CLIENTE
// GET /api/promocoes
// ======================================================

exports.listarAtivas = async(req,res)=>{


    try {


        const hoje =
            new Date();



        const promocoes =
            (db.data.promocoes || [])
            .filter(p=>{


                if(!p.ativa)
                    return false;



                if(p.inicio){

                    if(
                        hoje <
                        new Date(p.inicio)
                    ){

                        return false;

                    }

                }



                if(p.fim){

                    if(
                        hoje >
                        new Date(p.fim)
                    ){

                        return false;

                    }

                }


                return true;


            });



        return res.json(
            promocoes
        );



    }catch(error){


        return res.status(500).json({

            erro:
            "Erro ao buscar promoções"

        });


    }

};





// ======================================================
// ATIVAR / DESATIVAR
// PUT /api/promocoes/:id/status
// ======================================================

exports.status = async(req,res)=>{


    try{


        const promocao =
            db.data.promocoes.find(
                p =>
                p.id ==
                req.params.id
            );



        if(!promocao){

            return res.status(404).json({

                erro:
                "Promoção não encontrada"

            });

        }



        promocao.ativa =
            req.body.ativa;



        await db.write();



        return res.json(
            promocao
        );


    }catch(error){


        return res.status(500).json({

            erro:
            "Erro atualizar promoção"

        });


    }

};





// ======================================================
// EXCLUIR
// DELETE /api/promocoes/:id
// ======================================================

exports.delete = async(req,res)=>{


    try{


        db.data.promocoes =
            (db.data.promocoes || [])
            .filter(
                p =>
                p.id != req.params.id
            );


        await db.write();



        return res.json({

            sucesso:true

        });


    }catch(error){


        return res.status(500).json({

            erro:
            "Erro excluir promoção"

        });


    }

};