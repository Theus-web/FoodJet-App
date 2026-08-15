import 'package:flutter/material.dart';


class OrderDetailsScreen extends StatefulWidget {


  final String pedidoId;


  const OrderDetailsScreen({

    super.key,

    required this.pedidoId,

  });



  @override
  State<OrderDetailsScreen> createState() =>
      _OrderDetailsScreenState();

}



class _OrderDetailsScreenState
    extends State<OrderDetailsScreen> {



  String status = "Novo";



  final etapas = [

    "Novo",

    "Preparando",

    "Pronto",

    "Saiu para entrega",

    "Entregue"

  ];



  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
      const Color(0xFFF5F5F5),



      appBar: AppBar(

        backgroundColor:
        Colors.white,

        elevation:0,


        iconTheme:

        const IconThemeData(

          color: Colors.black,

        ),


        title:

        Text(

          "Pedido ${widget.pedidoId}",

          style:

          const TextStyle(

            color: Colors.black,

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),



      body:

      SingleChildScrollView(

        padding:

        const EdgeInsets.all(16),



        child:

        Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [



            _section(

              "Cliente",

              [

                "João Silva",

                "Telefone: (31) 99999-9999",

                "Rua Principal, 120",

              ],

            ),




            _section(

              "Produtos",

              [

                "🍕 Pizza Calabresa x2",

                "🥤 Refrigerante 2L x1",

              ],

            ),




            _section(

              "Pagamento",

              [

                "PIX",

                "Total: R\$85,00",

              ],

            ),




            const SizedBox(
              height:20,
            ),




            const Text(

              "Status do pedido",

              style:

              TextStyle(

                fontSize:20,

                fontWeight:
                FontWeight.bold,

              ),

            ),




            const SizedBox(
              height:15,
            ),




            Wrap(

              spacing:8,

              children:

              etapas.map((item){


                return ChoiceChip(

                  label:
                  Text(item),


                  selected:
                  status == item,



                  onSelected:(value){


                    setState(() {


                      status=item;


                    });



                  },

                );


              }).toList(),

            ),




            const SizedBox(
              height:30,
            ),





            SizedBox(

              width:
              double.infinity,


              child:

              ElevatedButton(

                onPressed:(){


                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    SnackBar(

                      content:

                      Text(

                        "Pedido atualizado: $status",

                      ),

                    ),

                  );


                },


                style:

                ElevatedButton.styleFrom(

                  backgroundColor:

                  const Color(0xFFF97316),


                  padding:

                  const EdgeInsets.all(16),


                ),



                child:

                const Text(

                  "Atualizar pedido",

                  style:

                  TextStyle(

                    color:
                    Colors.white,

                    fontSize:16,

                  ),

                ),

              ),

            )


          ],

        ),

      ),

    );

  }






  Widget _section(

      String titulo,

      List<String> dados,

      ){


    return Container(

      width:
      double.infinity,


      margin:

      const EdgeInsets.only(
        bottom:15,
      ),



      padding:

      const EdgeInsets.all(18),



      decoration:

      BoxDecoration(

        color:
        Colors.white,


        borderRadius:

        BorderRadius.circular(18),

      ),



      child:

      Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [



          Text(

            titulo,

            style:

            const TextStyle(

              fontSize:18,

              fontWeight:
              FontWeight.bold,

            ),

          ),



          const SizedBox(
            height:10,
          ),



          ...dados.map(

                (e)=>

                Padding(

                  padding:

                  const EdgeInsets.only(
                    bottom:5,
                  ),

                  child:

                  Text(e),

                ),

          )


        ],

      ),

    );


  }

}