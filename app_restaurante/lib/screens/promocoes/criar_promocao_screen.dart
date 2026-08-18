import 'package:flutter/material.dart';

import '../../services/promotion_service.dart';


class CriarPromocaoScreen extends StatefulWidget {

  final String restauranteId;


  const CriarPromocaoScreen({
    super.key,
    required this.restauranteId,
  });



  @override
  State<CriarPromocaoScreen> createState() =>
      _CriarPromocaoScreenState();

}



class _CriarPromocaoScreenState
    extends State<CriarPromocaoScreen> {


  final PromotionService service =
      PromotionService();



  final tituloController =
      TextEditingController();


  final descricaoController =
      TextEditingController();


  final descontoController =
      TextEditingController();


  final produtoController =
      TextEditingController();



  bool salvando = false;



  static const Color laranja =
      Color(0xFFF97316);





  @override
  void dispose(){

    tituloController.dispose();

    descricaoController.dispose();

    descontoController.dispose();

    produtoController.dispose();

    super.dispose();

  }





  Future<void> salvar() async {


    if(tituloController.text.trim().isEmpty){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content:
          Text(
            'Informe o nome da promoção',
          ),

        ),

      );

      return;

    }




    try{


      setState((){

        salvando=true;

      });




      await service.criarPromocao({

        "restauranteId":
        widget.restauranteId,


        "titulo":
        tituloController.text.trim(),


        "descricao":
        descricaoController.text.trim(),


        "produto":
        produtoController.text.trim(),


        "desconto":
        int.tryParse(
          descontoController.text,
        ) ?? 0,


        "ativa":
        true,


      });





      if(!mounted)return;



      Navigator.pop(context);



    }catch(e){


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content:
          Text(
            'Erro ao criar promoção: $e',
          ),

        ),

      );


    }finally{


      if(mounted){

        setState((){

          salvando=false;

        });

      }


    }


  }






  Widget campo(

      String label,

      TextEditingController controller,

      {

        TextInputType? tipo,

      }

      ){


    return Padding(

      padding:
      const EdgeInsets.only(
        bottom:15,
      ),


      child:

      TextField(

        controller:
        controller,


        keyboardType:
        tipo,


        decoration:
        InputDecoration(

          labelText:
          label,


          filled:
          true,


          fillColor:
          Colors.white,


          border:
          OutlineInputBorder(

            borderRadius:
            BorderRadius.circular(
              14,
            ),

          ),

        ),

      ),

    );


  }






  @override
  Widget build(BuildContext context){


    return Scaffold(


      backgroundColor:
      Colors.grey.shade100,



      appBar:
      AppBar(

        backgroundColor:
        laranja,


        title:
        const Text(
          'Nova Promoção',
        ),

      ),




      body:

      SingleChildScrollView(

        padding:
        const EdgeInsets.all(
          16,
        ),


        child:

        Column(

          children:[



            campo(
              'Nome da promoção',
              tituloController,
            ),




            campo(
              'Descrição',
              descricaoController,
            ),




            campo(
              'Produto',
              produtoController,
            ),





            campo(

              'Desconto (%)',

              descontoController,

              tipo:
              TextInputType.number,

            ),




            const SizedBox(
              height:20,
            ),




            SizedBox(

              width:
              double.infinity,


              height:
              55,


              child:

              ElevatedButton(

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  laranja,


                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),

                  ),

                ),



                onPressed:
                salvando
                    ? null
                    : salvar,



                child:

                salvando

                    ?

                const CircularProgressIndicator(
                  color:
                  Colors.white,
                )


                    :

                const Text(

                  'Criar Promoção',

                  style:

                  TextStyle(

                    color:
                    Colors.white,

                    fontSize:
                    17,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),


              ),

            )


          ],

        ),

      ),


    );


  }


}