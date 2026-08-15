import 'package:flutter/material.dart';


class WithdrawScreen extends StatefulWidget {

  const WithdrawScreen({
    super.key,
  });


  @override
  State<WithdrawScreen> createState() =>
      _WithdrawScreenState();

}



class _WithdrawScreenState
    extends State<WithdrawScreen> {


  final valorController =
  TextEditingController();


  String pixSelecionado = "CPF";


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

          "Solicitar Saque",

          style:

          TextStyle(

            color: Colors.black,

            fontWeight:
            FontWeight.bold,

          ),

        ),

      ),



      body:

      SingleChildScrollView(

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

              const EdgeInsets.all(20),


              decoration:

              BoxDecoration(

                color:
                Colors.white,


                borderRadius:

                BorderRadius.circular(20),

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
                      Colors.grey,

                    ),

                  ),



                  const SizedBox(
                    height:8,
                  ),



                  const Text(

                    "R\$ 5.840,00",

                    style:

                    TextStyle(

                      fontSize:30,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  )


                ],

              ),

            ),




            const SizedBox(
              height:25,
            ),




            const Text(

              "Valor do saque",

              style:

              TextStyle(

                fontSize:18,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(
              height:10,
            ),



            TextField(

              controller:
              valorController,


              keyboardType:
              TextInputType.number,


              decoration:

              InputDecoration(

                prefixText:
                "R\$ ",


                hintText:
                "Digite o valor",


                filled:
                true,


                fillColor:
                Colors.white,


                border:

                OutlineInputBorder(

                  borderRadius:

                  BorderRadius.circular(15),

                  borderSide:
                  BorderSide.none,

                ),

              ),

            ),




            const SizedBox(
              height:25,
            ),




            const Text(

              "Chave PIX",

              style:

              TextStyle(

                fontSize:18,

                fontWeight:
                FontWeight.bold,

              ),

            ),




            const SizedBox(
              height:10,
            ),




            DropdownButtonFormField<String>(


              value:
              pixSelecionado,


              decoration:

              InputDecoration(

                filled:
                true,


                fillColor:
                Colors.white,


                border:

                OutlineInputBorder(

                  borderRadius:

                  BorderRadius.circular(15),

                  borderSide:
                  BorderSide.none,

                ),

              ),



              items:

              const [


                DropdownMenuItem(

                  value:"CPF",

                  child:
                  Text("CPF"),

                ),



                DropdownMenuItem(

                  value:"CNPJ",

                  child:
                  Text("CNPJ"),

                ),



                DropdownMenuItem(

                  value:"Telefone",

                  child:
                  Text("Telefone"),

                ),



                DropdownMenuItem(

                  value:"Email",

                  child:
                  Text("Email"),

                ),


              ],



              onChanged:(value){


                setState(() {

                  pixSelecionado =
                      value!;

                });


              },


            ),





            const SizedBox(
              height:30,
            ),




            SizedBox(

              width:
              double.infinity,


              child:

              ElevatedButton(

                onPressed: () {


                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      content:

                      Text(

                        "Solicitação enviada",

                      ),

                    ),

                  );


                },


                style:

                ElevatedButton.styleFrom(

                  backgroundColor:

                  const Color(0xFFF97316),


                  padding:

                  const EdgeInsets.all(16),


                  shape:

                  RoundedRectangleBorder(

                    borderRadius:

                    BorderRadius.circular(15),

                  ),

                ),



                child:

                const Text(

                  "Solicitar saque",

                  style:

                  TextStyle(

                    color:
                    Colors.white,

                    fontSize:17,

                  ),

                ),

              ),

            ),




            const SizedBox(
              height:30,
            ),




            const Text(

              "Histórico de saques",

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





            _withdrawItem(

              "01/08/2026",

              "R\$ 1.500,00",

              "Pago",

            ),




            _withdrawItem(

              "28/07/2026",

              "R\$ 900,00",

              "Processando",

            ),



          ],

        ),

      ),

    );

  }






  Widget _withdrawItem(

      String data,

      String valor,

      String status,

      ){


    return Card(

      child:

      ListTile(

        leading:

        const Icon(

          Icons.account_balance_wallet,

          color:
          Color(0xFFF97316),

        ),


        title:

        Text(valor),


        subtitle:

        Text(data),



        trailing:

        Text(

          status,

          style:

          TextStyle(

            color:

            status=="Pago"

                ? Colors.green

                : Colors.orange,

          ),

        ),

      ),

    );


  }

}