import 'package:flutter/material.dart';


class OrderTimeline extends StatelessWidget {


  final String status;


  const OrderTimeline({

    super.key,

    required this.status,

  });



  final List<String> etapas = const [

    "Novo",

    "Aceito",

    "Preparando",

    "Saiu para entrega",

    "Entregue",

  ];



  int getAtual(){

    return etapas.indexOf(status);

  }




  @override
  Widget build(BuildContext context) {


    int atual = getAtual();



    return Column(

      children:

      List.generate(etapas.length, (index){


        bool concluido =
            index <= atual;


        bool ultimo =
            index == etapas.length -1;



        return Row(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [



            Column(

              children: [


                CircleAvatar(

                  radius:14,


                  backgroundColor:


                  concluido

                      ? const Color(0xFFF97316)

                      : Colors.grey.shade300,



                  child:

                  Icon(

                    concluido

                        ? Icons.check

                        : Icons.circle_outlined,


                    size:16,


                    color:

                    concluido

                        ? Colors.white

                        : Colors.grey,

                  ),

                ),



                if(!ultimo)

                  Container(

                    height:45,

                    width:2,


                    color:

                    concluido

                        ? const Color(0xFFF97316)

                        : Colors.grey.shade300,

                  )


              ],

            ),




            const SizedBox(

              width:15,

            ),





            Padding(

              padding:

              const EdgeInsets.only(
                top:5,
              ),



              child:

              Text(

                etapas[index],


                style:

                TextStyle(

                  fontSize:16,


                  fontWeight:

                  concluido

                      ? FontWeight.bold

                      : FontWeight.normal,



                  color:

                  concluido

                      ? Colors.black

                      : Colors.grey,

                ),

              ),

            )


          ],

        );


      }),

    );

  }


}