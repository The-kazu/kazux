import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mantém a preferência visual do usuário entre as aberturas do aplicativo.
class ServicoTema {
  static const _chaveModoTema = 'modo_tema_kazux';

  static final ValueNotifier<ThemeMode> modo = ValueNotifier(ThemeMode.light);

  static Future<void> carregar() async {
    final preferencias = await SharedPreferences.getInstance();
    modo.value = _paraModoTema(preferencias.getString(_chaveModoTema));
  }

  static Future<void> alterar(ThemeMode novoModo) async {
    modo.value = novoModo;
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveModoTema, novoModo.name);
  }

  static ThemeMode _paraModoTema(String? valor) {
    return switch (valor) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }
}
