import 'package:flutter/material.dart';


class FinanceScreen extends StatelessWidget {

  const FinanceScreen({
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

        title: const Text(

          "Financeiro",

          style: TextStyle(

            color: Colors.black,

            fontWeight:
            FontWeight.bold,

          ),

        ),


        iconTheme:
        const IconThemeData(

          color: Colors.black,

        ),

      ),



      body: SingleChildScrollView(


        padding:
        const EdgeInsets.all(16),



        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [



            const Text(

              "Resumo das vendas",

              style: TextStyle(

                fontSize: 20,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:16),



            _financeCard(

              "Hoje",

              "R\$ 1.250,00",

              Icons.today,

            ),



            _financeCard(

              "Esta semana",

              "R\$ 8.450,00",

              Icons.calendar_view_week,

            ),



            _financeCard(

              "Este mês",

              "R\$ 32.000,00",

              Icons.calendar_month,

            ),



            const SizedBox(height:25),



            const Text(

              "Formas de pagamento",

              style: TextStyle(

                fontSize:20,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:15),



            _paymentCard(

              "PIX",

              "R\$ 18.500,00",

              Icons.pix,

            ),



            _paymentCard(

              "Cartão",

              "R\$ 10.300,00",

              Icons.credit_card,

            ),



            _paymentCard(

              "Dinheiro",

              "R\$ 3.200,00",

              Icons.money,

            ),



            const SizedBox(height:25),




            const Text(

              "Últimas transações",

              style: TextStyle(

                fontSize:20,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:15),



            _transaction(

              "#1024",

              "Pizza Calabresa",

              "R\$56,90",

            ),



            _transaction(

              "#1023",

              "X-Bacon",

              "R\$42,00",

            ),


          ],

        ),

      ),

    );

  }





  Widget _financeCard(

      String titulo,

      String valor,

      IconData icon,

      ){


    return Container(

      margin:
      const EdgeInsets.only(
          bottom:12
      ),


      padding:
      const EdgeInsets.all(18),


      decoration: BoxDecoration(

        color:
        Colors.white,


        borderRadius:
        BorderRadius.circular(18),

      ),



      child: Row(

        children: [


          Container(

            padding:
            const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color:
              const Color(0xFFFFEDD5),

              borderRadius:
              BorderRadius.circular(15),

            ),


            child: Icon(

              icon,

              color:
              const Color(0xFFF97316),

            ),

          ),



          const SizedBox(width:15),



          Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,


            children: [

              Text(

                titulo,

                style:
                const TextStyle(

                  color:
                  Colors.grey,

                ),

              ),


              Text(

                valor,

                style:
                const TextStyle(

                  fontSize:22,

                  fontWeight:
                  FontWeight.bold,

                ),

              )

            ],

          )

        ],

      ),

    );

  }






  Widget _paymentCard(

      String titulo,

      String valor,

      IconData icon,

      ){


    return Card(

      child: ListTile(

        leading:

        Icon(

          icon,

          color:
          const Color(0xFFF97316),

        ),


        title:
        Text(titulo),


        trailing:

        Text(

          valor,

          style:
          const TextStyle(

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),

    );


  }







  Widget _transaction(

      String pedido,

      String produto,

      String valor,

      ){


    return Card(

      child: ListTile(

        leading:

        const CircleAvatar(

          child:
          Icon(Icons.receipt),

        ),



        title:

        Text(

          "Pedido $pedido",

        ),



        subtitle:

        Text(produto),



        trailing:

        Text(

          "+ $valor",

          style:

          const TextStyle(

            color:
            Colors.green,

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),

    );

  }

}