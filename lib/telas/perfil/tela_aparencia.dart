import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../servicos/servico_tema.dart';
import '../../tema/tema_aplicativo.dart';

class TelaAparencia extends StatelessWidget {
  const TelaAparencia({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CabecalhoKazux(
            title: 'Aparência',
            subtitle: 'Escolha como o Kazux aparece para você.',
            leading: BotaoIconeKazux(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ServicoTema.modo,
              builder: (context, modoAtual, _) {
                return RadioGroup<ThemeMode>(
                  groupValue: modoAtual,
                  onChanged: (valor) {
                    if (valor != null) ServicoTema.alterar(valor);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                    children: [
                      Text(
                        'TEMA DO APLICATIVO',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: TemaAplicativo.textLight,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _OpcaoTema(
                        modo: ThemeMode.light,
                        modoAtual: modoAtual,
                        icone: Icons.light_mode_rounded,
                        titulo: 'Claro',
                        descricao: 'Visual claro usado como padrão no Kazux.',
                      ),
                      const SizedBox(height: 10),
                      _OpcaoTema(
                        modo: ThemeMode.dark,
                        modoAtual: modoAtual,
                        icone: Icons.dark_mode_rounded,
                        titulo: 'Escuro',
                        descricao:
                            'Confortável para usar à noite ou em locais escuros.',
                      ),
                      const SizedBox(height: 10),
                      _OpcaoTema(
                        modo: ThemeMode.system,
                        modoAtual: modoAtual,
                        icone: Icons.settings_brightness_rounded,
                        titulo: 'Automático',
                        descricao: 'Acompanha o tema definido no aparelho.',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcaoTema extends StatelessWidget {
  const _OpcaoTema({
    required this.modo,
    required this.modoAtual,
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  final ThemeMode modo;
  final ThemeMode modoAtual;
  final IconData icone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    final selecionado = modo == modoAtual;
    final cor = selecionado
        ? TemaAplicativo.teal
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return CartaoKazux(
      padding: EdgeInsets.zero,
      child: RadioListTile<ThemeMode>(
        value: modo,
        activeColor: TemaAplicativo.teal,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        secondary: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.14),
          child: Icon(icone, color: cor),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(descricao),
      ),
    );
  }
}
