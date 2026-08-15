import 'package:flutter/material.dart';



class DashboardCard extends StatelessWidget {


  final String titulo;

  final String valor;

  final IconData icon;

  final Color cor;



  const DashboardCard({

    super.key,

    required this.titulo,

    required this.valor,

    required this.icon,

    required this.cor,

  });



  @override
  Widget build(BuildContext context) {


    return Card(

      elevation:3,


      shape:

      RoundedRectangleBorder(

        borderRadius:
        BorderRadius.circular(18),

      ),



      child:

      Padding(

        padding:
        const EdgeInsets.all(16),



        child:

        Column(


          crossAxisAlignment:
          CrossAxisAlignment.start,



          children: [



            Container(

              padding:
              const EdgeInsets.all(10),


              decoration:
              BoxDecoration(

                color:
                cor.withOpacity(0.15),


                shape:
                BoxShape.circle,

              ),



              child:

              Icon(

                icon,

                color:
                cor,

                size:30,

              ),


            ),





            const SizedBox(
              height:15,
            ),





            Text(

              valor,


              style:

              const TextStyle(

                fontSize:24,

                fontWeight:
                FontWeight.bold,

              ),


            ),





            const SizedBox(
              height:5,
            ),





            Text(

              titulo,


              style:

              TextStyle(

                color:
                Colors.grey.shade600,

                fontSize:14,

              ),

            ),



          ],



        ),


      ),


    );


  }


}