import 'package:flutter/material.dart';

import '../../services/promotion_service.dart';
import 'criar_promocao_screen.dart';


class PromocoesScreen extends StatefulWidget {

  final String restauranteId;


  const PromocoesScreen({
    super.key,
    required this.restauranteId,
  });


  @override
  State<PromocoesScreen> createState() =>
      _PromocoesScreenState();

}



class _PromocoesScreenState
    extends State<PromocoesScreen> {


  final PromotionService service =
      PromotionService();


  bool carregando = true;


  List<Map<String,dynamic>> promocoes = [];



  static const Color laranja =
      Color(0xFFF97316);



  @override
  void initState(){

    super.initState();

    carregar();

  }




  Future<void> carregar() async {


    try{


      setState((){

        carregando = true;

      });



      final resultado =
          await service.buscarPromocoes(
            widget.restauranteId,
          );



      if(!mounted)return;



      setState((){

        promocoes = resultado;

        carregando = false;

      });



    }catch(e){


      if(!mounted)return;


      setState((){

        carregando=false;

      });



      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(
            'Erro ao carregar promoções',
          ),
        ),
      );


    }

  }







  Future<void> alterarStatus(
      Map<String,dynamic> promocao
      ) async {



    final id =
        promocao['id']
        ?.toString();



    if(id==null)return;




    await service.alterarStatus(
      id,
      !(promocao['ativa'] ?? false),
    );



    carregar();


  }






  Future<void> excluir(
      Map<String,dynamic> promocao
      ) async {



    final id =
        promocao['id']
        ?.toString();



    if(id==null)return;




    await service.excluirPromocao(
      id,
    );



    carregar();


  }







  @override
  Widget build(BuildContext context){


    return Scaffold(


      backgroundColor:
          Colors.grey.shade100,



      appBar: AppBar(

        backgroundColor:
            laranja,


        title:
        const Text(
          'Promoções',
        ),


      ),





      floatingActionButton:
      FloatingActionButton.extended(


        backgroundColor:
            laranja,


        icon:
        const Icon(
          Icons.add,
        ),


        label:
        const Text(
          'Nova promoção',
        ),



        onPressed: () async{


          await Navigator.push(

            context,

            MaterialPageRoute(

              builder:(_)=>
                  CriarPromocaoScreen(
                    restauranteId:
                    widget.restauranteId,
                  ),

            ),

          );


          carregar();


        },

      ),





      body:


      carregando

          ?

      const Center(

        child:
        CircularProgressIndicator(),

      )


          :

      promocoes.isEmpty


          ?

      Center(

        child:

        Column(

          mainAxisAlignment:
          MainAxisAlignment.center,


          children:[


            Icon(

              Icons.local_offer_outlined,

              size:70,

              color:
              Colors.grey,

            ),


            const SizedBox(
              height:15,
            ),


            const Text(
              'Nenhuma promoção criada',
              style:
              TextStyle(
                fontSize:18,
                fontWeight:
                FontWeight.bold,
              ),
            ),


          ],

        ),

      )



          :


      RefreshIndicator(


        onRefresh:
        carregar,



        child:

        ListView.builder(


          padding:
          const EdgeInsets.all(16),



          itemCount:
          promocoes.length,



          itemBuilder:
              (_,index){



            final p =
            promocoes[index];



            final ativa =
                p['ativa'] ?? false;



            return Card(


              elevation:
              4,


              margin:
              const EdgeInsets.only(
                bottom:15,
              ),



              shape:
              RoundedRectangleBorder(

                borderRadius:
                BorderRadius.circular(
                  18,
                ),

              ),



              child:
              Padding(


                padding:
                const EdgeInsets.all(
                  16,
                ),



                child:

                Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,



                  children:[



                    Row(

                      children:[


                        Expanded(

                          child:

                          Text(

                            p['titulo']
                                ??
                                'Promoção',

                            style:
                            const TextStyle(

                              fontSize:20,

                              fontWeight:
                              FontWeight.bold,

                            ),

                          ),

                        ),



                        Switch(

                          value:
                          ativa,

                          activeColor:
                          laranja,


                          onChanged:
                              (_)=>
                              alterarStatus(
                                p,
                              ),

                        )


                      ],

                    ),




                    const SizedBox(
                      height:10,
                    ),




                    Text(

                      p['descricao']
                          ??
                          '',

                      style:

                      TextStyle(

                        color:
                        Colors.grey.shade700,

                      ),

                    ),




                    const SizedBox(
                      height:15,
                    ),





                    Row(

                      children:[



                        Text(

                          '🔥 ${p['desconto'] ?? 0}% OFF',

                          style:
                          const TextStyle(

                            color:
                            laranja,

                            fontWeight:
                            FontWeight.bold,

                          ),

                        ),




                        const Spacer(),




                        IconButton(

                          icon:
                          const Icon(
                            Icons.delete,
                            color:
                            Colors.red,
                          ),


                          onPressed:
                              ()=>excluir(
                                p,
                              ),

                        )



                      ],

                    )


                  ],

                ),

              ),


            );

          },


        ),

      ),


    );


  }


}