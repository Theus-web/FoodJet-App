import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ==========================================================
  // SERVIÇO DE AUTENTICAÇÃO
  // ==========================================================

  final AuthService _authService = AuthService();

  // ==========================================================
  // CONFIGURAÇÃO
  // ==========================================================

  static const Duration _duracaoSplash = Duration(seconds: 6);

  // ==========================================================
  // CONTROLADORES
  // ==========================================================

  late AnimationController _entradaController;
  late AnimationController _brilhoController;
  late AnimationController _textoController;
  late AnimationController _progressoController;

  // ==========================================================
  // ANIMAÇÕES
  // ==========================================================

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // ==========================================================
  // CONTROLE
  // ==========================================================

  bool _carregando = true;

  Timer? _navegacaoTimer;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    // ========================================================
    // ENTRADA PRINCIPAL
    // ========================================================

    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1400,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entradaController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entradaController,
        curve: Curves.easeOutBack,
      ),
    );

    // ========================================================
    // LOGO
    // ========================================================

    _logoFade = CurvedAnimation(
      parent: _entradaController,
      curve: const Interval(
        0.0,
        0.65,
        curve: Curves.easeOut,
      ),
    );

    _logoScale = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entradaController,
        curve: const Interval(
          0.0,
          0.75,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    // ========================================================
    // TEXTO
    // ========================================================

    _textoController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    );

    // ========================================================
    // BRILHO
    // ========================================================

    _brilhoController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    // ========================================================
    // PROGRESSO
    // ========================================================

    _progressoController = AnimationController(
      vsync: this,
      duration: _duracaoSplash,
    );

    // ========================================================
    // INICIAR ANIMAÇÕES
    // ========================================================

    _entradaController.forward();

    Future.delayed(
      const Duration(
        milliseconds: 650,
      ),
      () {
        if (!mounted) return;

        _textoController.forward();
      },
    );

    Future.delayed(
      const Duration(
        milliseconds: 900,
      ),
      () {
        if (!mounted) return;

        _brilhoController.repeat();
      },
    );

    _progressoController.forward();

    // ========================================================
    // INICIALIZAR FOODJET
    // ========================================================

    _inicializarFoodJet();
  }

  // ==========================================================
  // INICIALIZAR FOODJET
  // ==========================================================

  Future<void> _inicializarFoodJet() async {
    final inicio = DateTime.now();

    Map<String, dynamic>? sessao;

    debugPrint(
      '========================================',
    );

    debugPrint(
      'FOODJET: iniciando Splash moderna...',
    );

    try {
      // ======================================================
      // VERIFICAR SESSÃO
      // ======================================================

      sessao = await _authService.obterSessao();

      if (sessao != null) {
        debugPrint(
          'FOODJET: sessão encontrada.',
        );
      } else {
        debugPrint(
          'FOODJET: nenhuma sessão encontrada.',
        );
      }
    } catch (e) {
      debugPrint(
        'FOODJET: erro ao verificar sessão: $e',
      );

      sessao = null;
    }

    // ========================================================
    // GARANTIR 6 SEGUNDOS
    // ========================================================

    final decorrido = DateTime.now().difference(inicio);

    if (decorrido < _duracaoSplash) {
      await Future.delayed(
        _duracaoSplash - decorrido,
      );
    }

    if (!mounted) {
      return;
    }

    _abrirProximaTela(sessao);
  }

  // ==========================================================
  // ABRIR PRÓXIMA TELA
  // ==========================================================

  void _abrirProximaTela(
    Map<String, dynamic>? sessao,
  ) {
    if (!_carregando) {
      return;
    }

    setState(() {
      _carregando = false;
    });

    // ========================================================
    // USUÁRIO LOGADO
    // ========================================================

    if (sessao != null && sessao['usuario'] != null) {
      final usuario = Map<String, dynamic>.from(
        sessao['usuario'],
      );

      debugPrint(
        'FOODJET: entrando na Home.',
      );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (
            context,
            animation,
            secondaryAnimation,
          ) {
            return HomeScreen(
              usuario: usuario,
            );
          },
          transitionDuration: const Duration(
            milliseconds: 700,
          ),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );

      return;
    }

    // ========================================================
    // USUÁRIO NÃO LOGADO
    // ========================================================

    debugPrint(
      'FOODJET: entrando no Login.',
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const LoginScreen();
        },
        transitionDuration: const Duration(
          milliseconds: 700,
        ),
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ==========================================================
  // INTERFACE
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B00),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            // ==================================================
            // DIMENSÕES DA TELA
            // ==================================================

            final largura = constraints.maxWidth;

            final altura = constraints.maxHeight;

            final menorDimensao = largura < altura ? largura : altura;

            // ==================================================
            // TAMANHO RESPONSIVO DO LOTTIE
            // ==================================================

            final tamanhoLogo = (menorDimensao * 0.58).clamp(
              210.0,
              340.0,
            );

            // ==================================================
            // LARGURA RESPONSIVA DO PROGRESSO
            // ==================================================

            final larguraProgresso = (largura * 0.42).clamp(
              120.0,
              180.0,
            );

            return Stack(
              children: [
                // ==============================================
                // BRILHO SUPERIOR
                // ==============================================

                Positioned(
                  top: -120,
                  right: -100,
                  child: IgnorePointer(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(
                              0xFFFFA94D,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ==============================================
                // BRILHO INFERIOR
                // ==============================================

                Positioned(
                  bottom: -150,
                  left: -120,
                  child: IgnorePointer(
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(
                              0xFFE85D00,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ==============================================
                // CONTEÚDO CENTRAL
                // ==============================================

                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ====================================
                          // LOTTIE RESPONSIVO
                          // ====================================

                          AnimatedBuilder(
                            animation: _brilhoController,
                            builder: (
                              context,
                              child,
                            ) {
                              final brilho = _brilhoController.value;

                              return SizedBox(
                                width: tamanhoLogo,
                                height: tamanhoLogo,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.06 + (brilho * 0.08),
                                        ),
                                        blurRadius: 35 + (brilho * 20),
                                        spreadRadius: 3 + (brilho * 4),
                                      ),
                                    ],
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: Lottie.asset(
                                  'assets/animations/foodjet_splash.json',
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  repeat: false,
                                  animate: true,
                                  frameRate: FrameRate.max,
                                ),
                              ),
                            ),
                          ),

                          // ====================================
                          // ESPAÇAMENTO
                          // ====================================

                          SizedBox(
                            height: (altura * 0.035).clamp(
                              20.0,
                              38.0,
                            ),
                          ),

                          // ====================================
                          // PROGRESSO
                          // ====================================

                          SizedBox(
                            width: larguraProgresso,
                            child: AnimatedBuilder(
                              animation: _progressoController,
                              builder: (
                                context,
                                child,
                              ) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ==========================
                                    // BARRA
                                    // ==========================

                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        10,
                                      ),
                                      child: LinearProgressIndicator(
                                        value: _progressoController.value,
                                        minHeight: 3,
                                        backgroundColor:
                                            Colors.white.withValues(
                                          alpha: 0.20,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),

                                    // ==========================
                                    // ESPAÇAMENTO
                                    // ==========================

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    // ==========================
                                    // TEXTO
                                    // ==========================

                                    Text(
                                      'Preparando tudo para você...',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _navegacaoTimer?.cancel();

    _entradaController.dispose();
    _brilhoController.dispose();
    _textoController.dispose();
    _progressoController.dispose();

    super.dispose();
  }
}
