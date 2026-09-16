import 'package:app_entregador/screens/auth/cadastro_screen.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';
// ignore: unused_import
import 'screens/auth/cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final emailController =
      TextEditingController();

  final senhaController =
      TextEditingController();

  bool carregando = false;
  bool esconderSenha = true;

  String? erro;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();

    super.dispose();
  }

  Future<void> entrar() async {
    FocusScope.of(context).unfocus();

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      await AuthService.login(
        email: emailController.text,
        senha: senhaController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF97316),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration:
                      const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 58,
                    color:
                        Color(0xFFF97316),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'FoodJet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const Text(
                  'ENTREGADOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  padding:
                      const EdgeInsets.all(24),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      TextField(
                        controller:
                            emailController,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                        decoration:
                            InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon:
                              const Icon(
                            Icons.email_outlined,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            senhaController,
                        obscureText:
                            esconderSenha,
                        decoration:
                            InputDecoration(
                          labelText: 'Senha',
                          prefixIcon:
                              const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                esconderSenha =
                                    !esconderSenha;
                              });
                            },
                            icon: Icon(
                              esconderSenha
                                  ? Icons
                                      .visibility
                                  : Icons
                                      .visibility_off,
                            ),
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      if (erro != null) ...[
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.red
                                .withValues(
                              alpha: .08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Text(
                            erro!,
                            style:
                                const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 24,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton(
                          onPressed:
                              carregando
                                  ? null
                                  : entrar,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFFF97316,
                            ),
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                          child: carregando
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        Colors.white,
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Text(
                                  'ENTRAR',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CadastroScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Ainda não sou entregador',
                          style: TextStyle(
                            color:
                                Color(0xFFF97316),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}