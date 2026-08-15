
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ============================================================
  // CORES
  // ============================================================

  static const Color primaryColor = Color(0xFFF97316);
  static const Color backgroundColor = Color(0xFFF7F7F8);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final nomeController = TextEditingController();
  final cnpjController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();

  final responsavelController = TextEditingController();
  final cpfController = TextEditingController();

  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final cepController = TextEditingController();
  final ruaController = TextEditingController();
  final numeroController = TextEditingController();
  final complementoController = TextEditingController();
  final bairroController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();

  final bancoController = TextEditingController();
  final agenciaController = TextEditingController();
  final contaController = TextEditingController();
  final pixController = TextEditingController();

  final AuthService authService = AuthService();

  // ============================================================
  // ESTADO
  // ============================================================

  int etapaAtual = 0;

  bool carregando = false;
  bool buscandoCep = false;
  bool mostrarSenha = false;
  bool mostrarConfirmarSenha = false;

  String categoriaSelecionada = 'Restaurante';

  bool aceitaTermos = false;

  // Evita várias consultas para o mesmo CEP.
  String ultimoCepConsultado = '';

  // ============================================================
  // CATEGORIAS
  // ============================================================

  final List<String> categorias = [
    'Restaurante',
    'Lanchonete',
    'Pizzaria',
    'Hamburgueria',
    'Açaíteria',
    'Doceria',
    'Padaria',
    'Comida japonesa',
    'Comida brasileira',
    'Outro',
  ];

  // ============================================================
  // ETAPAS
  // ============================================================

  final List<String> nomesEtapas = [
    'Restaurante',
    'Responsável',
    'Endereço',
    'Pagamento',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    cepController.addListener(_monitorarCep);
  }

  // ============================================================
  // MONITORAR CEP
  // ============================================================

  void _monitorarCep() {
    final cep = cepController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cep.length == 8 &&
        cep != ultimoCepConsultado &&
        !buscandoCep) {
      buscarCep();
    }

    if (cep.length < 8) {
      ultimoCepConsultado = '';
    }
  }

  // ============================================================
  // BUSCAR CEP
  // ============================================================

  Future<void> buscarCep() async {
    final cep = cepController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cep.length != 8) {
      mostrarMensagem(
        'Digite um CEP válido com 8 números.',
      );
      return;
    }

    if (buscandoCep) {
      return;
    }

    setState(() {
      buscandoCep = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://viacep.com.br/ws/$cep/json/',
        ),
      );

      if (response.statusCode != 200) {
        mostrarMensagem(
          'Não foi possível consultar o CEP.',
        );
        return;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        mostrarMensagem(
          'Resposta inválida da consulta de CEP.',
        );
        return;
      }

      if (data['erro'] == true) {
        ultimoCepConsultado = '';

        mostrarMensagem(
          'CEP não encontrado.',
        );
        return;
      }

      ultimoCepConsultado = cep;

      ruaController.text =
          data['logradouro']?.toString() ?? '';

      bairroController.text =
          data['bairro']?.toString() ?? '';

      cidadeController.text =
          data['localidade']?.toString() ?? '';

      estadoController.text =
          data['uf']?.toString() ?? '';

      if (!mounted) return;

      mostrarMensagem(
        'Endereço preenchido automaticamente.',
      );
    } catch (e) {
      ultimoCepConsultado = '';

      if (!mounted) return;

      mostrarMensagem(
        'Erro ao consultar o CEP. Verifique sua conexão.',
      );
    } finally {
      if (mounted) {
        setState(() {
          buscandoCep = false;
        });
      }
    }
  }

  // ============================================================
  // CADASTRO
  // ============================================================

  
Future<void> cadastrar() async {
  if (!validarEtapaFinal()) {
    return;
  }

  if (!aceitaTermos) {
    mostrarMensagem(
      'Aceite os termos para continuar.',
    );
    return;
  }

  setState(() {
    carregando = true;
  });

  try {
    // ==========================================================
    // CADASTRO DO RESTAURANTE / AÇAÍTERIA
    // ==========================================================

    final resultado = await authService.register(
      // Nome do responsável
      responsavelController.text.trim(),

      // Email comercial
      emailController.text.trim(),

      // Senha
      senhaController.text.trim(),

      // Telefone
      telefoneController.text.trim(),

      // ========================================================
      // TIPO CORRETO
      // ========================================================

      tipo: "RESTAURANTE",

      // CPF do responsável
      cpf: cpfController.text.trim(),

      // ========================================================
      // DADOS COMPLETOS DO RESTAURANTE
      // ========================================================

      restaurante: {
        "nome": nomeController.text.trim(),

        "cnpj": cnpjController.text.trim(),

        "categoria": categoriaSelecionada,

        "email": emailController.text.trim(),

        "telefone": telefoneController.text.trim(),

        "responsavel":
            responsavelController.text.trim(),

        "cpf":
            cpfController.text.trim(),

        // ======================================================
        // ENDEREÇO
        // ======================================================

        "endereco": {
          "cep":
              cepController.text.trim(),

          "rua":
              ruaController.text.trim(),

          "numero":
              numeroController.text.trim(),

          "complemento":
              complementoController.text.trim(),

          "bairro":
              bairroController.text.trim(),

          "cidade":
              cidadeController.text.trim(),

          "estado":
              estadoController.text.trim(),
        },

        // ======================================================
        // PAGAMENTO
        // ======================================================

        "pagamento": {
          "banco":
              bancoController.text.trim(),

          "agencia":
              agenciaController.text.trim(),

          "conta":
              contaController.text.trim(),

          "pix":
              pixController.text.trim(),
        },

        // ======================================================
        // STATUS INICIAL
        // ======================================================

        "status": "FECHADO",

        "online": false,

        "aberto": false,
      },
    );

    if (!mounted) return;

    if (resultado != null) {
      mostrarMensagem(
        'Açaíteria criada com sucesso!',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } else {
      mostrarMensagem(
        'Não foi possível criar a açaíteria.',
      );
    }
  } catch (e) {
    if (!mounted) return;

    mostrarMensagem(
      'Erro no cadastro: '
      '${e.toString().replaceAll('Exception:', '').trim()}',
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
  // VALIDAÇÃO
  // ============================================================

  bool validarEtapaFinal() {
    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        telefoneController.text.trim().isEmpty ||
        cnpjController.text.trim().isEmpty) {
      mostrarMensagem(
        'Preencha os dados principais do restaurante.',
      );

      setState(() {
        etapaAtual = 0;
      });

      return false;
    }

    if (responsavelController.text.trim().isEmpty ||
        cpfController.text.trim().isEmpty ||
        senhaController.text.trim().isEmpty ||
        confirmarSenhaController.text.trim().isEmpty) {
      mostrarMensagem(
        'Preencha os dados do responsável.',
      );

      setState(() {
        etapaAtual = 1;
      });

      return false;
    }

    if (senhaController.text !=
        confirmarSenhaController.text) {
      mostrarMensagem(
        'As senhas não coincidem.',
      );

      setState(() {
        etapaAtual = 1;
      });

      return false;
    }

    if (senhaController.text.length < 8) {
      mostrarMensagem(
        'A senha deve ter pelo menos 8 caracteres.',
      );

      setState(() {
        etapaAtual = 1;
      });

      return false;
    }

    if (cepController.text
            .replaceAll(RegExp(r'[^0-9]'), '')
            .length !=
        8) {
      mostrarMensagem(
        'Digite um CEP válido.',
      );

      setState(() {
        etapaAtual = 2;
      });

      return false;
    }

    if (ruaController.text.trim().isEmpty ||
        numeroController.text.trim().isEmpty ||
        bairroController.text.trim().isEmpty ||
        cidadeController.text.trim().isEmpty ||
        estadoController.text.trim().isEmpty) {
      mostrarMensagem(
        'Preencha o endereço completo.',
      );

      setState(() {
        etapaAtual = 2;
      });

      return false;
    }

    if (bancoController.text.trim().isEmpty ||
        agenciaController.text.trim().isEmpty ||
        contaController.text.trim().isEmpty ||
        pixController.text.trim().isEmpty) {
      mostrarMensagem(
        'Preencha os dados de recebimento.',
      );

      setState(() {
        etapaAtual = 3;
      });

      return false;
    }

    return true;
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // PRÓXIMA ETAPA
  // ============================================================

  void proximaEtapa() {
    if (etapaAtual == 0) {
      if (nomeController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          telefoneController.text.trim().isEmpty ||
          cnpjController.text.trim().isEmpty) {
        mostrarMensagem(
          'Preencha todos os dados do restaurante.',
        );
        return;
      }
    }

    if (etapaAtual == 1) {
      if (responsavelController.text.trim().isEmpty ||
          cpfController.text.trim().isEmpty ||
          senhaController.text.trim().isEmpty ||
          confirmarSenhaController.text.trim().isEmpty) {
        mostrarMensagem(
          'Preencha todos os dados do responsável.',
        );
        return;
      }

      if (senhaController.text.length < 8) {
        mostrarMensagem(
          'A senha deve ter pelo menos 8 caracteres.',
        );
        return;
      }

      if (senhaController.text !=
          confirmarSenhaController.text) {
        mostrarMensagem(
          'As senhas não coincidem.',
        );
        return;
      }
    }

    if (etapaAtual == 2) {
      final cep = cepController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (cep.length != 8 ||
          ruaController.text.trim().isEmpty ||
          numeroController.text.trim().isEmpty ||
          bairroController.text.trim().isEmpty ||
          cidadeController.text.trim().isEmpty ||
          estadoController.text.trim().isEmpty) {
        mostrarMensagem(
          'Preencha o endereço completo.',
        );
        return;
      }
    }

    if (etapaAtual < nomesEtapas.length - 1) {
      setState(() {
        etapaAtual++;
      });
    }
  }

  // ============================================================
  // VOLTAR
  // ============================================================

  void voltarEtapa() {
    if (etapaAtual > 0) {
      setState(() {
        etapaAtual--;
      });
    }
  }

  // ============================================================
  // CAMPO
  // ============================================================

  Widget campo(
    String titulo,
    IconData icone,
    TextEditingController controller, {
    TextInputType? teclado,
    String? hint,
    bool obrigatorio = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: titulo,
        hintText: hint,
        prefixIcon: Icon(
          icone,
          color: primaryColor,
        ),
        suffixIcon: !obrigatorio
            ? const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.remove,
                  color: Colors.transparent,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F8F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SENHA
  // ============================================================

  Widget campoSenha({
    required String titulo,
    required TextEditingController controller,
    required bool mostrar,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !mostrar,
      decoration: InputDecoration(
        labelText: titulo,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: primaryColor,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            mostrar
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: primaryColor,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIA
  // ============================================================

  Widget categoriaCampo() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: categoriaSelecionada,
        decoration: const InputDecoration(
          labelText: 'Categoria do estabelecimento',
          prefixIcon: Icon(
            Icons.category_outlined,
            color: primaryColor,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        items: categorias.map((categoria) {
          return DropdownMenuItem(
            value: categoria,
            child: Text(categoria),
          );
        }).toList(),
        onChanged: (valor) {
          if (valor == null) return;

          setState(() {
            categoriaSelecionada = valor;
          });
        },
      ),
    );
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget cabecalho() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF8A3D),
                Color(0xFFF97316),
              ],
            ),
            borderRadius: BorderRadius.circular(23),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: .25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Cadastre seu restaurante',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'Faça parte do FoodJet e comece a receber pedidos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // INDICADOR
  // ============================================================

  Widget indicadorEtapas() {
    return Row(
      children: List.generate(
        nomesEtapas.length,
        (index) {
          final concluida = index <= etapaAtual;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: concluida
                        ? primaryColor
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: concluida
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                if (index < nomesEtapas.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: index < etapaAtual
                            ? primaryColor
                            : Colors.grey.shade200,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TÍTULO ETAPA
  // ============================================================

  Widget tituloEtapa(
    String titulo,
    String descricao,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          descricao,
          style: const TextStyle(
            color: Colors.black54,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // ETAPA RESTAURANTE
  // ============================================================

  Widget etapaRestaurante() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tituloEtapa(
          'Dados do restaurante',
          'Informe os dados básicos do seu estabelecimento.',
        ),

        campo(
          'Nome do restaurante',
          Icons.storefront_rounded,
          nomeController,
          hint: 'Ex.: Pizzaria do João',
        ),

        const SizedBox(height: 14),

        campo(
          'CNPJ',
          Icons.badge_outlined,
          cnpjController,
          teclado: TextInputType.number,
          hint: '00.000.000/0001-00',
        ),

        const SizedBox(height: 14),

        campo(
          'Email comercial',
          Icons.email_outlined,
          emailController,
          teclado: TextInputType.emailAddress,
          hint: 'contato@seurestaurante.com',
        ),

        const SizedBox(height: 14),

        campo(
          'Telefone / WhatsApp',
          Icons.phone_rounded,
          telefoneController,
          teclado: TextInputType.phone,
          hint: '(31) 99999-9999',
        ),

        const SizedBox(height: 14),

        categoriaCampo(),
      ],
    );
  }

  // ============================================================
  // ETAPA RESPONSÁVEL
  // ============================================================

  Widget etapaResponsavel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tituloEtapa(
          'Responsável e acesso',
          'Esses dados serão usados para administrar o restaurante.',
        ),

        campo(
          'Nome do responsável',
          Icons.person_outline_rounded,
          responsavelController,
          hint: 'Nome completo',
        ),

        const SizedBox(height: 14),

        campo(
          'CPF do responsável',
          Icons.assignment_ind_outlined,
          cpfController,
          teclado: TextInputType.number,
          hint: '000.000.000-00',
        ),

        const SizedBox(height: 14),

        campoSenha(
          titulo: 'Senha',
          controller: senhaController,
          mostrar: mostrarSenha,
          onToggle: () {
            setState(() {
              mostrarSenha = !mostrarSenha;
            });
          },
        ),

        const SizedBox(height: 14),

        campoSenha(
          titulo: 'Confirmar senha',
          controller: confirmarSenhaController,
          mostrar: mostrarConfirmarSenha,
          onToggle: () {
            setState(() {
              mostrarConfirmarSenha =
                  !mostrarConfirmarSenha;
            });
          },
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.security_rounded,
                color: primaryColor,
                size: 21,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use uma senha forte com pelo menos 8 caracteres.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ETAPA ENDEREÇO
  // ============================================================

  Widget etapaEndereco() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tituloEtapa(
          'Endereço do restaurante',
          'Digite o CEP e o endereço será preenchido automaticamente.',
        ),

        // --------------------------------------------------------
        // CEP
        // --------------------------------------------------------

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: campo(
                'CEP',
                Icons.location_on_outlined,
                cepController,
                teclado: TextInputType.number,
                hint: '00000-000',
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              width: 56,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    buscandoCep ? null : buscarCep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      primaryColor.withValues(alpha: .55),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: buscandoCep
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.search_rounded,
                      ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: primaryColor,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Ao digitar os 8 números, o endereço será buscado automaticamente.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // --------------------------------------------------------
        // RUA
        // --------------------------------------------------------

        campo(
          'Rua / Avenida',
          Icons.location_on_outlined,
          ruaController,
          hint: 'Preenchido automaticamente',
        ),

        const SizedBox(height: 14),

        // --------------------------------------------------------
        // NÚMERO / COMPLEMENTO
        // --------------------------------------------------------

        Row(
          children: [
            Expanded(
              child: campo(
                'Número',
                Icons.numbers_rounded,
                numeroController,
                teclado: TextInputType.number,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: campo(
                'Complemento',
                Icons.add_location_alt_outlined,
                complementoController,
                obrigatorio: false,
                hint: 'Sala, loja...',
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // --------------------------------------------------------
        // BAIRRO
        // --------------------------------------------------------

        campo(
          'Bairro',
          Icons.map_outlined,
          bairroController,
          hint: 'Preenchido automaticamente',
        ),

        const SizedBox(height: 14),

        // --------------------------------------------------------
        // CIDADE / UF
        // --------------------------------------------------------

        Row(
          children: [
            Expanded(
              flex: 3,
              child: campo(
                'Cidade',
                Icons.location_city_outlined,
                cidadeController,
                hint: 'Preenchido automaticamente',
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: campo(
                'UF',
                Icons.flag_outlined,
                estadoController,
                hint: 'MG',
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // --------------------------------------------------------
        // INFORMAÇÃO
        // --------------------------------------------------------

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: .12),
                primaryColor.withValues(alpha: .05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: primaryColor.withValues(alpha: .15),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.location_searching_rounded,
                color: primaryColor,
                size: 28,
              ),

              SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Localização do estabelecimento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'A localização será usada para calcular as entregas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ETAPA PAGAMENTO
  // ============================================================

  Widget etapaPagamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tituloEtapa(
          'Dados de recebimento',
          'Informe onde o restaurante deseja receber os valores.',
        ),

        campo(
          'Banco',
          Icons.account_balance_outlined,
          bancoController,
          hint: 'Ex.: Banco do Brasil',
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: campo(
                'Agência',
                Icons.account_balance_rounded,
                agenciaController,
                teclado: TextInputType.number,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: campo(
                'Conta',
                Icons.credit_card_rounded,
                contaController,
                teclado: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        campo(
          'Chave PIX',
          Icons.pix_rounded,
          pixController,
          hint: 'CPF, CNPJ, email ou chave aleatória',
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.green,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seus dados bancários serão utilizados exclusivamente para os recebimentos do restaurante.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: aceitaTermos,
                activeColor: primaryColor,
                onChanged: (valor) {
                  setState(() {
                    aceitaTermos = valor ?? false;
                  });
                },
              ),

              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Li e concordo com os termos de uso e a política de privacidade do FoodJet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget conteudoEtapa() {
    switch (etapaAtual) {
      case 0:
        return etapaRestaurante();

      case 1:
        return etapaResponsavel();

      case 2:
        return etapaEndereco();

      case 3:
        return etapaPagamento();

      default:
        return const SizedBox();
    }
  }

  // ============================================================
  // BOTÕES
  // ============================================================

  Widget botoesNavegacao() {
    final ultimaEtapa =
        etapaAtual == nomesEtapas.length - 1;

    return Column(
      children: [
        Row(
          children: [
            if (etapaAtual > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed:
                        carregando ? null : voltarEtapa,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Voltar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),
            ],

            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: carregando
                      ? null
                      : ultimaEtapa
                          ? cadastrar
                          : proximaEtapa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: carregando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              ultimaEtapa
                                  ? 'Criar restaurante'
                                  : 'Continuar',
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            if (!ultimaEtapa) ...[
                              const SizedBox(width: 8),

                              const Icon(
                                Icons
                                    .arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (etapaAtual == 0)
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const LoginScreen(),
                ),
              );
            },
            child: const Text(
              'Já tenho uma conta',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            if (etapaAtual > 0) {
              voltarEtapa();
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
        ),

        title: const Text(
          'Cadastro',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            children: [
              if (etapaAtual == 0)
                cabecalho(),

              if (etapaAtual > 0)
                const SizedBox(height: 12),

              // --------------------------------------------------
              // INDICADOR
              // --------------------------------------------------

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: .035),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    indicadorEtapas(),

                    const SizedBox(height: 10),

                    Text(
                      nomesEtapas[etapaAtual],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // FORMULÁRIO
              // --------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: .045),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: conteudoEtapa(),
              ),

              const SizedBox(height: 16),

              botoesNavegacao(),

              const SizedBox(height: 10),

              const Text(
                'FoodJet Restaurante',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    cepController.removeListener(_monitorarCep);

    nomeController.dispose();
    cnpjController.dispose();
    emailController.dispose();
    telefoneController.dispose();

    responsavelController.dispose();
    cpfController.dispose();

    senhaController.dispose();
    confirmarSenhaController.dispose();

    cepController.dispose();
    ruaController.dispose();
    numeroController.dispose();
    complementoController.dispose();
    bairroController.dispose();
    cidadeController.dispose();
    estadoController.dispose();

    bancoController.dispose();
    agenciaController.dispose();
    contaController.dispose();
    pixController.dispose();

    super.dispose();
  }
}

