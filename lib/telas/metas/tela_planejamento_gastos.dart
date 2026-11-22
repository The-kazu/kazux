import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';

class TelaPlanejamentoGastos extends StatefulWidget {
  const TelaPlanejamentoGastos({super.key});

  @override
  State<TelaPlanejamentoGastos> createState() => _TelaPlanejamentoGastosState();
}

class _TelaPlanejamentoGastosState extends State<TelaPlanejamentoGastos> {
  static const categorias = [
    'Alimentação',
    'Transporte',
    'Saúde',
    'Lazer',
    'Moradia',
    'Educação',
  ];
  late DateTime mes;
  late Future<List<Map<String, dynamic>>> futuro;

  @override
  void initState() {
    super.initState();
    mes = inicioMes(DateTime.now());
    futuro = ServicoBancoDados.getResumoLimitesGastos(mes);
  }

  void _recarregar() {
    setState(() => futuro = ServicoBancoDados.getResumoLimitesGastos(mes));
  }

  double? _lerValor(String texto) {
    final limpo = texto.replaceAll('R\$', '').replaceAll(' ', '');
    if (limpo.contains(',')) {
      return double.tryParse(limpo.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(limpo.replaceAll('.', ''));
  }

  Future<void> _editar([Map<String, dynamic>? limite]) async {
    var categoria = (limite?['categoria'] as String?) ?? categorias.first;
    final valorController = TextEditingController(
      text: limite == null ? '' : (limite['limite'] as num).toStringAsFixed(0),
    );
    final salvou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(limite == null ? 'Criar limite mensal' : 'Editar limite'),
        content: StatefulBuilder(
          builder: (context, atualizar) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: categorias
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: limite != null
                    ? null
                    : (valor) {
                        if (valor != null) {
                          atualizar(() => categoria = valor);
                        }
                      },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                inputFormatters: const [FormatadorMilharKazux()],
                decoration: const InputDecoration(
                  labelText: 'Limite mensal',
                  prefixText: 'R\$ ',
                  suffixText: ',00',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final valor = _lerValor(valorController.text);
              if (valor == null || valor <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe um limite válido.')),
                );
                return;
              }
              await ServicoBancoDados.salvarLimiteGasto(
                categoria: categoria,
                limite: valor,
              );
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    valorController.dispose();
    if (salvou == true) {
      await ServicoBancoDados.avaliarLimitesGastos(mes: mes);
      _recarregar();
    }
  }

  Future<void> _apagar(Map<String, dynamic> item) async {
    await ServicoBancoDados.removerLimiteGasto(item['id'] as int);
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Criar limite',
        onPressed: _editar,
        child: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futuro,
        builder: (context, snapshot) {
          final limites = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CabecalhoKazux(
                  title: 'Planejamento',
                  subtitle: 'Limites de gastos por categoria.',
                  leading: BotaoIconeKazux(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SeletorMesKazux(
                      mes: mes,
                      onAnterior: () {
                        setState(() => mes = somarMeses(mes, -1));
                        _recarregar();
                      },
                      onProximo: () {
                        setState(() => mes = somarMeses(mes, 1));
                        _recarregar();
                      },
                    ),
                    const SizedBox(height: 14),
                    const CartaoKazux(
                      color: TemaAplicativo.tealDark,
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF7EFFD4),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'O Kazux avisa ao chegar em 80% e ao ultrapassar o limite mensal.',
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (limites.isEmpty)
                      const CartaoKazux(
                        child: Text(
                          'Nenhum limite criado. Toque no botão + para planejar seus gastos.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...limites.map(
                        (item) => _CartaoLimite(
                          item: item,
                          onEditar: () => _editar(item),
                          onApagar: () => _apagar(item),
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

class _CartaoLimite extends StatelessWidget {
  const _CartaoLimite({
    required this.item,
    required this.onEditar,
    required this.onApagar,
  });

  final Map<String, dynamic> item;
  final VoidCallback onEditar;
  final VoidCallback onApagar;

  @override
  Widget build(BuildContext context) {
    final gasto = item['gasto'] as double;
    final limite = (item['limite'] as num).toDouble();
    final percentual = (item['percentual'] as double).clamp(0.0, 1.0);
    final excedeu = gasto > limite;
    final cor = excedeu
        ? TemaAplicativo.danger
        : percentual >= 0.8
        ? TemaAplicativo.warning
        : TemaAplicativo.teal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CartaoKazux(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.13),
                  child: Icon(
                    iconePorCategoria(item['categoria'] as String),
                    color: cor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['categoria'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (valor) =>
                      valor == 'editar' ? onEditar() : onApagar(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'apagar', child: Text('Apagar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: percentual,
              minHeight: 8,
              color: cor,
              backgroundColor: TemaAplicativo.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 9),
            Text(
              '${formatarMoeda(gasto)} de ${formatarMoeda(limite)}',
              style: TextStyle(color: cor, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
