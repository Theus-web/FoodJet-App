import 'package:flutter/material.dart';


class WalletScreen extends StatelessWidget {

  const WalletScreen({
    super.key,
  });


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
      const Color(0xFFF5F5F5),


      appBar: AppBar(

        title:

        const Text(

          "Carteira",

          style:

          TextStyle(

            color: Colors.black,

            fontWeight:
            FontWeight.bold,

          ),

        ),


        backgroundColor:
        Colors.white,


        elevation: 0,


        iconTheme:

        const IconThemeData(

          color: Colors.black,

        ),

      ),



      body:

      Padding(

        padding:
        const EdgeInsets.all(16),


        child:

        Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [


            Container(

              width:
              double.infinity,


              padding:
              const EdgeInsets.all(25),


              decoration:

              BoxDecoration(

                gradient:

                const LinearGradient(

                  colors: [

                    Color(0xFFF97316),

                    Color(0xFFFFB347),

                  ],

                ),


                borderRadius:

                BorderRadius.circular(25),

              ),



              child:

              Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,


                children: [


                  const Text(

                    "Saldo disponível",

                    style:

                    TextStyle(

                      color:
                      Colors.white,

                      fontSize:16,

                    ),

                  ),



                  const SizedBox(
                    height:10,
                  ),



                  const Text(

                    "R\$ 5.840,00",

                    style:

                    TextStyle(

                      color:
                      Colors.white,

                      fontSize:32,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),



                  const SizedBox(
                    height:20,
                  ),



                  ElevatedButton(

                    onPressed: () {


                    },


                    style:

                    ElevatedButton.styleFrom(

                      backgroundColor:
                      Colors.white,


                    ),



                    child:

                    const Text(

                      "Solicitar saque",

                      style:

                      TextStyle(

                        color:
                        Color(0xFFF97316),

                      ),

                    ),

                  )


                ],

              ),

            ),



            const SizedBox(
              height:25,
            ),



            const Text(

              "Resumo",

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




            _item(

              Icons.shopping_bag,

              "Total vendido",

              "R\$ 32.000,00",

            ),



            _item(

              Icons.schedule,

              "A receber",

              "R\$ 4.200,00",

            ),



            _item(

              Icons.check_circle,

              "Recebido",

              "R\$ 27.800,00",

            ),



          ],

        ),

      ),

    );

  }



  Widget _item(

      IconData icon,

      String titulo,

      String valor,

      ){


    return Container(

      margin:

      const EdgeInsets.only(
          bottom:12
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

      Row(

        children: [


          Icon(

            icon,

            color:

            const Color(0xFFF97316),

          ),



          const SizedBox(
            width:15,
          ),



          Expanded(

            child:

            Text(

              titulo,

              style:

              const TextStyle(

                fontSize:16,

              ),

            ),

          ),



          Text(

            valor,

            style:

            const TextStyle(

              fontWeight:
              FontWeight.bold,

            ),

          )

        ],

      ),

    );

  }

}