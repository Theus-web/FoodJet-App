import 'package:flutter/material.dart';


class RestaurantHomeScreen extends StatelessWidget {

  const RestaurantHomeScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor:
            const Color(0xFFF97316),

        title: const Text(
          "FoodJet Restaurante",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(

            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),

            onPressed: () {},

          ),

        ],

      ),


      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [


            const Text(

              "Olá, Restaurante 👋",

              style: TextStyle(

                fontSize: 24,

                fontWeight:
                    FontWeight.bold,

              ),

            ),



            const SizedBox(height: 20),



            Row(

              children: [


                Expanded(

                  child:
                      _cardIndicador(

                        "Vendas hoje",

                        "R\$ 0,00",

                        Icons.attach_money,

                      ),

                ),



                const SizedBox(width: 12),



                Expanded(

                  child:
                      _cardIndicador(

                        "Pedidos",

                        "0",

                        Icons.shopping_bag,

                      ),

                ),


              ],

            ),




            const SizedBox(height: 25),




            const Text(

              "Gerenciamento",

              style: TextStyle(

                fontSize: 20,

                fontWeight:
                    FontWeight.bold,

              ),

            ),




            const SizedBox(height: 15),




            _menuCard(

              context,

              "Pedidos",

              "Gerencie pedidos recebidos",

              Icons.receipt_long,

            ),




            _menuCard(

              context,

              "Produtos",

              "Cadastre e edite produtos",

              Icons.restaurant_menu,

            ),





            _menuCard(

              context,

              "Cardápio",

              "Organize categorias",

              Icons.menu_book,

            ),





            _menuCard(

              context,

              "Avaliações",

              "Veja opiniões dos clientes",

              Icons.star,

            ),





            _menuCard(

              context,

              "Configurações",

              "Dados do restaurante",

              Icons.settings,

            ),



          ],

        ),

      ),

    );

  }





  Widget _cardIndicador(

      String titulo,

      String valor,

      IconData icone,

      ) {


    return Container(

      padding:
          const EdgeInsets.all(16),


      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(16),

      ),



      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,


        children: [


          Icon(

            icone,

            color:
                Color(0xFFF97316),

          ),



          const SizedBox(height: 10),



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

              fontSize:
                  22,

              fontWeight:
                  FontWeight.bold,

            ),

          ),


        ],

      ),

    );

  }







  Widget _menuCard(

      BuildContext context,

      String titulo,

      String descricao,

      IconData icone,

      ) {


    return Container(

      margin:
          const EdgeInsets.only(
            bottom: 12,
          ),


      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(16),

      ),



      child: ListTile(


        leading:

            Container(

              padding:
                  const EdgeInsets.all(10),


              decoration:
                  BoxDecoration(

                color:
                    const Color(0xFFFFEDD5),

                borderRadius:
                    BorderRadius.circular(12),

              ),


              child:
                  Icon(

                    icone,

                    color:
                        const Color(0xFFF97316),

                  ),

            ),



        title:
            Text(

              titulo,

              style:
                  const TextStyle(

                fontWeight:
                    FontWeight.bold,

              ),

            ),



        subtitle:
            Text(
              descricao,
            ),



        trailing:
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),



        onTap: () {},


      ),

    );

  }


}