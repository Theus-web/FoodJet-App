import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color laranja = Color(0xFFF97316);

  final _formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final cpfController = TextEditingController();
  final nascimentoController = TextEditingController();
  final telefoneController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final cepController = TextEditingController();
  final enderecoController = TextEditingController();
  final numeroController = TextEditingController();
  final complementoController = TextEditingController();
  final bairroController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();

  final cnhController = TextEditingController();
  final categoriaCnhController = TextEditingController();
  final placaController = TextEditingController();
  final renavamController = TextEditingController();

  bool mostrarSenha = false;
  bool mostrarConfirmarSenha = false;
  bool aceitouTermos = false;
  bool carregando = false;

  File? cnhFrente;
  File? cnhVerso;
  File? crlv;
  File? comprovanteEndereco;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    nomeController.dispose();
    cpfController.dispose();
    nascimentoController.dispose();
    telefoneController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();

    cepController.dispose();
    enderecoController.dispose();
    numeroController.dispose();
    complementoController.dispose();
    bairroController.dispose();
    cidadeController.dispose();
    estadoController.dispose();

    cnhController.dispose();
    categoriaCnhController.dispose();
    placaController.dispose();
    renavamController.dispose();

    super.dispose();
  }

  // ============================================================
  // DOCUMENTO - GALERIA
  // ============================================================

  Future<void> _escolherDocumento({
    required String tipo,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('FOODJET - SELECIONAR DOCUMENTO');
      debugPrint('Tipo: $tipo');
      debugPrint('Abrindo galeria...');
      debugPrint('========================================');

      final XFile? arquivo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (arquivo == null) {
        debugPrint('Usuário cancelou a seleção.');
        return;
      }

      debugPrint('Arquivo selecionado: ${arquivo.path}');

      final file = File(arquivo.path);

      final existe = await file.exists();

      debugPrint('Arquivo existe: $existe');

      if (!existe) {
        if (!mounted) return;

        _mensagem(
          'O arquivo selecionado não foi encontrado.',
          erro: true,
        );

        return;
      }

      final tamanho = await file.length();

      debugPrint('Tamanho: $tamanho bytes');

      if (tamanho <= 0) {
        if (!mounted) return;

        _mensagem(
          'O arquivo selecionado está vazio.',
          erro: true,
        );

        return;
      }

      if (!mounted) return;

      _salvarDocumento(
        tipo: tipo,
        file: file,
      );

      _mensagem(
        'Documento selecionado com sucesso.',
      );
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERRO AO SELECIONAR DOCUMENTO');
      debugPrint('Erro: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      _mensagem(
        'Erro ao selecionar documento:\n$e',
        erro: true,
      );
    }
  }

  // ============================================================
  // DOCUMENTO - CÂMERA
  // ============================================================

  Future<void> _tirarFoto({
    required String tipo,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('FOODJET - TIRAR FOTO');
      debugPrint('Tipo: $tipo');
      debugPrint('Abrindo câmera...');
      debugPrint('========================================');

      final XFile? arquivo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (arquivo == null) {
        debugPrint('Usuário cancelou a câmera.');
        return;
      }

      debugPrint('Foto capturada: ${arquivo.path}');

      final file = File(arquivo.path);

      final existe = await file.exists();

      debugPrint('Arquivo existe: $existe');

      if (!existe) {
        if (!mounted) return;

        _mensagem(
          'A foto não foi encontrada.',
          erro: true,
        );

        return;
      }

      final tamanho = await file.length();

      debugPrint('Tamanho: $tamanho bytes');

      if (tamanho <= 0) {
        if (!mounted) return;

        _mensagem(
          'A foto capturada está vazia.',
          erro: true,
        );

        return;
      }

      if (!mounted) return;

      _salvarDocumento(
        tipo: tipo,
        file: file,
      );

      _mensagem(
        'Foto adicionada com sucesso.',
      );
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERRO AO TIRAR FOTO');
      debugPrint('Erro: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      _mensagem(
        'Erro ao tirar foto:\n$e',
        erro: true,
      );
    }
  }

  // ============================================================
  // SALVAR DOCUMENTO
  // ============================================================

  void _salvarDocumento({
    required String tipo,
    required File file,
  }) {
    setState(() {
      switch (tipo) {
        case 'cnh_frente':
          cnhFrente = file;
          break;

        case 'cnh_verso':
          cnhVerso = file;
          break;

        case 'crlv':
          crlv = file;
          break;

        case 'comprovante':
          comprovanteEndereco = file;
          break;
      }
    });
  }

  // ============================================================
  // MENU DE DOCUMENTO
  // ============================================================

  Future<void> _selecionarDocumento(
    String tipo,
  ) async {
    if (carregando) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Adicionar documento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: laranja,
                  ),
                  title: const Text(
                    'Tirar foto',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'Usar a câmera do celular',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Future.delayed(
                      const Duration(milliseconds: 200),
                      () {
                        if (mounted) {
                          _tirarFoto(
                            tipo: tipo,
                          );
                        }
                      },
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: laranja,
                  ),
                  title: const Text(
                    'Escolher da galeria',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'Selecionar uma imagem existente',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    Future.delayed(
                      const Duration(milliseconds: 200),
                      () {
                        if (mounted) {
                          _escolherDocumento(
                            tipo: tipo,
                          );
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // VALIDAR DOCUMENTOS
  // ============================================================

  bool _validarDocumentos() {
    if (cnhFrente == null) {
      _mensagem(
        'Envie a frente da CNH.',
        erro: true,
      );
      return false;
    }

    if (cnhVerso == null) {
      _mensagem(
        'Envie o verso da CNH.',
        erro: true,
      );
      return false;
    }

    if (crlv == null) {
      _mensagem(
        'Envie o CRLV da moto.',
        erro: true,
      );
      return false;
    }

    if (comprovanteEndereco == null) {
      _mensagem(
        'Envie o comprovante de endereço.',
        erro: true,
      );
      return false;
    }

    if (!aceitouTermos) {
      _mensagem(
        'Aceite os termos para continuar.',
        erro: true,
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // CADASTRAR
  // ============================================================

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_validarDocumentos()) {
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      /*
       * INTEGRAÇÃO COM BACKEND SERÁ FEITA NA PRÓXIMA ETAPA.
       *
       * Dados:
       *
       * tipo = entregador
       * tipo_veiculo = moto
       * status_entregador = pendente
       *
       * Documentos:
       * cnh_frente
       * cnh_verso
       * crlv
       * comprovante_endereco
       */

      await Future.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted) return;

      _mensagem(
        'Cadastro preenchido. Os documentos estão prontos para envio.',
      );
    } catch (e) {
      if (!mounted) return;

      _mensagem(
        'Não foi possível realizar o cadastro.',
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
  // MENSAGEM
  // ============================================================

  void _mensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor:
              erro ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: Duration(
            seconds: erro ? 5 : 3,
          ),
        ),
      );
  }

  // ============================================================
  // CAMPO
  // ============================================================

  Widget _campo({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool senha = false,
    bool mostrar = false,
    VoidCallback? alternarSenha,
    TextInputType? teclado,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: senha && !mostrar,
      keyboardType: teclado,
      style: const TextStyle(
        color: Colors.white,
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Preencha este campo';
            }

            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white60,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70,
        ),
        suffixIcon:
            senha
                ? IconButton(
                    onPressed: alternarSenha,
                    icon: Icon(
                      mostrar
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white54,
                    ),
                  )
                : null,
        filled: true,
        fillColor: const Color(0xFF171717),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFF333333),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: laranja,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENTO CARD
  // ============================================================

  Widget _documentoCard({
    required String titulo,
    required String descricao,
    required String tipo,
    required File? arquivo,
    required IconData icon,
  }) {
    final enviado = arquivo != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              enviado
                  ? Colors.green
                  : const Color(0xFF333333),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: laranja.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: laranja,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enviado
                          ? 'Documento selecionado'
                          : descricao,
                      style: TextStyle(
                        color:
                            enviado
                                ? Colors.green
                                : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (enviado)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
            ],
          ),

          if (enviado) ...[
            const SizedBox(height: 15),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Image.file(
                  arquivo,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: const Text(
                        'Não foi possível visualizar a imagem',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              arquivo.path.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  carregando
                      ? null
                      : () {
                        _selecionarDocumento(tipo);
                      },
              icon: Icon(
                enviado
                    ? Icons.edit
                    : Icons.upload_file,
                size: 19,
              ),
              label: Text(
                enviado
                    ? 'Alterar documento'
                    : 'Enviar documento',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: laranja,
                side: const BorderSide(
                  color: laranja,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Criar conta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            35,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Seja um Entregador',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Cadastre seus dados e envie seus documentos para começar a trabalhar com a FoodJet.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Dados pessoais',
                style: TextStyle(
                  color: laranja,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _campo(
                label: 'Nome completo',
                controller: nomeController,
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'CPF',
                controller: cpfController,
                icon: Icons.badge_outlined,
                teclado: TextInputType.number,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Data de nascimento',
                controller: nascimentoController,
                icon: Icons.calendar_month_outlined,
                teclado: TextInputType.datetime,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Telefone',
                controller: telefoneController,
                icon: Icons.phone_outlined,
                teclado: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'E-mail',
                controller: emailController,
                icon: Icons.email_outlined,
                teclado: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Senha',
                controller: senhaController,
                icon: Icons.lock_outline,
                senha: true,
                mostrar: mostrarSenha,
                alternarSenha: () {
                  setState(() {
                    mostrarSenha = !mostrarSenha;
                  });
                },
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Confirmar senha',
                controller: confirmarSenhaController,
                icon: Icons.lock_outline,
                senha: true,
                mostrar: mostrarConfirmarSenha,
                alternarSenha: () {
                  setState(() {
                    mostrarConfirmarSenha =
                        !mostrarConfirmarSenha;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme sua senha';
                  }

                  if (value != senhaController.text) {
                    return 'As senhas não conferem';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 35),

              const Text(
                'Endereço',
                style: TextStyle(
                  color: laranja,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _campo(
                label: 'CEP',
                controller: cepController,
                icon: Icons.location_on_outlined,
                teclado: TextInputType.number,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Rua',
                controller: enderecoController,
                icon: Icons.home_outlined,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _campo(
                      label: 'Número',
                      controller: numeroController,
                      icon: Icons.numbers,
                      teclado: TextInputType.number,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 3,
                    child: _campo(
                      label: 'Complemento',
                      controller: complementoController,
                      icon: Icons.apartment_outlined,
                      validator: (_) => null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Bairro',
                controller: bairroController,
                icon: Icons.location_city_outlined,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _campo(
                      label: 'Cidade',
                      controller: cidadeController,
                      icon: Icons.location_city,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 1,
                    child: _campo(
                      label: 'UF',
                      controller: estadoController,
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Text(
                'Dados da moto',
                style: TextStyle(
                  color: laranja,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: laranja.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: laranja.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.two_wheeler,
                      color: laranja,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'O cadastro do FoodJet Entregador é exclusivo para entregadores de moto.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              _campo(
                label: 'Placa da moto',
                controller: placaController,
                icon: Icons.directions_car_outlined,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Renavam',
                controller: renavamController,
                icon: Icons.confirmation_number_outlined,
                teclado: TextInputType.number,
              ),

              const SizedBox(height: 35),

              const Text(
                'CNH',
                style: TextStyle(
                  color: laranja,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _campo(
                label: 'Número da CNH',
                controller: cnhController,
                icon: Icons.badge_outlined,
                teclado: TextInputType.number,
              ),

              const SizedBox(height: 14),

              _campo(
                label: 'Categoria da CNH',
                controller: categoriaCnhController,
                icon: Icons.drive_eta_outlined,
              ),

              const SizedBox(height: 15),

              _documentoCard(
                titulo: 'CNH — frente',
                descricao:
                    'Envie uma foto nítida da frente da CNH.',
                tipo: 'cnh_frente',
                arquivo: cnhFrente,
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 12),

              _documentoCard(
                titulo: 'CNH — verso',
                descricao:
                    'Envie uma foto nítida do verso da CNH.',
                tipo: 'cnh_verso',
                arquivo: cnhVerso,
                icon: Icons.badge,
              ),

              const SizedBox(height: 35),

              const Text(
                'CRLV da moto',
                style: TextStyle(
                  color: laranja,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Envie o documento da moto que será utilizada nas entregas.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 15),

              _documentoCard(
                titulo: 'CRLV',
                descricao:
                    'Envie uma foto ou imagem legível do CRLV.',
                tipo: 'crlv',
                arquivo: crlv,
                icon: Icons.two_wheeler,
              ),

              const SizedBox(height: 35),

              const Text(
                'Comprovante de endereço',
                style: TextStyle(
                  color: laranja,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Pode ser uma conta de água, luz, telefone ou outro documento que comprove seu endereço.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 15),

              _documentoCard(
                titulo: 'Comprovante de endereço',
                descricao:
                    'Envie uma foto nítida do comprovante.',
                tipo: 'comprovante',
                arquivo: comprovanteEndereco,
                icon: Icons.home_outlined,
              ),

              const SizedBox(height: 35),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: aceitouTermos,
                      activeColor: laranja,
                      onChanged:
                          carregando
                              ? null
                              : (value) {
                                setState(() {
                                  aceitouTermos =
                                      value ?? false;
                                });
                              },
                    ),

                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 12,
                        ),
                        child: Text(
                          'Declaro que as informações e documentos enviados são verdadeiros e concordo com os termos de uso e política de privacidade do FoodJet.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      carregando ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    disabledBackgroundColor:
                        laranja.withValues(
                      alpha: 0.5,
                    ),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child:
                      carregando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'ENVIAR CADASTRO',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'Após o envio, seu cadastro será analisado pela equipe FoodJet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}