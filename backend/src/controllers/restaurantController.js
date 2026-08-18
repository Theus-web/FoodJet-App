const Restaurant = require("../models/restaurant");


// ==================================================
// CRIAR RESTAURANTE
// ==================================================

exports.create = async (req, res) => {

    try {

        const restaurante = {

            id: Date.now(),

            nome:
                req.body.nome || "",

            categoria:
                req.body.categoria || "",

            descricao:
                req.body.descricao || "",

            telefone:
                req.body.telefone || "",

            endereco:
                req.body.endereco || "",


            taxaEntrega:
                Number(req.body.taxaEntrega) || 0,


            tempoEntrega:
                req.body.tempoEntrega || "",


            status:
                "ABERTO",


            online:
                true,


            aberto:
                true,


            aceitarAutomatico:
                req.body.aceitarAutomatico !== false,


            criadoEm:
                new Date().toISOString()
        };


        await Restaurant.criar(
            restaurante
        );


        return res.status(201).json({

            sucesso:true,

            mensagem:
                "Restaurante cadastrado com sucesso",

            restaurante
        });


    } catch(error) {


        console.error(
            "ERRO CREATE RESTAURANTE:",
            error
        );


        return res.status(500).json({

            sucesso:false,

            erro:
                "Erro ao cadastrar restaurante",

            detalhe:
                error.message
        });

    }

};



// ==================================================
// LISTAR RESTAURANTES
// ==================================================

exports.list = async (req,res)=>{

    try {


        let lista =
            await Restaurant.listar();



        if(!Array.isArray(lista)){

            lista=[];

        }



        const agora =
            new Date();



        lista =
            lista.map((restaurante)=>{


                let prioridade=0;

                let destaque=false;

                let tipoDestaque=null;



                if(
                    restaurante.promocao &&
                    restaurante.promocao.ativa === true
                ){


                    const validade =
                        new Date(
                            restaurante.promocao.expiraEm
                        );



                    if(validade > agora){


                        destaque=true;


                        tipoDestaque =
                            restaurante.promocao.tipo;



                        if(tipoDestaque==="TOP1"){

                            prioridade=3;

                        }
                        else if(tipoDestaque==="DESTAQUE"){

                            prioridade=2;

                        }
                        else if(tipoDestaque==="IMPULSO"){

                            prioridade=1;

                        }

                    }

                }



                return {

                    ...restaurante,

                    destaque,

                    tipoDestaque,

                    prioridade,

                    selo:
                        destaque
                        ? "Patrocinado FoodJet"
                        : null

                };


            });



        lista.sort(
            (a,b)=>
                b.prioridade-a.prioridade
        );



        return res.json(lista);



    }catch(error){


        console.error(
            "ERRO LISTAR RESTAURANTES:",
            error
        );


        return res.status(500).json({

            erro:
                "Erro ao listar restaurantes",

            detalhe:
                error.message

        });


    }

};

// ==================================================
// BUSCAR RESTAURANTE POR ID
// GET /api/restaurants/:id
// ==================================================

exports.getById = async (req, res) => {

    try {

        const { id } = req.params;


        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

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


        return res.json(restaurante);


    } catch (error) {

        console.error(
            "ERRO AO BUSCAR RESTAURANTE:",
            error
        );


        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao buscar restaurante",

            detalhe:
                error.message

        });

    }

};



// ==================================================
// ATUALIZAR RESTAURANTE
// PUT /api/restaurants/:id
// ==================================================

exports.update = async (req, res) => {

    try {

        const { id } = req.params;


        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

            });

        }


        console.log(
            "========================================"
        );

        console.log(
            "⚙️ ATUALIZANDO RESTAURANTE"
        );

        console.log(
            "ID:",
            id
        );

        console.log(
            "DADOS:",
            req.body
        );

        console.log(
            "========================================"
        );


        const restaurante =
            await Restaurant.atualizar(
                id,
                req.body
            );


        if (!restaurante) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }


        // ==================================================
        // AVISAR CLIENTES PELO WEBSOCKET
        // ==================================================

        if (global.io) {

            global.io.emit(
                "restaurante_atualizado",
                restaurante
            );


            console.log(
                "📡 RESTAURANTE ATUALIZADO ENVIADO AOS CLIENTES"
            );

        }


        return res.json({

            sucesso: true,

            mensagem:
                "Restaurante atualizado com sucesso",

            restaurante

        });


    } catch (error) {

        console.error(
            "ERRO AO ATUALIZAR RESTAURANTE:",
            error
        );


        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro ao atualizar restaurante",

            detalhe:
                error.message

        });

    }

};



// ==================================================
// EXCLUIR RESTAURANTE
// DELETE /api/restaurants/:id
// ==================================================

exports.delete = async (req, res) => {

    try {

        const { id } = req.params;


        console.log(
            "========================================"
        );

        console.log(
            "🗑️ EXCLUSÃO COMPLETA DE CONTA"
        );

        console.log(
            "RESTAURANTE ID:",
            id
        );

        console.log(
            "========================================"
        );


        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do restaurante é obrigatório"

            });

        }


        // ==================================================
        // VERIFICAR RESTAURANTE
        // ==================================================

        const restaurante =
            await Restaurant.buscarPorId(id);


        if (!restaurante) {

            return res.status(404).json({

                sucesso: false,

                erro:
                    "Restaurante não encontrado"

            });

        }


        // ==================================================
        // EXCLUIR DADOS
        // ==================================================

        const resultado =
            await Restaurant.excluir(id);


        if (
            !resultado ||
            resultado.sucesso !== true
        ) {

            return res.status(500).json({

                sucesso: false,

                erro:
                    "Não foi possível excluir a conta do restaurante"

            });

        }


        console.log(
            "✅ EXCLUSÃO CONCLUÍDA"
        );


        console.log(
            "Restaurante:",
            resultado.removidos?.restaurante
        );


        console.log(
            "Produtos:",
            resultado.removidos?.produtos
        );


        console.log(
            "Pedidos:",
            resultado.removidos?.pedidos
        );


        console.log(
            "Pagamentos:",
            resultado.removidos?.pagamentos
        );


        console.log(
            "Outros:",
            resultado.removidos?.outros
        );


        console.log(
            "========================================"
        );


        // ==================================================
        // AVISAR CLIENTES
        // ==================================================

        if (global.io) {

            global.io.emit(
                "restaurante_excluido",
                {

                    restauranteId:
                        String(id)

                }
            );


            console.log(
                "📡 EXCLUSÃO ENVIADA AOS CLIENTES"
            );

        }


        return res.status(200).json({

            sucesso: true,

            mensagem:
                "Conta e dados vinculados ao restaurante foram excluídos com sucesso",

            restauranteId:
                String(id),

            removidos:
                resultado.removidos

        });


    } catch (error) {

        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO AO EXCLUIR RESTAURANTE"
        );

        console.error(error);

        console.error(
            "========================================"
        );


        return res.status(500).json({

            sucesso: false,

            erro:
                "Erro interno ao excluir a conta do restaurante",

            detalhe:
                error.message

        });

    }

};

