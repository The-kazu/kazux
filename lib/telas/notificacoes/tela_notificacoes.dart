import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';

class TelaNotificacoes extends StatefulWidget {
  const TelaNotificacoes({super.key});

  @override
  State<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends State<TelaNotificacoes> {
  late Future<List<Map<String, dynamic>>> futuro;

  @override
  void initState() {
    super.initState();
    futuro = _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    await ServicoBancoDados.avaliarLimitesGastos();
    return ServicoBancoDados.getNotificacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futuro,
        builder: (context, snapshot) {
          final itens = snapshot.data ?? [];
          final naoLidas = itens.where((item) => item['lida'] == 0).length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CabecalhoKazux(
                  title: 'Notificações',
                  subtitle: naoLidas == 0
                      ? 'Você está em dia.'
                      : '$naoLidas aviso${naoLidas == 1 ? '' : 's'} novo${naoLidas == 1 ? '' : 's'}.',
                  leading: BotaoIconeKazux(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  trailing: itens.isEmpty
                      ? null
                      : BotaoIconeKazux(
                          icon: Icons.done_all_rounded,
                          onPressed: () async {
                            await ServicoBancoDados.marcarNotificacoesComoLidas();
                            if (mounted) {
                              setState(() => futuro = _carregar());
                            }
                          },
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(18),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (itens.isEmpty)
                      const CartaoKazux(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 34,
                              color: TemaAplicativo.textLight,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Nenhum alerta por enquanto.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Defina limites em Metas para receber avisos de gastos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: TemaAplicativo.textLight),
                            ),
                          ],
                        ),
                      )
                    else
                      ...itens.map((item) => _CartaoNotificacao(item: item)),
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

class _CartaoNotificacao extends StatelessWidget {
  const _CartaoNotificacao({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final excedido = item['tipo'] == 'limite_excedido';
    final data = DateTime.tryParse((item['criadaEm'] as String?) ?? '');
    final cor = excedido ? TemaAplicativo.danger : TemaAplicativo.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoKazux(
        padding: const EdgeInsets.all(14),
        color: item['lida'] == 0 ? Colors.white : TemaAplicativo.surfaceAlt,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.13),
              child: Icon(
                excedido
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                color: cor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['titulo'] as String,
                    style: const TextStyle(
                      color: TemaAplicativo.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['mensagem'] as String,
                    style: const TextStyle(
                      color: TemaAplicativo.textMid,
                      height: 1.35,
                    ),
                  ),
                  if (data != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      formatarDataCurta(data),
                      style: const TextStyle(
                        color: TemaAplicativo.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
