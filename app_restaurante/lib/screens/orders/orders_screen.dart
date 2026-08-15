import 'package:flutter/material.dart';


class OrdersScreen extends StatefulWidget {

  const OrdersScreen({
    super.key,
  });


  @override
  State<OrdersScreen> createState() =>
      _OrdersScreenState();

}



class _OrdersScreenState
    extends State<OrdersScreen> {


  String filtro = "Todos";



  final filtros = [

    "Todos",

    "Novos",

    "Preparando",

    "Prontos",

    "Entregues"

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


        title:

        const Text(

          "Pedidos",

          style:

          TextStyle(

            color:Colors.black,

            fontWeight:
            FontWeight.bold,

          ),

        ),


        iconTheme:

        const IconThemeData(

          color:Colors.black,

        ),

      ),




      body:

      Column(

        children: [



          SizedBox(

            height:60,


            child:

            ListView.builder(

              scrollDirection:
              Axis.horizontal,


              padding:

              const EdgeInsets.all(10),



              itemCount:
              filtros.length,



              itemBuilder:(context,index){


                final item =
                filtros[index];


                return Padding(

                  padding:

                  const EdgeInsets.only(
                    right:8,
                  ),


                  child:

                  ChoiceChip(

                    label:

                    Text(item),


                    selected:

                    filtro==item,


                    onSelected:(value){


                      setState(() {

                        filtro=item;

                      });


                    },


                  ),

                );

              },

            ),

          ),




          Expanded(

            child:

            ListView(

              padding:

              const EdgeInsets.all(16),



              children: [


                _orderCard(

                  "#1025",

                  "João Silva",

                  "Novo",

                  "R\$85,00",

                ),



                _orderCard(

                  "#1024",

                  "Maria Oliveira",

                  "Preparando",

                  "R\$56,90",

                ),



                _orderCard(

                  "#1023",

                  "Carlos Santos",

                  "Entregue",

                  "R\$72,00",

                ),


              ],

            ),

          )

        ],

      ),

    );

  }






  Widget _orderCard(

      String pedido,

      String cliente,

      String status,

      String valor,

      ){



    return Container(

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



          Row(

            mainAxisAlignment:

            MainAxisAlignment.spaceBetween,


            children: [


              Text(

                "Pedido $pedido",

                style:

                const TextStyle(

                  fontWeight:
                  FontWeight.bold,

                  fontSize:18,

                ),

              ),



              Text(

                status,

                style:

                TextStyle(

                  color:

                  status=="Novo"

                      ? Colors.red

                      : Colors.orange,

                  fontWeight:
                  FontWeight.bold,

                ),

              )


            ],

          ),



          const SizedBox(
            height:10,
          ),



          Text(cliente),



          const SizedBox(
            height:5,
          ),



          Text(valor),



          const SizedBox(
            height:15,
          ),



          SizedBox(

            width:
            double.infinity,


            child:

            ElevatedButton(

              onPressed:(){},


              style:

              ElevatedButton.styleFrom(

                backgroundColor:

                const Color(0xFFF97316),

              ),



              child:

              const Text(

                "Ver pedido",

                style:

                TextStyle(

                  color:
                  Colors.white,

                ),

              ),

            ),

          )



        ],

      ),

    );


  }

}