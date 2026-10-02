import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  final LatLng? center;
  final double zoom;
  final String? enderecoDestino;
  final String? tituloDestino;

  const MapWidget({
    super.key,
    this.center,
    this.zoom = 15,
    this.enderecoDestino,
    this.tituloDestino,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  static const LatLng ipatinga = LatLng(-19.4708, -42.5396);

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentPosition;
  LatLng? _destino;
  List<LatLng> _rota = [];

  bool _carregandoLocalizacao = true;
  bool _carregandoRota = false;
  bool _localizacaoAtiva = false;

  String _mensagemLocalizacao = 'Obtendo localização...';
  String _mensagemRota = '';

  @override
  void initState() {
    super.initState();
    _iniciarLocalizacao();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final destinoMudou =
        oldWidget.enderecoDestino != widget.enderecoDestino;

    if (destinoMudou) {
      _destino = null;
      _rota = [];
      _mensagemRota = '';

      if (widget.enderecoDestino != null &&
          widget.enderecoDestino!.trim().isNotEmpty) {
        _prepararRota();
      }
    }
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
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _atualizarLocalizacao(false, 'Ative a localização do dispositivo');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _atualizarLocalizacao(false, 'Permissão de localização negada');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _atualizarLocalizacao(
          false,
          'Permissão bloqueada nas configurações',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final novaPosicao = LatLng(
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centralizarMapa(novaPosicao);
      });

      _iniciarStreamLocalizacao();

      if (widget.enderecoDestino != null &&
          widget.enderecoDestino!.trim().isNotEmpty) {
        await _prepararRota();
      }
    } catch (e) {
      debugPrint('❌ Erro ao obter localização: $e');

      _atualizarLocalizacao(
        false,
        'Não foi possível obter sua localização',
      );
    }
  }

  void _atualizarLocalizacao(bool ativa, String mensagem) {
    if (!mounted) return;

    setState(() {
      _carregandoLocalizacao = false;
      _localizacaoAtiva = ativa;
      _mensagemLocalizacao = mensagem;
    });
  }

  void _iniciarStreamLocalizacao() {
    _positionSubscription?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        final novaPosicao = LatLng(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return;

        setState(() {
          _currentPosition = novaPosicao;
          _localizacaoAtiva = false;
          _mensagemLocalizacao = '';
        });
      },
      onError: (error) {
        debugPrint('❌ Erro no stream de localização: $error');
      },
    );
  }
  
  // ============================================================
  // ROTA
  // ============================================================

  Future<void> _prepararRota() async {
    final endereco = widget.enderecoDestino?.trim();

    if (endereco == null || endereco.isEmpty) {
      return;
    }

    if (_currentPosition == null) {
      debugPrint('⚠️ Rota aguardando localização do entregador.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _carregandoRota = true;
      _mensagemRota = 'Calculando rota...';
      _rota = [];
    });

    try {
      final destino = await _geocodificar(endereco);

      if (destino == null) {
        if (!mounted) return;

        setState(() {
          _carregandoRota = false;
          _mensagemRota = 'Não foi possível localizar o destino.';
        });

        debugPrint('❌ Endereço não localizado: $endereco');
        return;
      }

      _destino = destino;

      final pontos = await _buscarRota(
        _currentPosition!,
        destino,
      );

      if (!mounted) return;

      setState(() {
        _rota = pontos;
        _carregandoRota = false;
        _mensagemRota = pontos.length >= 2
            ? 'Rota pronta'
            : 'Rota não encontrada';
      });

      if (pontos.length >= 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ajustarCameraParaRota();
        });
      } else {
        _centralizarMapa(destino, zoom: 16);
      }
    } catch (e) {
      debugPrint('❌ Erro ao calcular rota: $e');

      if (!mounted) return;

      setState(() {
        _carregandoRota = false;
        _mensagemRota = 'Erro ao calcular rota';
      });
    }
  }

  Future<LatLng?> _geocodificar(String endereco) async {
    final consulta = endereco.toLowerCase().contains('ipatinga')
        ? endereco
        : '$endereco, Ipatinga, MG, Brasil';

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': consulta,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'br',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'FoodJet-Entregador/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Nominatim HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List || data.isEmpty) {
      return null;
    }

    final item = data.first;
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');

    if (lat == null || lon == null) {
      return null;
    }

    return LatLng(lat, lon);
  }

  Future<List<LatLng>> _buscarRota(
    LatLng origem,
    LatLng destino,
  ) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/${origem.longitude},${origem.latitude};${destino.longitude},${destino.latitude}',
      {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'FoodJet-Entregador/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OSRM HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data is! Map || data['code'] != 'Ok') {
      return [];
    }

    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) {
      return [];
    }

    final geometry = routes.first['geometry'];
    final coordinates = geometry is Map ? geometry['coordinates'] : null;

    if (coordinates is! List) {
      return [];
    }

    return coordinates
        .whereType<List>()
        .where((p) => p.length >= 2)
        .map(
          (p) => LatLng(
            (p[1] as num).toDouble(),
            (p[0] as num).toDouble(),
          ),
        )
        .toList();
  }

  void _ajustarCameraParaRota() {
    if (!mounted || _rota.length < 2) return;

    try {
      final bounds = LatLngBounds.fromPoints(_rota);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(55, 55, 55, 75),
          maxZoom: 17,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Não foi possível ajustar a rota: $e');
    }
  }

  // ============================================================
  // CÂMERA
  // ============================================================

  void _centralizarMapa(
    LatLng position, {
    double? zoom,
  }) {
    if (!mounted) return;

    try {
      _mapController.move(
        position,
        zoom ?? widget.zoom,
      );
    } catch (e) {
      Future.delayed(
        const Duration(milliseconds: 300),
        () {
          if (!mounted) return;
          try {
            _mapController.move(
              position,
              zoom ?? widget.zoom,
            );
          } catch (_) {}
        },
      );
    }
  }

  Future<void> _minhaLocalizacao() async {
    if (_currentPosition != null) {
      if (_rota.length >= 2) {
        _ajustarCameraParaRota();
      } else {
        _centralizarMapa(_currentPosition!);
      }
      return;
    }

    await _iniciarLocalizacao();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final markerPosition =
        _currentPosition ?? widget.center ?? ipatinga;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.center ?? ipatinga,
              initialZoom: widget.zoom,
              minZoom: 3,
              maxZoom: 19,
              backgroundColor: const Color(0xFFF8F9FA),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxZoom: 19,
                userAgentPackageName: 'com.foodjet.entregador',
              ),

              if (_rota.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _rota,
                      strokeWidth: 7,
                      color: const Color(0xFFF97316),
                    ),
                    Polyline(
                      points: _rota,
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: markerPosition,
                    width: 38,
                    height: 38,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF97316)
                                .withOpacity(0.15),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.22),
                                blurRadius: 9,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF97316),
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_destino != null)
                    Marker(
                      point: _destino!,
                      width: 130,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.tituloDestino?.trim().isNotEmpty == true
                                  ? widget.tituloDestino!.trim()
                                  : 'Destino',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFDC2626),
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 12,
            left: 12,
            right: 62,
            child: _buildInfo(),
          ),

          Positioned(
            right: 12,
            bottom: 12,
            child: _buildLocationButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
  final temDestino = widget.enderecoDestino?.trim().isNotEmpty == true;

  // Sem destino/entrega: não exibe mensagem fixa no mapa.
  if (!temDestino) {
    return const SizedBox.shrink();
  }

  return Align(
    alignment: Alignment.topLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _carregandoRota
                  ? Colors.orange
                  : const Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _carregandoRota
                  ? 'Calculando rota...'
                  : (_mensagemRota.isNotEmpty
                      ? _mensagemRota
                      : 'Rota ativa'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLocationButton() {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _minhaLocalizacao,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            Icons.my_location_rounded,
            color: Color(0xFFF97316),
            size: 24,
          ),
        ),
      ),
    );
  }
}
