import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../modelos/modelo_transacao.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({
    super.key,
    required this.mesSelecionado,
    required this.onMesAnterior,
    required this.onMesProximo,
    required this.podeVoltarMes,
    required this.podeAvancarMes,
  });

  final DateTime mesSelecionado;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesProximo;
  final bool podeVoltarMes;
  final bool podeAvancarMes;

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

enum _TipoGrafico { palitos, pizza }

class _TelaRelatoriosState extends State<TelaRelatorios> {
  late Future<List<ModeloTransacao>> futuro;
  _TipoGrafico tipoGrafico = _TipoGrafico.palitos;

  @override
  void initState() {
    super.initState();
    futuro = ServicoBancoDados.getTransacoes();
  }

  @override
  void didUpdateWidget(covariant TelaRelatorios oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mesmoMes(oldWidget.mesSelecionado, widget.mesSelecionado)) {
      futuro = ServicoBancoDados.getTransacoes();
    }
  }

  Future<void> _atualizarRelatorio() async {
    setState(() => futuro = ServicoBancoDados.getTransacoes());
    await futuro;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<List<ModeloTransacao>>(
        future: futuro,
        builder: (context, snapshot) {
          final transacoes = (snapshot.data ?? [])
              .where((item) => mesmoMes(item.data, widget.mesSelecionado))
              .toList();
          final receitas = transacoes
              .where((item) => item.isReceita)
              .fold<double>(0, (sum, item) => sum + item.valor);
          final despesas = transacoes
              .where((item) => item.isDespesa)
              .fold<double>(0, (sum, item) => sum + item.valor);
          final categorias = _categorias(transacoes);

          return RefreshIndicator(
            onRefresh: _atualizarRelatorio,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: CabecalhoKazux(
                    title: 'Relatórios',
                    subtitle:
                        'Gráficos de ${nomeMesAno(widget.mesSelecionado)}.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SeletorMesKazux(
                        mes: widget.mesSelecionado,
                        onAnterior: widget.onMesAnterior,
                        onProximo: widget.onMesProximo,
                        podeVoltar: widget.podeVoltarMes,
                        podeAvancar: widget.podeAvancarMes,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _NumeroRelatorio(
                              label: 'Receitas',
                              value: receitas,
                              icon: Icons.arrow_downward_rounded,
                              color: TemaAplicativo.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _NumeroRelatorio(
                              label: 'Despesas',
                              value: despesas,
                              icon: Icons.arrow_upward_rounded,
                              color: TemaAplicativo.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CartaoKazux(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TituloGrafico(
                              title: 'Gastos por categoria',
                              subtitle: categorias.isEmpty
                                  ? 'Cadastre despesas para gerar os gráficos.'
                                  : 'Total gasto: ${formatarMoeda(despesas)}',
                            ),
                            const SizedBox(height: 14),
                            _SeletorGrafico(
                              tipoGrafico: tipoGrafico,
                              onChanged: (tipo) {
                                setState(() => tipoGrafico = tipo);
                              },
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: categorias.isEmpty
                                  ? const _EstadoVazioGrafico()
                                  : tipoGrafico == _TipoGrafico.palitos
                                  ? _GraficoPalitosCategorias(
                                      key: const ValueKey('palitos'),
                                      categorias: categorias,
                                    )
                                  : _GraficoPizzaCategorias(
                                      key: const ValueKey('pizza'),
                                      categorias: categorias,
                                      total: despesas,
                                    ),
                            ),
                            if (categorias.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              ...categorias.map(
                                (entry) => _CategoriaLinha(entry: entry),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CartaoKazux(
                        color: TemaAplicativo.tealDark,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_rounded,
                              color: Color(0xFF7EFFD4),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                categorias.isEmpty
                                    ? 'Cadastre despesas para liberar análises por categoria.'
                                    : 'Seu maior gasto está em ${categorias.first.nome}, com ${categorias.first.percentual.toStringAsFixed(0)}% das despesas.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_CategoriaResumo> _categorias(List<ModeloTransacao> transacoes) {
    final porCategoria = <String, double>{};
    for (final item in transacoes.where((item) => item.isDespesa)) {
      porCategoria[item.categoria] =
          (porCategoria[item.categoria] ?? 0) + item.valor;
    }
    final total = porCategoria.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final lista =
        porCategoria.entries
            .map(
              (entry) => _CategoriaResumo(
                nome: entry.key,
                valor: entry.value,
                percentual: total <= 0 ? 0 : entry.value / total * 100,
                cor: corPorCategoria(entry.key),
              ),
            )
            .toList()
          ..sort((a, b) => b.valor.compareTo(a.valor));
    return lista;
  }
}

class _TituloGrafico extends StatelessWidget {
  const _TituloGrafico({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: TemaAplicativo.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: TemaAplicativo.textLight, fontSize: 12),
        ),
      ],
    );
  }
}

class _NumeroRelatorio extends StatelessWidget {
  const _NumeroRelatorio({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CartaoKazux(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: TemaAplicativo.textLight)),
          const SizedBox(height: 5),
          Text(
            formatarMoeda(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeletorGrafico extends StatelessWidget {
  const _SeletorGrafico({required this.tipoGrafico, required this.onChanged});

  final _TipoGrafico tipoGrafico;
  final ValueChanged<_TipoGrafico> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TemaAplicativo.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _BotaoTipoGrafico(
            label: 'Palitos',
            icon: Icons.bar_chart_rounded,
            selected: tipoGrafico == _TipoGrafico.palitos,
            onTap: () => onChanged(_TipoGrafico.palitos),
          ),
          _BotaoTipoGrafico(
            label: 'Pizza',
            icon: Icons.pie_chart_rounded,
            selected: tipoGrafico == _TipoGrafico.pizza,
            onTap: () => onChanged(_TipoGrafico.pizza),
          ),
        ],
      ),
    );
  }
}

class _BotaoTipoGrafico extends StatelessWidget {
  const _BotaoTipoGrafico({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? TemaAplicativo.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : TemaAplicativo.textMid,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : TemaAplicativo.textMid,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraficoPalitosCategorias extends StatelessWidget {
  const _GraficoPalitosCategorias({super.key, required this.categorias});

  final List<_CategoriaResumo> categorias;

  @override
  Widget build(BuildContext context) {
    final itens = categorias.take(6).toList();
    final maxValue = itens.fold<double>(
      1,
      (max, item) => item.valor > max ? item.valor : max,
    );

    return SizedBox(
      height: 238,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: itens.map((item) {
                final altura = (item.valor / maxValue * 154).clamp(18.0, 154.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatarCurto(item.valor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TemaAplicativo.textDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: altura,
                          width: 24,
                          decoration: BoxDecoration(
                            color: item.cor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: item.cor.withValues(alpha: 0.26),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: itens.map((item) {
              return Expanded(
                child: Text(
                  item.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TemaAplicativo.textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatarCurto(double value) {
    if (value >= 1000) {
      return 'R\$${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$${value.toStringAsFixed(0)}';
  }
}

class _GraficoPizzaCategorias extends StatelessWidget {
  const _GraficoPizzaCategorias({
    super.key,
    required this.categorias,
    required this.total,
  });

  final List<_CategoriaResumo> categorias;
  final double total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: CustomPaint(
              painter: _PizzaPainter(categorias),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: TemaAplicativo.textLight,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        formatarMoeda(total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: TemaAplicativo.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: _LegendaCategorias(categorias: categorias)),
        ],
      ),
    );
  }
}

class _LegendaCategorias extends StatelessWidget {
  const _LegendaCategorias({required this.categorias});

  final List<_CategoriaResumo> categorias;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: categorias.take(6).map((categoria) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: categoria.cor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  categoria.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TemaAplicativo.textMid,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '${categoria.percentual.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: TemaAplicativo.textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoriaLinha extends StatelessWidget {
  const _CategoriaLinha({required this.entry});

  final _CategoriaResumo entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconePorCategoria(entry.nome), color: entry.cor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.nome,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${entry.percentual.toStringAsFixed(0)}% · ${formatarMoeda(entry.valor)}',
                style: const TextStyle(
                  color: TemaAplicativo.textMid,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: (entry.percentual / 100).clamp(0.0, 1.0),
            minHeight: 7,
            color: entry.cor,
            backgroundColor: TemaAplicativo.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

class _EstadoVazioGrafico extends StatelessWidget {
  const _EstadoVazioGrafico();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: TemaAplicativo.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, color: TemaAplicativo.textLight),
          SizedBox(height: 8),
          Text(
            'Nenhuma despesa cadastrada.',
            style: TextStyle(
              color: TemaAplicativo.textMid,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PizzaPainter extends CustomPainter {
  const _PizzaPainter(this.categorias);

  final List<_CategoriaResumo> categorias;

  @override
  void paint(Canvas canvas, Size size) {
    final total = categorias.fold<double>(0, (sum, item) => sum + item.valor);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    if (total <= 0) {
      paint.color = TemaAplicativo.surfaceAlt;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    var start = -math.pi / 2;
    for (final categoria in categorias) {
      final sweep = categoria.valor / total * math.pi * 2;
      paint.color = categoria.cor;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }

    final divisor = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    start = -math.pi / 2;
    for (final categoria in categorias) {
      final sweep = categoria.valor / total * math.pi * 2;
      final point = Offset(
        center.dx + math.cos(start) * radius,
        center.dy + math.sin(start) * radius,
      );
      canvas.drawLine(center, point, divisor);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter oldDelegate) =>
      oldDelegate.categorias != categorias;
}

class _CategoriaResumo {
  const _CategoriaResumo({
    required this.nome,
    required this.valor,
    required this.percentual,
    required this.cor,
  });

  final String nome;
  final double valor;
  final double percentual;
  final Color cor;
}
