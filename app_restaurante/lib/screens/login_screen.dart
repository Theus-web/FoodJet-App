
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'restaurant_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  // ==================================================
  // ARMAZENAMENTO SEGURO
  // ==================================================

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  static const String chaveSalvarSenha =
      'foodjet_restaurante_salvar_senha';

  static const String chaveEmailSalvo =
      'foodjet_restaurante_email';

  static const String chaveSenhaSalva =
      'foodjet_restaurante_senha';

  // ==================================================
  // ESTADO
  // ==================================================

  bool carregando = false;
  bool mostrarSenha = false;
  bool salvarSenha = false;

  // ==================================================
  // CORES
  // ==================================================

  static const Color laranja =
      Color(0xFFF97316);

  static const Color fundo =
      Color(0xFFF5F5F5);

  // ==================================================
  // INIT
  // ==================================================

  @override
  void initState() {
    super.initState();

    _carregarLoginSalvo();
  }

  // ==================================================
  // CARREGAR LOGIN SALVO
  // ==================================================

  Future<void> _carregarLoginSalvo() async {
    try {
      final salvar =
          await storage.read(
        key: chaveSalvarSenha,
      );

      if (salvar != 'true') {
        return;
      }

      final email =
          await storage.read(
        key: chaveEmailSalvo,
      );

      final senha =
          await storage.read(
        key: chaveSenhaSalva,
      );

      if (!mounted) return;

      setState(() {
        salvarSenha = true;

        if (email != null) {
          emailController.text = email;
        }

        if (senha != null) {
          senhaController.text = senha;
        }
      });
    } catch (e) {
      print(
        '⚠️ ERRO AO CARREGAR LOGIN SALVO: $e',
      );
    }
  }

  // ==================================================
  // SALVAR / REMOVER LOGIN
  // ==================================================

  Future<void> _salvarOuRemoverLogin({
    required String email,
    required String senha,
  }) async {
    try {
      if (salvarSenha) {
        await storage.write(
          key: chaveSalvarSenha,
          value: 'true',
        );

        await storage.write(
          key: chaveEmailSalvo,
          value: email,
        );

        await storage.write(
          key: chaveSenhaSalva,
          value: senha,
        );

        print(
          '🔐 LOGIN DO RESTAURANTE SALVO COM SEGURANÇA',
        );
      } else {
        await storage.delete(
          key: chaveSalvarSenha,
        );

        await storage.delete(
          key: chaveEmailSalvo,
        );

        await storage.delete(
          key: chaveSenhaSalva,
        );

        print(
          '🗑️ LOGIN SALVO DO RESTAURANTE REMOVIDO',
        );
      }
    } catch (e) {
      print(
        '⚠️ ERRO AO SALVAR LOGIN: $e',
      );
    }
  }

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();

    super.dispose();
  }

  // ==================================================
  // LOGIN
  // ==================================================

  Future<void> fazerLogin() async {
    final email =
        emailController.text.trim().toLowerCase();

    final senha =
        senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _mensagem(
        'Informe seu e-mail e sua senha.',
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
      print('');
      print('========================================');
      print('🏪 LOGIN RESTAURANTE');
      print('📧 E-mail: $email');
      print('========================================');

      final resposta =
          await authService.login(
        email: email,
        senha: senha,
      );

      print(
        '📡 RESPOSTA LOGIN: $resposta',
      );

      final usuario =
          resposta['usuario'];

      if (usuario == null) {
        throw Exception(
          resposta['erro']?.toString() ??
              resposta['mensagem']?.toString() ??
              'Usuário inválido.',
        );
      }

      print(
        '✅ RESTAURANTE AUTENTICADO',
      );

      // ==================================================
      // SALVAR LOGIN SOMENTE APÓS LOGIN BEM-SUCEDIDO
      // ==================================================

      await _salvarOuRemoverLogin(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RestaurantHomeScreen(
            usuario: usuario,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      print(
        '❌ ERRO LOGIN RESTAURANTE: $e',
      );

      _mensagem(
        e.toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
        erro: true,
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
        content: Text(
          mensagem,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            erro ? Colors.red : Colors.green,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==================================================
  // CAMPO
  // ==================================================

  InputDecoration _decoracaoCampo({
    required String hint,
    required IconData icone,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 15,
      ),

      filled: true,

      fillColor: Colors.white,

      prefixIcon: Icon(
        icone,
        color: Colors.grey.shade700,
      ),

      suffixIcon: suffixIcon,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide:
            BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),
        borderSide:
            const BorderSide(
          color: laranja,
          width: 1.5,
        ),
      ),
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

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
                width: 105,
                height: 105,
                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black
                              .withOpacity(
                        0.08,
                      ),
                      blurRadius: 20,
                      offset:
                          const Offset(
                        0,
                        8,
                      ),
                    ),
                  ],
                ),

                child: const Icon(
                  Icons.restaurant,
                  size: 62,
                  color: laranja,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // TÍTULO
              // ==================================================

              const Text(
                'FoodJet Restaurante',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontSize: 29,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Gerencie seu restaurante de forma simples e rápida',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(
                height: 45,
              ),

              // ==================================================
              // E-MAIL
              // ==================================================

              Align(
                alignment:
                    Alignment.centerLeft,

                child: const Text(
                  'E-mail',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    emailController,

                keyboardType:
                    TextInputType.emailAddress,

                textInputAction:
                    TextInputAction.next,

                style:
                    const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),

                decoration:
                    _decoracaoCampo(
                  hint:
                      'Digite seu e-mail',
                  icone:
                      Icons.email_outlined,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // SENHA
              // ==================================================

              Align(
                alignment:
                    Alignment.centerLeft,

                child: const Text(
                  'Senha',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextField(
                controller:
                    senhaController,

                obscureText:
                    !mostrarSenha,

                textInputAction:
                    TextInputAction.done,

                onSubmitted: (_) {
                  if (!carregando) {
                    fazerLogin();
                  }
                },

                style:
                    const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),

                decoration:
                    _decoracaoCampo(
                  hint:
                      'Digite sua senha',

                  icone:
                      Icons.lock_outline,

                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        mostrarSenha =
                            !mostrarSenha;
                      });
                    },

                    icon: Icon(
                      mostrarSenha
                          ? Icons
                              .visibility_off_outlined
                          : Icons
                              .visibility_outlined,

                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // SALVAR SENHA
              // ==================================================

              Row(
                children: [
                  Checkbox(
                    value: salvarSenha,

                    activeColor: laranja,

                    checkColor: Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        5,
                      ),
                    ),

                    onChanged:
                        carregando
                            ? null
                            : (valor) {
                                setState(() {
                                  salvarSenha =
                                      valor ??
                                          false;
                                });
                              },
                  ),

                  const Expanded(
                    child: Text(
                      'Salvar senha',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            Colors.black87,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const ForgotPasswordScreen(),
                                ),
                              );
                            },

                  style:
                      TextButton.styleFrom(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),

                  child:
                      const Text(
                    'Esqueci minha senha',

                    style: TextStyle(
                      color: laranja,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // BOTÃO ENTRAR
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
                          : fazerLogin,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        laranja,

                    foregroundColor:
                        Colors.white,

                    elevation: 2,

                    shadowColor:
                        laranja.withOpacity(
                      0.35,
                    ),

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
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              'ENTRAR',

                              style:
                                  TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing:
                                    0.5,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // DIVISOR
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        Divider(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 15,
                    ),

                    child: Text(
                      'OU',

                      style:
                          TextStyle(
                        color:
                            Colors.grey,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        Divider(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // CRIAR CONTA
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 53,

                child:
                    OutlinedButton(
                  onPressed:
                      carregando
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          const RegisterScreen(),
                                ),
                              );
                            },

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        laranja,

                    side:
                        const BorderSide(
                      color:
                          laranja,
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

                  child:
                      const Text(
                    'CRIAR UMA CONTA',

                    style:
                        TextStyle(
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
              // RODAPÉ
              // ==================================================

              const Text(
                'FoodJet Restaurante',

                style:
                    TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Gerencie seus pedidos, produtos e vendas.',
                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color: Colors.grey,
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

