
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // DADOS DO RESTAURANTE
  // ============================================================

  final _restaurantController = TextEditingController();
  final _ownerController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // ============================================================
  // ENDEREÇO
  // ============================================================

  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // ============================================================
  // SENHA
  // ============================================================

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _loading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _restaurantController.dispose();
    _ownerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();

    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // DECORAÇÃO DOS CAMPOS
  // ============================================================

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ============================================================
  // CADASTRO
  // ============================================================

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Aceite os Termos de Uso.",
          ),
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final authService = AuthService();

      final resposta = await authService.register(
        _restaurantController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
        tipo: "RESTAURANTE",
        restaurante: {
          "nome": _restaurantController.text.trim(),

          "categoria": "Restaurante",

          "responsavel":
              _ownerController.text.trim(),

          "endereco": {
            "cep": _cepController.text.trim(),
            "rua": _streetController.text.trim(),
            "numero": _numberController.text.trim(),
            "complemento":
                _complementController.text.trim(),
            "bairro":
                _neighborhoodController.text.trim(),
            "cidade":
                _cityController.text.trim(),
            "estado":
                _stateController.text.trim().toUpperCase(),
          },

          "pagamento": {
            "banco": "",
            "agencia": "",
            "conta": "",
            "pix": "",
          },
        },
      );

      if (!mounted) {
        return;
      }

      if (resposta == null) {
        throw Exception(
          "Não foi possível realizar o cadastro.",
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Restaurante cadastrado com sucesso!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      String mensagem = e.toString();

      if (mensagem.startsWith("Exception: ")) {
        mensagem = mensagem.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Criar Conta",
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              children: [

                // ==================================================
                // LOGO
                // ==================================================

                const SizedBox(height: 20),

                const Icon(
                  Icons.restaurant,
                  size: 90,
                  color: Color(0xFFF97316),
                ),

                const SizedBox(height: 15),

                const Text(
                  "FoodJet Restaurante",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Cadastre seu restaurante",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // DADOS DO RESTAURANTE
                // ==================================================

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Dados do restaurante",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _restaurantController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: _decoration(
                    "Nome do Restaurante",
                    Icons.store,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Informe o nome.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _ownerController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: _decoration(
                    "Responsável",
                    Icons.person,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Informe o responsável.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration: _decoration(
                    "E-mail",
                    Icons.email,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        !value.contains("@")) {
                      return "E-mail inválido.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration: _decoration(
                    "Telefone",
                    Icons.phone,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Informe o telefone.";
                    }

                    return null;
                  },
                ),

                // ==================================================
                // ENDEREÇO
                // ==================================================

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Endereço do restaurante",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Esse será o endereço onde o entregador irá retirar os pedidos.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CEP
                // ==================================================

                TextFormField(
                  controller: _cepController,
                  keyboardType:
                      TextInputType.number,
                  textInputAction:
                      TextInputAction.next,
                  decoration: _decoration(
                    "CEP",
                    Icons.location_on,
                  ),
                  validator: (value) {
                    final cep =
                        value?.trim() ?? "";

                    if (cep.isEmpty) {
                      return "Informe o CEP.";
                    }

                    if (cep.length < 8) {
                      return "CEP inválido.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // RUA
                // ==================================================

                TextFormField(
                  controller: _streetController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: _decoration(
                    "Rua / Avenida",
                    Icons.signpost,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Informe a rua.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // NÚMERO
                // ==================================================

                TextFormField(
                  controller: _numberController,
                  keyboardType:
                      TextInputType.number,
                  decoration: _decoration(
                    "Número",
                    Icons.pin,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Informe o número.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // COMPLEMENTO
                // ==================================================

                TextFormField(
                  controller: _complementController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: _decoration(
                    "Complemento (opcional)",
                    Icons.apartment,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // BAIRRO
                // ==================================================

                TextFormField(
                  controller: _neighborhoodController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: _decoration(
                    "Bairro",
                    Icons.location_city,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Informe o bairro.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CIDADE
                // ==================================================

                TextFormField(
                  controller: _cityController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: _decoration(
                    "Cidade",
                    Icons.location_city,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Informe a cidade.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // ESTADO
                // ==================================================

                TextFormField(
                  controller: _stateController,
                  textCapitalization:
                      TextCapitalization.characters,
                  maxLength: 2,
                  decoration: _decoration(
                    "Estado (UF)",
                    Icons.map,
                  ),
                  validator: (value) {
                    final estado =
                        value?.trim() ?? "";

                    if (estado.isEmpty) {
                      return "Informe o estado.";
                    }

                    if (estado.length != 2) {
                      return "Informe a UF. Ex.: MG";
                    }

                    return null;
                  },
                ),

                // ==================================================
                // SENHA
                // ==================================================

                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Acesso",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _decoration(
                    "Senha",
                    Icons.lock,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.length < 6) {
                      return "A senha deve ter pelo menos 6 caracteres.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller:
                      _confirmPasswordController,
                  obscureText:
                      _obscureConfirmPassword,
                  decoration: _decoration(
                    "Confirmar Senha",
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value !=
                        _passwordController.text) {
                      return "As senhas não conferem.";
                    }

                    return null;
                  },
                ),

                // ==================================================
                // TERMOS
                // ==================================================

                const SizedBox(height: 20),

                CheckboxListTile(
                  value: _acceptTerms,
                  controlAffinity:
                      ListTileControlAffinity.leading,
                  activeColor:
                      const Color(0xFFF97316),
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    "Aceito os Termos de Uso e Política de Privacidade",
                  ),
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms =
                          value ?? false;
                    });
                  },
                ),

                // ==================================================
                // BOTÃO
                // ==================================================

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : _register,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF97316),
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "CRIAR CONTA",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // ==================================================
                // LOGIN
                // ==================================================

                const SizedBox(height: 30),

                const Divider(),

                const SizedBox(height: 15),

                const Text(
                  "Já possui uma conta?",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    "ENTRAR",
                    style: TextStyle(
                      color: Color(0xFFF97316),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

