import 'package:flutter/material.dart';
import 'servicos/servico_backup_automatico.dart';
import 'servicos/servico_tema.dart';
import 'telas/abertura/tela_abertura.dart';
import 'tema/tema_aplicativo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServicoTema.carregar();
  ServicoBackupAutomatico.iniciar();
  runApp(const KazuxApp());
}

class KazuxApp extends StatelessWidget {
  const KazuxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ServicoTema.modo,
      builder: (context, modoTema, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kazux',
        theme: TemaAplicativo.themeClaro,
        darkTheme: TemaAplicativo.themeEscuro,
        themeMode: modoTema,
        home: const TelaAbertura(),
      ),
    );
  }
}
