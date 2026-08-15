
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get modoEscuro =>
      _themeMode == ThemeMode.dark;

  void alternarModo(bool ativar) {
    _themeMode = ativar
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();
  }
}

final ThemeController themeController =
    ThemeController();

