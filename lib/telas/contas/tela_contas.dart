import 'package:flutter/material.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../../componentes/componentes_kazux.dart';
import 'tela_editar_conta.dart';

class TelaContas extends StatefulWidget {
  const TelaContas({super.key});

  @override
  State<TelaContas> createState() => _TelaContasState();
}

class _TelaContasState extends State<TelaContas> {
  late Future<List<Map<String, dynamic>>> futuro;

  @override
  void initState() {
    super.initState();
    futuro = ServicoBancoDados.getContas();
  }

  void _reload() {
    setState(() => futuro = ServicoBancoDados.getContas());
  }

  Future<void> _editarConta(Map<String, dynamic> conta) async {
    final salvo = await Navigator.of(context, rootNavigator: false).push<bool>(
      MaterialPageRoute(builder: (_) => TelaEditarConta(conta: conta)),
    );

    if (salvo == true) {
      _reload();
    }
  }

  Future<void> _zerarSaldos() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zerar saldos iniciais?'),
        content: const Text(
          'As transações serão mantidas. Apenas o saldo inicial das contas ficará R\$ 0,00.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zerar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ServicoBancoDados.zerarSaldosIniciais();
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saldos iniciais zerados.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futuro,
        builder: (context, snapshot) {
          final contas = snapshot.data ?? [];
          final total = contas.fold<double>(
            0,
            (sum, conta) => sum + (conta['saldoInicial'] as num).toDouble(),
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CabecalhoKazux(
                  title: 'Minhas contas',
                  subtitle:
                      'Edite o saldo inicial usado no cálculo do saldo total.',
                  leading: BotaoIconeKazux(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    CartaoKazux(
                      color: TemaAplicativo.tealDark,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldos iniciais',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatarMoeda(total),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else
                      ...contas.map(
                        (conta) => _CartaoConta(
                          conta: conta,
                          onTap: () => _editarConta(conta),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _zerarSaldos,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Zerar saldos iniciais'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: TemaAplicativo.danger,
                        side: const BorderSide(color: TemaAplicativo.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Kazux, o saldo total é calculado por: saldos iniciais + receitas - despesas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TemaAplicativo.textLight,
                        height: 1.35,
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

class _CartaoConta extends StatelessWidget {
  const _CartaoConta({required this.conta, required this.onTap});

  final Map<String, dynamic> conta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final saldo = (conta['saldoInicial'] as num).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoKazux(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: TemaAplicativo.mint,
              child: Icon(
                Icons.account_balance_rounded,
                color: TemaAplicativo.teal,
              ),
            ),
            title: Text(
              conta['nome'] as String,
              style: const TextStyle(
                color: TemaAplicativo.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(conta['tipo'] as String),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatarMoeda(saldo),
                  style: const TextStyle(
                    color: TemaAplicativo.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'editar',
                  style: TextStyle(
                    color: TemaAplicativo.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
