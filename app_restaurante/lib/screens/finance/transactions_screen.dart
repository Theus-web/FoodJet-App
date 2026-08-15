import 'package:flutter/material.dart';


class TransactionsScreen extends StatelessWidget {

  const TransactionsScreen({
    super.key,
  });


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
      const Color(0xFFF5F5F5),


      appBar: AppBar(

        backgroundColor:
        Colors.white,

        elevation: 0,


        iconTheme:

        const IconThemeData(

          color: Colors.black,

        ),


        title:

        const Text(

          "Transações",

          style:

          TextStyle(

            color: Colors.black,

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),



      body:

      Column(

        children: [


          Padding(

            padding:
            const EdgeInsets.all(16),


            child:

            Row(

              children: [


                _filterButton(
                  "Hoje",
                ),


                _filterButton(
                  "Semana",
                ),


                _filterButton(
                  "Mês",
                ),


              ],

            ),

          ),





          Expanded(

            child:

            ListView(

              padding:

              const EdgeInsets.symmetric(
                horizontal:16,
              ),



              children: [


                _transactionCard(

                  pedido:
                  "#1024",

                  cliente:
                  "João Silva",

                  pagamento:
                  "PIX",

                  valor:
                  "R\$ 56,90",

                  status:
                  "Concluído",

                ),




                _transactionCard(

                  pedido:
                  "#1023",

                  cliente:
                  "Maria Oliveira",

                  pagamento:
                  "Cartão",

                  valor:
                  "R\$ 82,00",

                  status:
                  "Concluído",

                ),




                _transactionCard(

                  pedido:
                  "#1022",

                  cliente:
                  "Carlos Santos",

                  pagamento:
                  "Dinheiro",

                  valor:
                  "R\$ 45,00",

                  status:
                  "Pendente",

                ),



              ],

            ),

          )

        ],

      ),

    );

  }





  Widget _filterButton(String texto){


    return Expanded(

      child:

      Container(

        margin:

        const EdgeInsets.only(
          right:8,
        ),


        child:

        ElevatedButton(

          onPressed: () {},


          child:

          Text(texto),

        ),

      ),

    );


  }







  Widget _transactionCard({

    required String pedido,

    required String cliente,

    required String pagamento,

    required String valor,

    required String status,


  }){


    return Container(

      margin:

      const EdgeInsets.only(
        bottom:12,
      ),



      padding:

      const EdgeInsets.all(16),



      decoration:

      BoxDecoration(

        color:
        Colors.white,


        borderRadius:

        BorderRadius.circular(18),

      ),



      child:

      Row(

        children: [



          Container(

            padding:

            const EdgeInsets.all(12),


            decoration:

            BoxDecoration(

              color:

              const Color(0xFFFFEDD5),


              borderRadius:

              BorderRadius.circular(15),

            ),



            child:

            const Icon(

              Icons.receipt_long,

              color:

              Color(0xFFF97316),

            ),

          ),





          const SizedBox(
            width:15,
          ),





          Expanded(

            child:

            Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,


              children: [



                Text(

                  "Pedido $pedido",

                  style:

                  const TextStyle(

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),



                const SizedBox(
                  height:4,
                ),



                Text(cliente),



                Text(

                  pagamento,

                  style:

                  const TextStyle(

                    color:
                    Colors.grey,

                  ),

                ),


              ],

            ),

          ),





          Column(

            crossAxisAlignment:
            CrossAxisAlignment.end,


            children: [



              Text(

                valor,

                style:

                const TextStyle(

                  fontWeight:
                  FontWeight.bold,

                  fontSize:16,

                ),

              ),



              Text(

                status,

                style:

                TextStyle(

                  color:

                  status == "Concluído"

                      ? Colors.green

                      : Colors.orange,

                ),

              ),



            ],

          )


        ],

      ),

    );


  }

}