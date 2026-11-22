import 'package:flutter/material.dart';
import '../../modelos/modelo_transacao.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../../componentes/componentes_kazux.dart';

class TelaTransacoes extends StatefulWidget {
  const TelaTransacoes({
    super.key,
    required this.onChanged,
    required this.mesSelecionado,
    required this.onMesAnterior,
    required this.onMesProximo,
    required this.podeVoltarMes,
    required this.podeAvancarMes,
  });

  final VoidCallback onChanged;
  final DateTime mesSelecionado;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesProximo;
  final bool podeVoltarMes;
  final bool podeAvancarMes;

  @override
  State<TelaTransacoes> createState() => _TelaTransacoesState();
}

class _TelaTransacoesState extends State<TelaTransacoes> {
  late Future<List<ModeloTransacao>> futuro;
  String filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    futuro = ServicoBancoDados.getTransacoes();
  }

  void _reload() {
    setState(() => futuro = ServicoBancoDados.getTransacoes());
    widget.onChanged();
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
          final filtradas = filtro == 'Todas'
              ? transacoes
              : transacoes.where((item) => item.tipo == filtro).toList();
          final receitas = transacoes
              .where((item) => item.isReceita)
              .fold<double>(0, (sum, item) => sum + item.valor);
          final despesas = transacoes
              .where((item) => item.isDespesa)
              .fold<double>(0, (sum, item) => sum + item.valor);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CabecalhoKazux(
                  title: 'Transações',
                  subtitle:
                      'Movimentações de ${nomeMesAno(widget.mesSelecionado)}.',
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
                          child: _SummaryBox(
                            label: 'Receitas',
                            value: receitas,
                            color: TemaAplicativo.teal,
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryBox(
                            label: 'Despesas',
                            value: despesas,
                            color: TemaAplicativo.danger,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Todas', label: Text('Todas')),
                        ButtonSegment(
                          value: 'Receita',
                          label: Text('Receitas'),
                        ),
                        ButtonSegment(
                          value: 'Despesa',
                          label: Text('Despesas'),
                        ),
                      ],
                      selected: {filtro},
                      onSelectionChanged: (valor) {
                        setState(() => filtro = valor.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (filtradas.isEmpty)
                      const CartaoKazux(
                        child: Center(
                          child: Text('Nenhuma transação neste mês.'),
                        ),
                      )
                    else
                      ...filtradas.map(
                        (transacao) => _LinhaTransacao(
                          transacao: transacao,
                          onDelete: () async {
                            if (transacao.id != null) {
                              await ServicoBancoDados.removerTransacao(
                                transacao.id!,
                              );
                              _reload();
                            }
                          },
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CartaoKazux(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: TemaAplicativo.textLight)),
          const SizedBox(height: 4),
          Text(
            formatarMoeda(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaTransacao extends StatelessWidget {
  const _LinhaTransacao({required this.transacao, required this.onDelete});

  final ModeloTransacao transacao;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cor = transacao.isReceita
        ? TemaAplicativo.teal
        : corPorCategoria(transacao.categoria);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(transacao.id ?? transacao.descricao),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: TemaAplicativo.danger,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: CartaoKazux(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cor.withValues(alpha: 0.13),
                child: Icon(iconePorCategoria(transacao.categoria), color: cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transacao.descricao,
                      style: const TextStyle(
                        color: TemaAplicativo.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transacao.categoria} · ${transacao.conta} · ${transacao.data.day.toString().padLeft(2, '0')}/${transacao.data.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: TemaAplicativo.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${transacao.isReceita ? '+' : '-'}${formatarMoeda(transacao.valor)}',
                style: TextStyle(
                  color: transacao.isReceita
                      ? TemaAplicativo.teal
                      : TemaAplicativo.danger,
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
