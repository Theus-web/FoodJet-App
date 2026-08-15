
import 'package:flutter/material.dart';

class RestaurantProvider extends ChangeNotifier {
  String? restauranteId;
  String? nome;
  String? telefone;
  String? imagem;

  bool aberto = true;

  // ============================================================
  // DEFINIR RESTAURANTE LOGADO
  // ============================================================

  void setRestaurant({
    required String id,
    required String nomeRestaurante,
    String? telefoneRestaurante,
    String? imagemRestaurante,
    bool? statusAberto,
  }) {
    restauranteId = id.trim();

    nome = nomeRestaurante.trim();

    telefone = telefoneRestaurante;

    imagem = imagemRestaurante;

    if (statusAberto != null) {
      aberto = statusAberto;
    }

    notifyListeners();
  }

  // ============================================================
  // DEFINIR SOMENTE O ID
  // ============================================================

  void setRestaurantId(String id) {
    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      return;
    }

    restauranteId = idLimpo;

    notifyListeners();
  }

  // ============================================================
  // OBTER ID DO RESTAURANTE
  // ============================================================

  String? getRestaurantId() {
    if (restauranteId == null) {
      return null;
    }

    final id = restauranteId!.trim();

    if (id.isEmpty) {
      return null;
    }

    return id;
  }

  // ============================================================
  // VERIFICAR SE EXISTE RESTAURANTE
  // ============================================================

  bool get possuiRestaurante {
    return getRestaurantId() != null;
  }

  // ============================================================
  // ABRIR / FECHAR RESTAURANTE
  // ============================================================

  void alterarStatus() {
    aberto = !aberto;

    notifyListeners();
  }

  // ============================================================
  // DEFINIR STATUS
  // ============================================================

  void definirStatus(bool status) {
    aberto = status;

    notifyListeners();
  }

  // ============================================================
  // LIMPAR DADOS DO RESTAURANTE
  // ============================================================

  void limpar() {
    restauranteId = null;
    nome = null;
    telefone = null;
    imagem = null;

    aberto = false;

    notifyListeners();
  }

  // ============================================================
  // LIMPAR LOGIN
  // ============================================================

  void logout() {
    restauranteId = null;

    nome = null;

    telefone = null;

    imagem = null;

    aberto = false;

    notifyListeners();
  }
}

