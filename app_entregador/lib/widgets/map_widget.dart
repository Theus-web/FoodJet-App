
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  final LatLng? center;
  final double zoom;

  const MapWidget({
    super.key,
    this.center,
    this.zoom = 15,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  static const LatLng ipatinga = LatLng(
    -19.4708,
    -42.5396,
  );

  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentPosition;

  bool _carregandoLocalizacao = true;
  bool _localizacaoAtiva = false;

  String _mensagemLocalizacao = 'Obtendo localização...';

  @override
  void initState() {
    super.initState();

    _iniciarLocalizacao();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // LOCALIZAÇÃO
  // ============================================================

  Future<void> _iniciarLocalizacao() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _carregandoLocalizacao = false;
          _localizacaoAtiva = false;
          _mensagemLocalizacao =
              'Ative a localização do dispositivo';
        });

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          _carregandoLocalizacao = false;
          _localizacaoAtiva = false;
          _mensagemLocalizacao =
              'Permissão de localização negada';
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _carregandoLocalizacao = false;
          _localizacaoAtiva = false;
          _mensagemLocalizacao =
              'Permissão bloqueada nas configurações';
        });

        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng novaPosicao = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = novaPosicao;
        _carregandoLocalizacao = false;
        _localizacaoAtiva = true;
        _mensagemLocalizacao = 'Localização ativa';
      });

      // Aguarda o FlutterMap terminar de montar
      // antes de centralizar.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centralizarMapa(novaPosicao);
      });

      _iniciarStreamLocalizacao();
    } catch (e) {
      debugPrint(
        'Erro ao obter localização: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregandoLocalizacao = false;
        _localizacaoAtiva = false;
        _mensagemLocalizacao =
            'Não foi possível obter sua localização';
      });
    }
  }

  // ============================================================
  // ACOMPANHAR GPS
  // ============================================================

  void _iniciarStreamLocalizacao() {
    _positionSubscription?.cancel();

    const LocationSettings settings =
        LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        final LatLng novaPosicao = LatLng(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return;

        setState(() {
          _currentPosition = novaPosicao;
          _localizacaoAtiva = true;
          _mensagemLocalizacao = 'Localização ativa';
        });
      },
      onError: (error) {
        debugPrint(
          'Erro no stream de localização: $error',
        );
      },
    );
  }

  // ============================================================
  // CENTRALIZAR MAPA
  // ============================================================

  void _centralizarMapa(LatLng position) {
    if (!mounted) return;

    try {
      _mapController.move(
        position,
        widget.zoom,
      );
    } catch (e) {
      debugPrint(
        'Mapa ainda não está pronto: $e',
      );

      // Tenta novamente depois de alguns milissegundos.
      Future.delayed(
        const Duration(milliseconds: 300),
        () {
          if (!mounted) return;

          try {
            _mapController.move(
              position,
              widget.zoom,
            );
          } catch (e) {
            debugPrint(
              'Não foi possível centralizar mapa: $e',
            );
          }
        },
      );
    }
  }

  // ============================================================
  // BOTÃO MINHA LOCALIZAÇÃO
  // ============================================================

  Future<void> _minhaLocalizacao() async {
    // Já temos posição.
    if (_currentPosition != null) {
      _centralizarMapa(_currentPosition!);

      return;
    }

    // Ainda não temos posição.
    setState(() {
      _carregandoLocalizacao = true;
      _mensagemLocalizacao =
          'Obtendo localização...';
    });

    await _iniciarLocalizacao();

    if (_currentPosition != null) {
      _centralizarMapa(_currentPosition!);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final LatLng markerPosition =
        _currentPosition ?? widget.center ?? ipatinga;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // ========================================================
          // MAPA
          // ========================================================

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  widget.center ?? ipatinga,
              initialZoom: widget.zoom,
              minZoom: 3,
              maxZoom: 19,
              backgroundColor:
                  const Color(0xFFF8F9FA),
            ),
            children: [
              // ====================================================
              // OPENSTREETMAP
              // ====================================================

              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 19,
                userAgentPackageName:
                    'com.foodjet.entregador',
              ),

              // ====================================================
              // MARCADOR DO ENTREGADOR
              // ====================================================

              MarkerLayer(
                markers: [
                  Marker(
                    point: markerPosition,
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Halo
                        Container(
                          width: 68,
                          height: 68,
                          decoration:
                              BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(
                              0xFFF97316,
                            ).withOpacity(0.15),
                          ),
                        ),

                        // Círculo branco
                        Container(
                          width: 48,
                          height: 48,
                          decoration:
                              BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.22),
                                blurRadius: 9,
                                offset:
                                    const Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ],
                          ),
                          padding:
                              const EdgeInsets.all(4),
                          child: Container(
                            decoration:
                                const BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Color(0xFFF97316),
                            ),
                            child: const Icon(
                              Icons
                                  .navigation_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ========================================================
          // STATUS GPS
          // ========================================================

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildLocationStatus(),
          ),

          // ========================================================
          // BOTÃO CENTRALIZAR
          // ========================================================

          Positioned(
            right: 12,
            bottom: 12,
            child: _buildLocationButton(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildLocationStatus() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_carregandoLocalizacao)
              const SizedBox(
                width: 15,
                height: 15,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      Color(0xFFF97316),
                ),
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _localizacaoAtiva
                          ? const Color(
                              0xFF16A34A,
                            )
                          : const Color(
                              0xFFEF4444,
                            ),
                ),
              ),

            const SizedBox(width: 8),

            Text(
              _mensagemLocalizacao,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF171717),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO
  // ============================================================

  Widget _buildLocationButton() {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: _minhaLocalizacao,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            Icons.my_location_rounded,
            color:
                Color(0xFFF97316),
            size: 24,
          ),
        ),
      ),
    );
  }
}

