import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../register/register_screen.dart';
import '../auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  final AuthService authService = AuthService();

  bool carregando = false;
  bool mostrarSenha = false;

  static const Color laranja = Color(0xFFF97316);

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();

    super.dispose();
  }

  // ==================================================
  // LOGIN
  // ==================================================

  Future<void> entrar() async {
    final email =
        emailController.text.trim().toLowerCase();

    final senha =
        senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mensagem(
        'Preencha o e-mail e a senha.',
        erro: true,
      );
      return;
    }

    if (!email.contains('@')) {
      _mensagem(
        'Digite um e-mail válido.',
        erro: true,
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final resultado =
          await authService.login(
        email,
        senha,
      );

      print('RESULTADO LOGIN: $resultado');
      print(
        'USUARIO LOGIN: ${resultado['usuario']}',
      );

      if (!mounted) return;

      if (resultado['usuario'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              usuario:
                  Map<String, dynamic>.from(
                resultado['usuario'],
              ),
            ),
          ),
        );
      } else {
        final mensagem =
            resultado['erro']?.toString() ??
            resultado['mensagem']?.toString() ??
            'Erro ao fazer login.';

        _mensagem(
          mensagem,
          erro: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mensagem(
        'Não foi possível conectar ao servidor.',
        erro: true,
      );

      print(
        'ERRO LOGIN: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ==================================================
  // ESQUECI MINHA SENHA
  // ==================================================

  void esqueciSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ForgotPasswordScreen(),
      ),
    );
  }

  // ==================================================
  // MENSAGEM
  // ==================================================

  void _mensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
            erro
                ? Colors.red
                : Colors.green,
        duration:
            const Duration(
          seconds: 3,
        ),
      ),
    );
  }

  // ==================================================
  // TELA
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: laranja,

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 25,
          ),

          child: Column(
            children: [
              const SizedBox(
                height: 45,
              ),

              // ==================================================
              // LOGO
              // ==================================================

              Container(
                width: 100,
                height: 100,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  size: 65,
                  color: laranja,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'FoodJet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Delivery rápido e inteligente',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 55,
              ),

              // ==================================================
              // E-MAIL
              // ==================================================

              TextField(
                controller:
                    emailController,
                keyboardType:
                    TextInputType.emailAddress,
                style:
                    const TextStyle(
                  color: Colors.black,
                ),
                decoration:
                    InputDecoration(
                  filled: true,
                  fillColor:
                      Colors.white,
                  hintText:
                      'E-mail',
                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                    color: Colors.black,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // SENHA
              // ==================================================

              TextField(
                controller:
                    senhaController,
                obscureText:
                    !mostrarSenha,
                style:
                    const TextStyle(
                  color: Colors.black,
                ),
                decoration:
                    InputDecoration(
                  filled: true,
                  fillColor:
                      Colors.white,
                  hintText:
                      'Senha',
                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                    color: Colors.black,
                  ),
                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      mostrarSenha
                          ? Icons
                              .visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        mostrarSenha =
                            !mostrarSenha;
                      });
                    },
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // ESQUECI SENHA
              // ==================================================

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      carregando
                          ? null
                          : esqueciSenha,
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // ENTRAR
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 55,
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
                        Colors.black,
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
                      carregando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'ENTRAR',
                              style:
                                  TextStyle(
                                fontSize:
                                    18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // DIVISOR
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color:
                          Colors.white54,
                    ),
                  ),

                  const Padding(
                    padding:
                        EdgeInsets
                            .symmetric(
                      horizontal: 15,
                    ),
                    child: Text(
                      'OU',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Divider(
                      color:
                          Colors.white54,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // CRIAR CONTA
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child:
                    OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const RegisterScreen(),
                      ),
                    );
                  },
                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        Colors.white,
                    side:
                        const BorderSide(
                      color:
                          Colors.white,
                      width: 1.5,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),
                  child: const Text(
                    'CRIAR UMA CONTA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 35,
              ),

              // ==================================================
              // TERMOS
              // ==================================================

              const Text(
                'Ao continuar, você concorda com os '
                'termos de uso e política de privacidade '
                'do FoodJet.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),

              const SizedBox(
                height: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}