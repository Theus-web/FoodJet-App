const { db } = require("../config/database");


// ======================================================
// GARANTIR ESTRUTURA
// ======================================================

async function garantirEstrutura(){

    if(!db.data.promocoes){

        db.data.promocoes = [];

        await db.write();

    }

}



// ======================================================
// CRIAR PROMOÇÃO
// ======================================================

exports.criar = async (dados)=>{

    await garantirEstrutura();


    const promocao = {

        id:
        Date.now(),


        restauranteId:
        dados.restauranteId,


        plano:
        dados.plano,


        valor:
        Number(
            dados.valor || 0
        ),


        dias:
        Number(
            dados.dias || 30
        ),


        inicio:
        new Date().toISOString(),


        fim:
        new Date(
            Date.now()
            +
            (
                Number(dados.dias || 30)
                *
                24
                *
                60
                *
                60
                *
                1000
            )
        ).toISOString(),


        ativo:
        true,


        criadoEm:
        new Date().toISOString()

    };



    db.data.promocoes.push(
        promocao
    );


    await db.write();



    return promocao;

};





// ======================================================
// LISTAR
// ======================================================

exports.listar = async()=>{

    await garantirEstrutura();


    return db.data.promocoes;

};





// ======================================================
// BUSCAR ATIVA POR RESTAURANTE
// ======================================================

exports.buscarAtiva = async(restauranteId)=>{


    await garantirEstrutura();


    const agora =
    new Date();



    return db.data.promocoes.find(

        item =>

        String(
            item.restauranteId
        )
        ===
        String(
            restauranteId
        )

        &&

        item.ativo === true

        &&

        new Date(
            item.fim
        )
        >
        agora

    );


};





// ======================================================
// DESATIVAR
// ======================================================

exports.desativar = async(id)=>{


    await garantirEstrutura();



    const promocao =
    db.data.promocoes.find(

        item =>
        Number(item.id)
        ===
        Number(id)

    );



    if(promocao){

        promocao.ativo =
        false;


        await db.write();

    }



    return promocao;

};