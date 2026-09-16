import 'package:flutter/material.dart';

class ForgotPasswordScreen
    extends StatelessWidget {
  const ForgotPasswordScreen({
    super.key,
  });

  static const Color laranja =
      Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Recuperar senha',
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            const SizedBox(
              height: 30,
            ),

            const Text(
              'Esqueceu sua senha?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Digite seu e-mail para recuperar o acesso.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            TextField(
              keyboardType:
                  TextInputType.emailAddress,

              style:
                  const TextStyle(
                color: Colors.white,
              ),

              decoration:
                  InputDecoration(
                hintText:
                    'E-mail',

                hintStyle:
                    const TextStyle(
                  color:
                      Colors.white54,
                ),

                prefixIcon:
                    const Icon(
                  Icons.email_outlined,
                  color:
                      Colors.white70,
                ),

                filled: true,

                fillColor:
                    const Color(
                  0xFF171717,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              height: 55,

              child:
                  ElevatedButton(
                onPressed: () {},

                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      laranja,

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),

                child:
                    const Text(
                  'RECUPERAR SENHA',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
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