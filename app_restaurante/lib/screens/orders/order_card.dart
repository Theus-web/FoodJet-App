import 'package:flutter/material.dart';



class OrderCard extends StatelessWidget {


  final Map<String,dynamic> pedido;


  final VoidCallback onAtualizarStatus;



  const OrderCard({

    super.key,

    required this.pedido,

    required this.onAtualizarStatus,

  });





  Color statusColor(String status){


    switch(status){


      case "AGUARDANDO":

        return Colors.orange;



      case "PREPARANDO":

        return Colors.blue;



      case "PRONTO":

        return Colors.green;



      case "ENTREGUE":

        return Colors.grey;



      default:

        return Colors.black;


    }


  }






  String proximoStatus(String status){


    switch(status){


      case "AGUARDANDO":

        return "ACEITAR PEDIDO";



      case "PREPARANDO":

        return "MARCAR COMO PRONTO";



      case "PRONTO":

        return "FINALIZAR";



      default:

        return "ATUALIZAR";


    }


  }






  @override
  Widget build(BuildContext context){



    final status =

    pedido["status"] ?? "AGUARDANDO";





    return Card(


      margin:

      const EdgeInsets.symmetric(

        horizontal:16,

        vertical:8,

      ),



      elevation:3,



      shape:

      RoundedRectangleBorder(

        borderRadius:

        BorderRadius.circular(16),

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





            Row(

              mainAxisAlignment:

              MainAxisAlignment.spaceBetween,


              children: [



                Text(

                  "Pedido #${pedido["id"]}",


                  style:

                  const TextStyle(

                    fontSize:18,

                    fontWeight:

                    FontWeight.bold,

                  ),

                ),




                Container(



                  padding:

                  const EdgeInsets.symmetric(

                    horizontal:10,

                    vertical:5,

                  ),



                  decoration:

                  BoxDecoration(


                    color:

                    statusColor(status)
                        .withOpacity(0.15),



                    borderRadius:

                    BorderRadius.circular(20),


                  ),




                  child:

                  Text(


                    status,


                    style:

                    TextStyle(

                      color:

                      statusColor(status),


                      fontWeight:

                      FontWeight.bold,


                    ),


                  ),



                ),



              ],



            ),






            const SizedBox(height:15),






            if(pedido["itens"] != null)



              ...(pedido["itens"] as List)

                  .map((item){


                return Text(

                  "${item["quantidade"]}x ${item["nome"]}",


                );


              }),






            const SizedBox(height:10),






            Text(


              "Total: R\$ ${pedido["total"]}",


              style:

              const TextStyle(

                fontSize:17,

                fontWeight:

                FontWeight.bold,

              ),



            ),






            const SizedBox(height:15),






            if(status != "ENTREGUE")



              SizedBox(



                width:

                double.infinity,



                child:

                ElevatedButton(



                  style:

                  ElevatedButton.styleFrom(



                    backgroundColor:

                    const Color(0xFFF97316),



                    shape:

                    RoundedRectangleBorder(

                      borderRadius:

                      BorderRadius.circular(12),

                    ),


                  ),





                  onPressed:

                  onAtualizarStatus,




                  child:

                  Text(

                    proximoStatus(status),


                    style:

                    const TextStyle(

                      color:

                      Colors.white,

                    ),


                  ),



                ),



              ),



          ],



        ),



      ),



    );


  }


}
