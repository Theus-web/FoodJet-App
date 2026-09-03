
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ==================================================
  // SALVAR LOGIN
  // ==================================================

  bool salvarSenha = false;

  static const String chaveSalvarSenha =
      'foodjet_salvar_senha';

  static const String chaveEmailSalvo =
      'foodjet_email_salvo';

  static const String chaveSenhaSalva =
      'foodjet_senha_salva';

  static const Color laranja =
      Color(0xFFF97316);

  @override
  void initState() {
    super.initState();

    _carregarLoginSalvo();
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();

    super.dispose();
  }

  // ==================================================
  // CARREGAR LOGIN SALVO
  // ==================================================

  Future<void> _carregarLoginSalvo() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final salvo =
          prefs.getBool(chaveSalvarSenha) ?? false;

      final email =
          prefs.getString(chaveEmailSalvo) ?? '';

      final senha =
          prefs.getString(chaveSenhaSalva) ?? '';

      if (!mounted) return;

      setState(() {
        salvarSenha = salvo;

        if (salvo) {
          emailController.text = email;
          senhaController.text = senha;
        }
      });

      debugPrint(
        'LOGIN SALVO: ${salvo ? "SIM" : "NÃO"}',
      );
    } catch (e) {
      debugPrint(
        'ERRO AO CARREGAR LOGIN SALVO: $e',
      );
    }
  }

  // ==================================================
  // SALVAR OU REMOVER LOGIN
  // ==================================================

  Future<void> _salvarOuRemoverLogin() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      if (salvarSenha) {
        await prefs.setBool(
          chaveSalvarSenha,
          true,
        );

        await prefs.setString(
          chaveEmailSalvo,
          emailController.text
              .trim()
              .toLowerCase(),
        );

        await prefs.setString(
          chaveSenhaSalva,
          senhaController.text,
        );

        debugPrint(
          'LOGIN SALVO COM SUCESSO',
        );
      } else {
        await prefs.remove(
          chaveSalvarSenha,
        );

        await prefs.remove(
          chaveEmailSalvo,
        );

        await prefs.remove(
          chaveSenhaSalva,
        );

        debugPrint(
          'LOGIN SALVO REMOVIDO',
        );
      }
    } catch (e) {
      debugPrint(
        'ERRO AO SALVAR LOGIN: $e',
      );
    }
  }

  // ==================================================
  // LOGIN
  // ==================================================

  Future<void> entrar() async {
    final email =
        emailController.text
            .trim()
            .toLowerCase();

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

      debugPrint(
        'RESULTADO LOGIN: $resultado',
      );

      debugPrint(
        'USUARIO LOGIN: ${resultado['usuario']}',
      );

      if (!mounted) return;

      if (resultado['usuario'] != null) {
        // ==============================================
        // SALVAR OU REMOVER LOGIN
        // ==============================================

        await _salvarOuRemoverLogin();

        if (!mounted) return;

        // ==============================================
        // IR PARA HOME
        // ==============================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(
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

      debugPrint(
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
                width: 120,
                height: 120,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 15,
                      offset:
                          const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .delivery_dining_rounded,
                        size: 58,
                        color: laranja,
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                        'FoodJet',
                        style:
                            TextStyle(
                          color: laranja,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
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
                'Delivery rápido e inteligente 🚀',
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
                    TextInputType
                        .emailAddress,
                textInputAction:
                    TextInputAction.next,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration:
                    InputDecoration(
                  filled: true,
                  fillColor:
                      Colors.white,
                  hintText: 'E-mail',
                  hintStyle:
                      const TextStyle(
                    color:
                        Colors.black54,
                  ),
                  prefixIcon:
                      const Icon(
                    Icons
                        .email_outlined,
                    color:
                        Colors.black87,
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Colors.white,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color: Color(
                        0xFFFFE1D1,
                      ),
                      width: 2,
                    ),
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
                textInputAction:
                    TextInputAction.done,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration:
                    InputDecoration(
                  filled: true,
                  fillColor:
                      Colors.white,
                  hintText: 'Senha',
                  hintStyle:
                      const TextStyle(
                    color:
                        Colors.black54,
                  ),
                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline,
                    color:
                        Colors.black87,
                  ),
                  suffixIcon:
                      IconButton(
                    icon: Icon(
                      mostrarSenha
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,
                      color:
                          Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        mostrarSenha =
                            !mostrarSenha;
                      });
                    },
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          Colors.white,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                    borderSide:
                        const BorderSide(
                      color: Color(
                        0xFFFFE1D1,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // SALVAR SENHA
              // ==================================================

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Theme(
                  data:
                      Theme.of(context)
                          .copyWith(
                    checkboxTheme:
                        CheckboxThemeData(
                      fillColor:
                          WidgetStateProperty
                              .resolveWith(
                        (states) {
                          if (states.contains(
                            WidgetState
                                .selected,
                          )) {
                            return Colors
                                .black;
                          }

                          return Colors
                              .white;
                        },
                      ),
                      checkColor:
                          WidgetStateProperty
                              .all(
                        Colors.white,
                      ),
                      side:
                          const BorderSide(
                        color:
                            Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Checkbox(
                        value:
                            salvarSenha,
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
                      const Text(
                        'Salvar senha',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    style:
                        TextStyle(
                      color:
                          Colors.white,
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
                          BorderRadius
                              .circular(
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
                                    3,
                              ),
                            )
                          : const Text(
                              'ENTRAR',
                              style:
                                  TextStyle(
                                fontSize:
                                    18,
                                fontWeight:
                                    FontWeight
                                        .bold,
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
                          BorderRadius
                              .circular(
                        15,
                      ),
                    ),
                  ),
                  child: const Text(
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

