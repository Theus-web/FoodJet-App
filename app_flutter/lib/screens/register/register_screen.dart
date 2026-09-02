
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController =
      TextEditingController();

  final TextEditingController _cpfController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _telefoneController =
      TextEditingController();

  final TextEditingController _senhaController =
      TextEditingController();

  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;

  // ============================================================
  // SOMENTE NÚMEROS
  // ============================================================

  String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  // ============================================================
  // CPF
  // ============================================================

  String _formatarCpf(String valor) {
    final cpf = _somenteNumeros(valor);

    if (cpf.length <= 3) {
      return cpf;
    }

    if (cpf.length <= 6) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3)}';
    }

    if (cpf.length <= 9) {
      return '${cpf.substring(0, 3)}.'
          '${cpf.substring(3, 6)}.'
          '${cpf.substring(6)}';
    }

    return '${cpf.substring(0, 3)}.'
        '${cpf.substring(3, 6)}.'
        '${cpf.substring(6, 9)}-'
        '${cpf.substring(9, cpf.length > 11 ? 11 : cpf.length)}';
  }

  // ============================================================
  // TELEFONE
  // ============================================================

  String _formatarTelefone(String valor) {
    final telefone = _somenteNumeros(valor);

    if (telefone.length <= 2) {
      return telefone;
    }

    if (telefone.length <= 7) {
      return '(${telefone.substring(0, 2)}) '
          '${telefone.substring(2)}';
    }

    if (telefone.length <= 10) {
      return '(${telefone.substring(0, 2)}) '
          '${telefone.substring(2, 6)}-'
          '${telefone.substring(6)}';
    }

    return '(${telefone.substring(0, 2)}) '
        '${telefone.substring(2, 7)}-'
        '${telefone.substring(7, telefone.length > 11 ? 11 : telefone.length)}';
  }

  // ============================================================
  // CADASTRAR
  // ============================================================

  Future<void> cadastrar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final url = Uri.parse(
        'http://192.168.1.101:3000/api/auth/register',
      );

      final cpf = _somenteNumeros(
        _cpfController.text,
      );

      final telefone = _somenteNumeros(
        _telefoneController.text,
      );

      final resposta = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'nome': _nomeController.text.trim(),
              'cpf': cpf,
              'email': _emailController.text.trim().toLowerCase(),
              'telefone': telefone,
              'senha': _senhaController.text,
              'tipo': 'CLIENTE',
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      Map<String, dynamic> resultado = {};

      try {
        final dados = jsonDecode(resposta.body);

        if (dados is Map<String, dynamic>) {
          resultado = dados;
        }
      } catch (_) {
        resultado = {};
      }

      if (!mounted) return;

      if (resposta.statusCode == 201 ||
          resposta.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta criada com sucesso!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(
          const Duration(milliseconds: 800),
        );

        if (!mounted) return;

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['erro']?.toString() ??
                  'Não foi possível criar sua conta.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível conectar ao servidor. '
            'Verifique se o FoodJet Backend está funcionando.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  // ============================================================
  // DECORAÇÃO
  // ============================================================

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white70,
      ),
      prefixIcon: Icon(
        icone,
        color: Colors.orange,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF252525),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.white12,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.orange,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Criar conta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              30,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // ==================================================
                  // ÍCONE
                  // ==================================================

                  Center(
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        size: 45,
                        color: Colors.orange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Crie sua conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Cadastre-se para começar a pedir\n'
                    'seus pratos favoritos pelo FoodJet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // NOME
                  // ==================================================

                  TextFormField(
                    controller: _nomeController,
                    keyboardType: TextInputType.name,
                    textCapitalization:
                        TextCapitalization.words,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _decoracaoCampo(
                      label: 'Nome completo',
                      icone: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Digite seu nome';
                      }

                      if (value.trim().length < 3) {
                        return 'Digite seu nome completo';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // CPF
                  // ==================================================

                  TextFormField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) {
                          final numeros =
                              newValue.text.replaceAll(
                            RegExp(r'\D'),
                            '',
                          );

                          final formatado =
                              _formatarCpf(numeros);

                          return TextEditingValue(
                            text: formatado,
                            selection:
                                TextSelection.collapsed(
                              offset: formatado.length,
                            ),
                          );
                        },
                      ),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _decoracaoCampo(
                      label: 'CPF',
                      icone: Icons.badge_outlined,
                    ),
                    validator: (value) {
                      final cpf = _somenteNumeros(
                        value ?? '',
                      );

                      if (cpf.isEmpty) {
                        return 'Digite seu CPF';
                      }

                      if (cpf.length != 11) {
                        return 'Digite um CPF válido';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // TELEFONE
                  // ==================================================

                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) {
                          final numeros =
                              _somenteNumeros(
                            newValue.text,
                          );

                          if (numeros.length > 11) {
                            return oldValue;
                          }

                          final formatado =
                              _formatarTelefone(
                            numeros,
                          );

                          return TextEditingValue(
                            text: formatado,
                            selection:
                                TextSelection.collapsed(
                              offset: formatado.length,
                            ),
                          );
                        },
                      ),
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _decoracaoCampo(
                      label: 'Telefone',
                      icone: Icons.phone_outlined,
                    ),
                    validator: (value) {
                      final telefone =
                          _somenteNumeros(
                        value ?? '',
                      );

                      if (telefone.isEmpty) {
                        return 'Digite seu telefone';
                      }

                      if (telefone.length != 10 &&
                          telefone.length != 11) {
                        return 'Digite um telefone válido';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _decoracaoCampo(
                      label: 'E-mail',
                      icone: Icons.email_outlined,
                    ),
                    validator: (value) {
                      final email =
                          value?.trim() ?? '';

                      if (email.isEmpty) {
                        return 'Digite seu e-mail';
                      }

                      final emailValido = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email);

                      if (!emailValido) {
                        return 'Digite um e-mail válido';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // SENHA
                  // ==================================================

                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_mostrarSenha,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _decoracaoCampo(
                      label: 'Senha',
                      icone: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _mostrarSenha =
                                !_mostrarSenha;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Digite sua senha';
                      }

                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // CONFIRMAR SENHA
                  // ==================================================

                  TextFormField(
                    controller:
                        _confirmarSenhaController,
                    obscureText:
                        !_mostrarConfirmarSenha,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _decoracaoCampo(
                      label: 'Confirmar senha',
                      icone: Icons.lock_reset_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarConfirmarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _mostrarConfirmarSenha =
                                !_mostrarConfirmarSenha;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Confirme sua senha';
                      }

                      if (value !=
                          _senhaController.text) {
                        return 'As senhas não coincidem';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // BOTÃO
                  // ==================================================

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _carregando
                              ? null
                              : cadastrar,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.orange,
                        disabledBackgroundColor:
                            Colors.orange
                                .withOpacity(0.5),
                        elevation: 3,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: _carregando
                          ? const SizedBox(
                              height: 25,
                              width: 25,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'CRIAR MINHA CONTA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // LOGIN
                  // ==================================================

                  TextButton(
                    onPressed: _carregando
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text(
                      'Já tenho uma conta. Entrar',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Ao criar sua conta, você poderá fazer '
                    'pedidos e acompanhar suas entregas pelo FoodJet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

