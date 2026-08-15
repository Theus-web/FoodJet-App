import 'package:flutter/material.dart';


class StatusFilter extends StatelessWidget {


  final String selecionado;

  final Function(String) onChanged;



  const StatusFilter({

    super.key,

    required this.selecionado,

    required this.onChanged,

  });



  final List<String> status = const [

    "Todos",

    "Novos",

    "Preparando",

    "Prontos",

    "Entregues",

  ];




  @override
  Widget build(BuildContext context) {


    return SizedBox(

      height:50,


      child:

      ListView.builder(

        scrollDirection:
        Axis.horizontal,


        padding:

        const EdgeInsets.symmetric(
          horizontal:16,
        ),



        itemCount:
        status.length,



        itemBuilder:
        (context,index){



          final item =
          status[index];



          bool ativo =
          selecionado == item;



          return Padding(

            padding:

            const EdgeInsets.only(
              right:10,
            ),



            child:

            GestureDetector(

              onTap:(){

                onChanged(item);

              },



              child:

              Container(

                padding:

                const EdgeInsets.symmetric(

                  horizontal:18,

                  vertical:10,

                ),



                decoration:

                BoxDecoration(

                  color:

                  ativo

                      ? const Color(0xFFF97316)

                      : Colors.white,



                  borderRadius:

                  BorderRadius.circular(25),



                  border:

                  Border.all(

                    color:

                    ativo

                        ? const Color(0xFFF97316)

                        : Colors.grey.shade300,

                  ),

                ),




                child:

                Text(

                  item,


                  style:

                  TextStyle(

                    color:

                    ativo

                        ? Colors.white

                        : Colors.black,


                    fontWeight:

                    ativo

                        ? FontWeight.bold

                        : FontWeight.normal,

                  ),

                ),


              ),

            ),

          );


        },

      ),

    );

  }

}