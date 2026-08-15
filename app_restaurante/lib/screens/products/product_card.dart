import 'package:flutter/material.dart';

import '../../models/product_model.dart';



class ProductCard extends StatelessWidget {


  final ProductModel produto;


  final VoidCallback onEditar;


  final VoidCallback onExcluir;


  final VoidCallback onDisponibilidade;


  final VoidCallback onDestaque;



  const ProductCard({

    super.key,

    required this.produto,

    required this.onEditar,

    required this.onExcluir,

    required this.onDisponibilidade,

    required this.onDestaque,

  });





  @override
  Widget build(BuildContext context) {


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
        BorderRadius.circular(18),

      ),




      child:
      Padding(

        padding:
        const EdgeInsets.all(12),



        child:
        Column(

          children: [




            Row(

              children: [



                produto.imagem == null

                    ?

                Container(

                  width:80,

                  height:80,


                  decoration:
                  BoxDecoration(

                    color:
                    Colors.grey.shade200,


                    borderRadius:
                    BorderRadius.circular(15),

                  ),


                  child:
                  const Icon(

                    Icons.fastfood,

                    size:35,

                  ),


                )



                    :


                ClipRRect(

                  borderRadius:
                  BorderRadius.circular(15),


                  child:
                  Image.network(

                    "http://192.168.1.101:3000${produto.imagem}",


                    width:80,

                    height:80,


                    fit:
                    BoxFit.cover,

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

                        produto.nome,


                        style:
                        const TextStyle(

                          fontSize:18,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),




                      const SizedBox(
                        height:5,
                      ),




                      Text(

                        produto.categoria,


                        style:
                        TextStyle(

                          color:
                          Colors.grey.shade600,

                        ),

                      ),




                      const SizedBox(
                        height:5,
                      ),




                      Text(

                        "R\$ ${produto.preco.toStringAsFixed(2)}",


                        style:
                        const TextStyle(

                          fontSize:16,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),



                    ],

                  ),

                ),



              ],

            ),






            const SizedBox(
              height:15,
            ),






            Row(

              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,


              children: [



                Row(

                  children: [



                    Icon(

                      produto.disponivel

                          ?
                      Icons.check_circle

                          :
                      Icons.cancel,


                      color:

                      produto.disponivel

                          ?
                      Colors.green

                          :
                      Colors.red,


                      size:18,

                    ),




                    const SizedBox(
                      width:5,
                    ),




                    Text(

                      produto.disponivel

                          ?
                      "Disponível"

                          :
                      "Indisponível",

                    ),



                  ],

                ),




                GestureDetector(

                  onTap:
                  onDestaque,


                  child:
                  Row(

                    children: [


                      Icon(

                        produto.destaque

                            ?
                        Icons.star

                            :
                        Icons.star_border,


                        color:

                        produto.destaque

                            ?
                        Colors.amber

                            :
                        Colors.grey,

                      ),


                      const SizedBox(
                        width:5,
                      ),


                      const Text(
                        "Destaque",
                      ),


                    ],

                  ),

                ),



              ],

            ),






            const Divider(
              height:25,
            ),





            Row(

              mainAxisAlignment:
              MainAxisAlignment.end,


              children: [



                IconButton(

                  icon:
                  const Icon(
                    Icons.edit,
                  ),


                  color:
                  Colors.blue,


                  onPressed:
                  onEditar,

                ),




                IconButton(

                  icon:
                  const Icon(
                    Icons.visibility,
                  ),


                  color:
                  Colors.orange,


                  onPressed:
                  onDisponibilidade,

                ),




                IconButton(

                  icon:
                  const Icon(
                    Icons.delete,
                  ),


                  color:
                  Colors.red,


                  onPressed:
                  onExcluir,

                ),



              ],

            )




          ],

        ),


      ),


    );


  }


}