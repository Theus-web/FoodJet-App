import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/restaurant_provider.dart';

import 'screens/login_screen.dart';



void main() {


  runApp(

    const FoodJetApp(),


  );


}





class FoodJetApp extends StatelessWidget {


  const FoodJetApp({
    super.key,
  });





  @override
  Widget build(BuildContext context) {


    return MultiProvider(


      providers: [


        ChangeNotifierProvider(


          create: (_) =>

          RestaurantProvider(),


        ),


      ],




      child:

      MaterialApp(


        debugShowCheckedModeBanner:

        false,



        title:

        "FoodJet Restaurante",



        theme:


        ThemeData(


          colorScheme:

          ColorScheme.fromSeed(

            seedColor:

            const Color(0xFFF97316),

          ),



          useMaterial3:

          true,


        ),




        home:

        const LoginScreen(),



      ),


    );


  }


}