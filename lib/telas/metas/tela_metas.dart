import 'package:flutter/material.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../../componentes/componentes_kazux.dart';
import 'tela_editar_meta.dart';
import 'tela_planejamento_gastos.dart';

class TelaMetas extends StatefulWidget {
  const TelaMetas({super.key});

  @override
  State<TelaMetas> createState() => _TelaMetasState();
}

class _TelaMetasState extends State<TelaMetas> {
  late Future<List<Map<String, dynamic>>> futuro;

  @override
  void initState() {
    super.initState();
    futuro = ServicoBancoDados.getMetas();
  }

  void _reload() {
    setState(() => futuro = ServicoBancoDados.getMetas());
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? meta}) async {
    final salvo = await Navigator.of(
      context,
      rootNavigator: false,
    ).push<bool>(MaterialPageRoute(builder: (_) => TelaEditarMeta(meta: meta)));

    if (salvo == true) {
      _reload();
    }
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> meta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar meta?'),
        content: Text('A meta "${meta['nome']}" será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ServicoBancoDados.removerMeta(meta['id'] as int);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meta apagada.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futuro,
        builder: (context, snapshot) {
          final metas = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CabecalhoKazux(
                  title: 'Metas',
                  subtitle: 'Toque em uma meta para editar ou apagar.',
                  leading: Navigator.canPop(context)
                      ? BotaoIconeKazux(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    CartaoKazux(
                      color: TemaAplicativo.tealDark,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pie_chart_rounded,
                            color: Color(0xFF7EFFD4),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Planejamento de gastos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Defina limites mensais e receba alertas.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Abrir planejamento',
                            onPressed: () {
                              Navigator.of(context, rootNavigator: false).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TelaPlanejamentoGastos(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (metas.isEmpty)
                      const CartaoKazux(
                        child: Center(child: Text('Nenhuma meta cadastrada.')),
                      )
                    else
                      ...metas.map(
                        (meta) => _CartaoMeta(
                          meta: meta,
                          onEdit: () => _abrirFormulario(meta: meta),
                          onDelete: () => _confirmarExclusao(meta),
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

class _CartaoMeta extends StatelessWidget {
  const _CartaoMeta({
    required this.meta,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> meta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final atual = (meta['valorAtual'] as num).toDouble();
    final alvo = (meta['valorAlvo'] as num).toDouble();
    final progresso = alvo == 0 ? 0.0 : (atual / alvo).clamp(0.0, 1.0);
    final prazo = DateTime.tryParse((meta['prazo'] as String?) ?? '');
    final prazoTexto = prazo == null
        ? 'Sem data definida'
        : formatarDataCurta(prazo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: CartaoKazux(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: TemaAplicativo.mint,
                    child: Icon(
                      meta['icone'] == 'flight'
                          ? Icons.flight_takeoff_rounded
                          : Icons.savings_rounded,
                      color: TemaAplicativo.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      meta['nome'] as String,
                      style: const TextStyle(
                        color: TemaAplicativo.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (valor) {
                      if (valor == 'editar') {
                        onEdit();
                      } else if (valor == 'apagar') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'apagar', child: Text('Apagar')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.event_rounded,
                    color: TemaAplicativo.textLight,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Data da meta: $prazoTexto',
                    style: const TextStyle(
                      color: TemaAplicativo.textLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                color: TemaAplicativo.teal,
                backgroundColor: TemaAplicativo.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatarMoeda(atual)} de ${formatarMoeda(alvo)}',
                      style: const TextStyle(color: TemaAplicativo.textLight),
                    ),
                  ),
                  Text(
                    '${(progresso * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: TemaAplicativo.teal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
