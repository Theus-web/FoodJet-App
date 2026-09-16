
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../register/register_screen.dart';
import 'forgot_password_screen.dart';

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

  bool carregando = false;
  bool mostrarSenha = false;
  bool salvarSenha = false;

  static const String chaveSalvarSenha =
      'foodjet_entregador_salvar_senha';

  static const String chaveEmailSalvo =
      'foodjet_entregador_email_salvo';

  static const String chaveSenhaSalva =
      'foodjet_entregador_senha_salva';

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

  // ============================================================
  // CARREGAR LOGIN SALVO
  // ============================================================

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
    } catch (e) {
      debugPrint(
        'ERRO AO CARREGAR LOGIN SALVO: $e',
      );
    }
  }

  // ============================================================
  // SALVAR OU REMOVER LOGIN
  // ============================================================

  Future<void> _salvarOuRemoverLogin() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      if (salvarSenha) {
        final email =
            emailController.text.trim().toLowerCase();

        final senha =
            senhaController.text;

        await prefs.setBool(
          chaveSalvarSenha,
          true,
        );

        await prefs.setString(
          chaveEmailSalvo,
          email,
        );

        await prefs.setString(
          chaveSenhaSalva,
          senha,
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
      }
    } catch (e) {
      debugPrint(
        'ERRO AO SALVAR LOGIN: $e',
      );
    }
  }

  // ============================================================
  // SALVAR SESSÃO
  // ============================================================

  Future<void> _salvarSessao(
    Map<String, dynamic> resultado,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final usuario =
          resultado['usuario'];

      if (usuario is Map) {
        await prefs.setString(
          'usuario',
          jsonEncode(
            Map<String, dynamic>.from(usuario),
          ),
        );

        await prefs.setBool(
          'logado',
          true,
        );
      }

      final token =
          resultado['token'] ??
          resultado['jwt'] ??
          resultado['access_token'] ??
          resultado['accessToken'] ??
          resultado['auth_token'];

      if (token != null &&
          token.toString().trim().isNotEmpty) {
        final tokenString =
            token.toString().trim();

        await prefs.setString(
          'token',
          tokenString,
        );

        await prefs.setString(
          'jwt',
          tokenString,
        );

        await prefs.setString(
          'access_token',
          tokenString,
        );

        await prefs.setString(
          'auth_token',
          tokenString,
        );
      }
    } catch (e) {
      debugPrint(
        'ERRO AO SALVAR SESSÃO: $e',
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

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
      // ========================================================
      // CORREÇÃO:
      // AuthService.login() é STATIC e usa parâmetros NOMEADOS.
      // ========================================================

      final resultado =
          await AuthService.login(
        email: email,
        senha: senha,
      );

      debugPrint(
        'RESULTADO LOGIN ENTREGADOR: $resultado',
      );

      if (!mounted) return;

      // ========================================================
      // VERIFICAR SE O LOGIN FOI ACEITO
      // ========================================================

      if (resultado['usuario'] != null) {
        final usuario =
            Map<String, dynamic>.from(
          resultado['usuario'],
        );

        // ======================================================
        // VERIFICAR TIPO DE USUÁRIO
        // ======================================================

        final tipo =
            usuario['tipo']
                ?.toString()
                .trim()
                .toLowerCase();

        if (tipo != null &&
            tipo.isNotEmpty &&
            tipo != 'entregador') {
          _mensagem(
            'Esta conta não é de entregador.',
            erro: true,
          );
          return;
        }

        // ======================================================
        // SALVAR SESSÃO
        // ======================================================

        await _salvarSessao(
          Map<String, dynamic>.from(
            resultado,
          ),
        );

        // ======================================================
        // SALVAR LOGIN
        // ======================================================

        await _salvarOuRemoverLogin();

        if (!mounted) return;

        // ======================================================
        // IR PARA HOME
        //
        // O HomeScreen atual não possui parâmetro "usuario".
        // O usuário já foi salvo no SharedPreferences.
        // ======================================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const HomeScreen(),
          ),
        );
      } else {
        final mensagem =
            resultado['erro']
                ?.toString() ??
            resultado['mensagem']
                ?.toString() ??
            'E-mail ou senha incorretos.';

        _mensagem(
          mensagem,
          erro: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'ERRO LOGIN ENTREGADOR: $e',
      );

      _mensagem(
        'Não foi possível conectar ao servidor.',
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

  // ============================================================
  // ESQUECI MINHA SENHA
  // ============================================================

  void esqueciSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ForgotPasswordScreen(),
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

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
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // DECORAÇÃO DOS CAMPOS
  // ============================================================

  InputDecoration _decoracaoCampo({
    required String hint,
    required IconData icone,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor:
          const Color(0xFF171717),
      hintText: hint,
      hintStyle:
          const TextStyle(
        color: Colors.white54,
        fontSize: 16,
      ),
      prefixIcon:
          Icon(
        icone,
        color: Colors.white70,
      ),
      suffixIcon:
          suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: Color(0xFF333333),
          width: 1.2,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: laranja,
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // TELA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Column(
            children: [
              const SizedBox(height: 45),

              // ==================================================
              // LOGO
              // ==================================================

              Container(
                width: 120,
                height: 120,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF171717),
                  borderRadius:
                      BorderRadius.circular(28),
                  border:
                      Border.all(
                    color:
                        const Color(0xFF333333),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          laranja.withValues(
                        alpha: 0.20,
                      ),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child:
                    const Center(
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
                      SizedBox(height: 2),
                      Text(
                        'FoodJet',
                        style:
                            TextStyle(
                          color:
                              laranja,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing:
                              0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'FoodJet',
                style:
                    TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'ENTREGADOR',
                style:
                    TextStyle(
                  color: laranja,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 2.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Faça suas entregas com a FoodJet 🚀',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 48),

              // ==================================================
              // E-MAIL
              // ==================================================

              TextField(
                controller:
                    emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration:
                    _decoracaoCampo(
                  hint: 'E-mail',
                  icone:
                      Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 18),

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
                onSubmitted: (_) {
                  if (!carregando) {
                    entrar();
                  }
                },
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration:
                    _decoracaoCampo(
                  hint: 'Senha',
                  icone:
                      Icons.lock_outline,
                  suffixIcon:
                      IconButton(
                    icon:
                        Icon(
                      mostrarSenha
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color:
                          Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        mostrarSenha =
                            !mostrarSenha;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // SALVAR SENHA
              // ==================================================

              Align(
                alignment:
                    Alignment.centerLeft,
                child:
                    Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Checkbox(
                      value:
                          salvarSenha,
                      activeColor:
                          laranja,
                      checkColor:
                          Colors.white,
                      side:
                          const BorderSide(
                        color:
                            Colors.white54,
                        width: 1.5,
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

                                  if (!(valor ??
                                      false)) {
                                    SharedPreferences
                                        .getInstance()
                                        .then(
                                      (prefs) async {
                                        await prefs
                                            .remove(
                                          chaveSalvarSenha,
                                        );
                                        await prefs
                                            .remove(
                                          chaveEmailSalvo,
                                        );
                                        await prefs
                                            .remove(
                                          chaveSenhaSalva,
                                        );
                                      },
                                    );
                                  }
                                },
                    ),
                    const Text(
                      'Salvar senha',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ESQUECI SENHA
              // ==================================================

              Align(
                alignment:
                    Alignment.centerRight,
                child:
                    TextButton(
                  onPressed:
                      carregando
                          ? null
                          : esqueciSenha,
                  child:
                      const Text(
                    'Esqueci minha senha',
                    style:
                        TextStyle(
                      color: laranja,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

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
                        laranja,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        laranja.withValues(
                      alpha: 0.55,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    elevation: 4,
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
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // DIVISOR
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color:
                          Color(0xFF333333),
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
                            Colors.white38,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color:
                          Color(0xFF333333),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ==================================================
              // CRIAR CONTA
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 52,
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
                      color: laranja,
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
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // TERMOS
              // ==================================================

              const Text(
                'Ao continuar, você concorda com os '
                'termos de uso e política de privacidade '
                'do FoodJet.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Colors.white38,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

