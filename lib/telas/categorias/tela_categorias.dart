import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../modelos/modelo_transacao.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';

class TelaCategorias extends StatefulWidget {
  const TelaCategorias({super.key});

  @override
  State<TelaCategorias> createState() => _TelaCategoriasState();
}

class _TelaCategoriasState extends State<TelaCategorias> {
  late Future<List<ModeloTransacao>> futuro;

  static const despesasPadrao = [
    'Alimentação',
    'Transporte',
    'Saúde',
    'Lazer',
    'Moradia',
    'Educação',
  ];
  static const receitasPadrao = ['Salário', 'Freela', 'Investimento'];

  @override
  void initState() {
    super.initState();
    futuro = ServicoBancoDados.getTransacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Categorias personalizadas entram na próxima etapa.',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova'),
      ),
      body: FutureBuilder<List<ModeloTransacao>>(
        future: futuro,
        builder: (context, snapshot) {
          final transacoes = snapshot.data ?? [];
          final despesas = _agrupar(transacoes.where((item) => item.isDespesa));
          final receitas = _agrupar(transacoes.where((item) => item.isReceita));
          final totalDespesas = despesas.values.fold<double>(
            0,
            (s, v) => s + v,
          );
          final totalReceitas = receitas.values.fold<double>(
            0,
            (s, v) => s + v,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CabecalhoKazux(
                  title: 'Categorias',
                  subtitle: 'Organize seus gastos e receitas.',
                  leading: BotaoIconeKazux(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ResumoCategorias(
                      totalReceitas: totalReceitas,
                      totalDespesas: totalDespesas,
                    ),
                    const SizedBox(height: 18),
                    const TituloSecao('Despesas'),
                    ...despesasPadrao.map(
                      (categoria) => _ItemCategoria(
                        categoria: categoria,
                        valor: despesas[categoria] ?? 0,
                        total: totalDespesas,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const TituloSecao('Receitas'),
                    ...receitasPadrao.map(
                      (categoria) => _ItemCategoria(
                        categoria: categoria,
                        valor: receitas[categoria] ?? 0,
                        total: totalReceitas,
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

  Map<String, double> _agrupar(Iterable<ModeloTransacao> itens) {
    final result = <String, double>{};
    for (final item in itens) {
      result[item.categoria] = (result[item.categoria] ?? 0) + item.valor;
    }
    return result;
  }
}

class _ResumoCategorias extends StatelessWidget {
  const _ResumoCategorias({
    required this.totalReceitas,
    required this.totalDespesas,
  });

  final double totalReceitas;
  final double totalDespesas;

  @override
  Widget build(BuildContext context) {
    return CartaoKazux(
      color: TemaAplicativo.tealDark,
      child: Row(
        children: [
          const Icon(Icons.category_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo por categorias',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatarMoeda(totalReceitas)} em receitas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatarMoeda(totalDespesas)} em despesas',
                  style: const TextStyle(
                    color: Color(0xFFFFB0B0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCategoria extends StatelessWidget {
  const _ItemCategoria({
    required this.categoria,
    required this.valor,
    required this.total,
  });

  final String categoria;
  final double valor;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0.0 : (valor / total).clamp(0.0, 1.0);
    final cor = corPorCategoria(categoria);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoKazux(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.13),
              child: Icon(iconePorCategoria(categoria), color: cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoria,
                          style: const TextStyle(
                            color: TemaAplicativo.textDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        formatarMoeda(valor),
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percent,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                    color: cor,
                    backgroundColor: TemaAplicativo.surfaceAlt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
