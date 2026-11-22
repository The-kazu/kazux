import 'package:flutter/material.dart';
import '../../modelos/modelo_transacao.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../../componentes/componentes_kazux.dart';
import '../assistente/tela_assistente.dart';
import '../metas/tela_metas.dart';
import '../notificacoes/tela_notificacoes.dart';
import '../perfil/tela_perfil.dart';
import '../relatorios/tela_relatorios.dart';
import '../transacoes/tela_adicionar_transacao.dart';
import '../transacoes/tela_transacoes.dart';

class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navegadorInternoKey =
      GlobalKey<NavigatorState>();
  late final _ObservadorNavegadorInterno _observadorNavegador;
  int selectedIndex = 0;
  int refreshKey = 0;
  bool subTelaAberta = false;
  late DateTime mesSelecionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    mesSelecionado = inicioMes(DateTime.now());
    _observadorNavegador = _ObservadorNavegadorInterno(_atualizarSubTelaAberta);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _sincronizarMesDoSistema();
    }
  }

  void _sincronizarMesDoSistema() {
    final mesAtualDoSistema = inicioMes(DateTime.now());
    if (mesmoMes(mesSelecionado, mesAtualDoSistema)) {
      return;
    }

    setState(() {
      mesSelecionado = mesAtualDoSistema;
      refreshKey++;
      subTelaAberta = false;
    });

    _navegadorInternoKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _paginaAtual()),
      (_) => false,
    );
  }

  void _refresh() {
    setState(() => refreshKey++);
  }

  void _atualizarSubTelaAberta() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final podeVoltar = _navegadorInternoKey.currentState?.canPop() ?? false;
      if (podeVoltar != subTelaAberta) {
        setState(() => subTelaAberta = podeVoltar);
      }
    });
  }

  Widget _paginaAtual() {
    return switch (selectedIndex) {
      0 => TelaPainel(
        key: ValueKey('painel-$refreshKey'),
        onChanged: _refresh,
        mesSelecionado: mesSelecionado,
        onMesAnterior: () => _alterarMes(-1),
        onMesProximo: () => _alterarMes(1),
        podeVoltarMes: _podeAlterarMes(-1),
        podeAvancarMes: _podeAlterarMes(1),
      ),
      1 => TelaRelatorios(
        key: ValueKey('relatorios-$refreshKey'),
        mesSelecionado: mesSelecionado,
        onMesAnterior: () => _alterarMes(-1),
        onMesProximo: () => _alterarMes(1),
        podeVoltarMes: _podeAlterarMes(-1),
        podeAvancarMes: _podeAlterarMes(1),
      ),
      2 => TelaTransacoes(
        key: ValueKey('transacoes-$refreshKey'),
        onChanged: _refresh,
        mesSelecionado: mesSelecionado,
        onMesAnterior: () => _alterarMes(-1),
        onMesProximo: () => _alterarMes(1),
        podeVoltarMes: _podeAlterarMes(-1),
        podeAvancarMes: _podeAlterarMes(1),
      ),
      3 => const TelaAssistente(),
      _ => TelaPerfil(key: ValueKey('perfil-$refreshKey')),
    };
  }

  bool _podeAlterarMes(int direcao) {
    final atual = inicioMes(DateTime.now());
    final minimo = somarMeses(atual, -12);
    final maximo = somarMeses(atual, 12);
    final alvo = somarMeses(mesSelecionado, direcao);
    return !alvo.isBefore(minimo) && !alvo.isAfter(maximo);
  }

  void _alterarMes(int direcao) {
    if (!_podeAlterarMes(direcao)) {
      return;
    }

    setState(() {
      mesSelecionado = somarMeses(mesSelecionado, direcao);
      refreshKey++;
      subTelaAberta = false;
    });

    _navegadorInternoKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _paginaAtual()),
      (_) => false,
    );
  }

  void _selecionarAba(int index) {
    setState(() {
      selectedIndex = index;
      refreshKey++;
      subTelaAberta = false;
    });

    _navegadorInternoKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _paginaAtual()),
      (_) => false,
    );
  }

  Future<void> _abrirNovaTransacao() async {
    await _navegadorInternoKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => TelaAdicionarTransacao(mesReferencia: mesSelecionado),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: _navegadorInternoKey,
        observers: [_observadorNavegador],
        onGenerateRoute: (_) {
          return MaterialPageRoute(builder: (_) => _paginaAtual());
        },
      ),
      floatingActionButton:
          !subTelaAberta && (selectedIndex == 2 || selectedIndex == 0)
          ? FloatingActionButton(
              onPressed: _abrirNovaTransacao,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: TemaAplicativo.mint,
        onDestinationSelected: _selecionarAba,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_rounded),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transações',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'Assistente',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _ObservadorNavegadorInterno extends NavigatorObserver {
  _ObservadorNavegadorInterno(this.onChanged);

  final VoidCallback onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    onChanged();
  }
}

class TelaPainel extends StatefulWidget {
  const TelaPainel({
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
  State<TelaPainel> createState() => _TelaPainelState();
}

class _TelaPainelState extends State<TelaPainel> {
  late Future<_DadosPainel> futuro;

  @override
  void initState() {
    super.initState();
    futuro = _load();
  }

  Future<_DadosPainel> _load() async {
    final todasTransacoes = await ServicoBancoDados.getTransacoes();
    final contas = await ServicoBancoDados.getContas();
    final metas = await ServicoBancoDados.getMetas();
    final usuario = await ServicoBancoDados.getUsuario();
    final saldoInicial = contas.fold<double>(
      0,
      (sum, conta) => sum + (conta['saldoInicial'] as num).toDouble(),
    );
    final transacoes = todasTransacoes
        .where((transacao) => mesmoMes(transacao.data, widget.mesSelecionado))
        .toList();
    final transacoesAteMes = todasTransacoes
        .where(
          (transacao) => !transacao.data.isAfter(fimMes(widget.mesSelecionado)),
        )
        .toList();
    final receitas = transacoes
        .where((transacao) => transacao.isReceita)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    final despesas = transacoes
        .where((transacao) => transacao.isDespesa)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    final receitasAteMes = transacoesAteMes
        .where((transacao) => transacao.isReceita)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    final despesasAteMes = transacoesAteMes
        .where((transacao) => transacao.isDespesa)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);

    return _DadosPainel(
      usuario: usuario,
      transacoes: transacoes,
      todasTransacoes: todasTransacoes,
      contas: contas,
      metas: metas,
      saldo: saldoInicial + receitasAteMes - despesasAteMes,
      receitas: receitas,
      despesas: despesas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DadosPainel>(
      future: futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        final nome = (data.usuario?['nome'] as String?) ?? 'Usuário';
        final primeiroNome = nome.split(' ').first;
        final limite = data.despesas <= 1200
            ? 'dentro do previsto'
            : 'acima do ideal';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() => futuro = _load());
              await futuro;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: CabecalhoKazux(
                    title: 'Olá, $primeiroNome',
                    subtitle: 'Resumo de ${nomeMesAno(widget.mesSelecionado)}.',
                    trailing: BotaoIconeKazux(
                      icon: Icons.notifications_rounded,
                      onPressed: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder: (_) => const TelaNotificacoes(),
                          ),
                        );
                      },
                    ),
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
                      _BalanceCard(
                        data: data,
                        mesSelecionado: widget.mesSelecionado,
                        onChanged: () {
                          setState(() => futuro = _load());
                          widget.onChanged();
                        },
                      ),
                      const SizedBox(height: 14),
                      CartaoKazux(
                        color: TemaAplicativo.tealDark,
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Análise local: suas despesas estão $limite. Alimentação concentra ${data.percentualCategoria('Alimentação').toStringAsFixed(0)}% dos gastos.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: TituloSecao('Metas em destaque'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: false).push(
                                MaterialPageRoute(
                                  builder: (_) => const TelaMetas(),
                                ),
                              );
                            },
                            child: const Text('Ver todas'),
                          ),
                        ],
                      ),
                      ...data.metas
                          .take(2)
                          .map((meta) => _PreviaMeta(meta: meta)),
                      const SizedBox(height: 22),
                      TituloSecao(
                        'Transações de ${nomeMesAno(widget.mesSelecionado)}',
                      ),
                      if (data.transacoes.isEmpty)
                        const CartaoKazux(
                          child: Center(
                            child: Text('Nenhuma transação cadastrada'),
                          ),
                        )
                      else
                        ...data.transacoes
                            .take(4)
                            .map(
                              (transacao) =>
                                  _ItemTransacao(transacao: transacao),
                            ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.data,
    required this.mesSelecionado,
    required this.onChanged,
  });

  final _DadosPainel data;
  final DateTime mesSelecionado;
  final VoidCallback onChanged;

  void _abrirRelatorioContas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RelatorioContasSheet(data: data),
    );
  }

  Future<void> _abrirAjusteSaldo(
    BuildContext context,
    _ModoAjusteSaldo modo,
  ) async {
    if (data.contas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre uma conta antes de ajustar saldo.'),
        ),
      );
      return;
    }

    final salvou = await Navigator.of(context, rootNavigator: false).push<bool>(
      MaterialPageRoute(
        builder: (_) => _TelaAjusteSaldo(
          data: data,
          mesSelecionado: mesSelecionado,
          modo: modo,
        ),
      ),
    );

    if (salvou == true && context.mounted) {
      onChanged();
      final mensagem = modo == _ModoAjusteSaldo.zerar
          ? 'Saldo da conta zerado.'
          : 'Dinheiro removido da conta.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TemaAplicativo.teal,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saldo total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _abrirRelatorioContas(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: TemaAplicativo.teal,
                          size: 19,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Relatório',
                          style: TextStyle(
                            color: TemaAplicativo.teal,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatarMoeda(data.saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _abrirAjusteSaldo(context, _ModoAjusteSaldo.remover),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  label: const Text('Remover'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _abrirAjusteSaldo(context, _ModoAjusteSaldo.zerar),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Zerar saldo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniBalance(
                  label: 'Receitas',
                  value: data.receitas,
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniBalance(
                  label: 'Despesas',
                  value: data.despesas,
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFFFB0B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ModoAjusteSaldo { remover, zerar }

class _TelaAjusteSaldo extends StatefulWidget {
  const _TelaAjusteSaldo({
    required this.data,
    required this.mesSelecionado,
    required this.modo,
  });

  final _DadosPainel data;
  final DateTime mesSelecionado;
  final _ModoAjusteSaldo modo;

  @override
  State<_TelaAjusteSaldo> createState() => _TelaAjusteSaldoState();
}

class _TelaAjusteSaldoState extends State<_TelaAjusteSaldo> {
  final valorController = TextEditingController();
  final motivoController = TextEditingController(text: 'Retirada de dinheiro');
  late int contaSelecionadaId;

  bool get zerar => widget.modo == _ModoAjusteSaldo.zerar;

  @override
  void initState() {
    super.initState();
    contaSelecionadaId = widget.data.contas.first['id'] as int;
    if (zerar) {
      motivoController.text = 'Zerar saldo da conta';
    }
  }

  @override
  void dispose() {
    valorController.dispose();
    motivoController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get contaSelecionada {
    return widget.data.contas.firstWhere(
      (conta) => conta['id'] == contaSelecionadaId,
      orElse: () => widget.data.contas.first,
    );
  }

  String get nomeContaSelecionada => contaSelecionada['nome'] as String;

  DateTime _dataAjuste() {
    final hoje = DateTime.now();
    if (mesmoMes(hoje, widget.mesSelecionado)) {
      return hoje;
    }
    return DateTime(widget.mesSelecionado.year, widget.mesSelecionado.month, 1);
  }

  double _saldoAtualConta(String nomeConta) {
    final saldoInicial = (contaSelecionada['saldoInicial'] as num).toDouble();
    final transacoesConta = widget.data.todasTransacoes.where(
      (transacao) =>
          transacao.conta == nomeConta &&
          !transacao.data.isAfter(fimMes(widget.mesSelecionado)),
    );
    final entradas = transacoesConta
        .where((transacao) => transacao.isReceita)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    final saidas = transacoesConta
        .where((transacao) => transacao.isDespesa)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    return saldoInicial + entradas - saidas;
  }

  double? _lerValorMonetario(String texto) {
    final limpo = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (limpo.isEmpty) {
      return null;
    }
    if (limpo.contains(',')) {
      return double.tryParse(limpo.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(limpo.replaceAll('.', ''));
  }

  Future<void> _salvar() async {
    final saldoAtual = _saldoAtualConta(nomeContaSelecionada);
    final valor = zerar ? saldoAtual : _lerValorMonetario(valorController.text);
    final motivo = motivoController.text.trim().isEmpty
        ? (zerar ? 'Zerar saldo da conta' : 'Retirada de dinheiro')
        : motivoController.text.trim();

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            zerar ? 'Essa conta já está zerada.' : 'Informe um valor válido.',
          ),
        ),
      );
      return;
    }

    if (valor > saldoAtual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Essa conta tem ${formatarMoeda(saldoAtual)} disponível.',
          ),
        ),
      );
      return;
    }

    await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: motivo,
        valor: valor,
        tipo: 'Despesa',
        categoria: 'Ajuste',
        conta: nomeContaSelecionada,
        data: _dataAjuste(),
      ),
    );

    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final saldoAtual = _saldoAtualConta(nomeContaSelecionada);
    final titulo = zerar ? 'Zerar saldo da conta' : 'Remover dinheiro';
    final subtitulo = zerar
        ? 'Escolha a conta para deixar em R\$ 0,00 no mês selecionado.'
        : 'Registre uma saída rápida na conta escolhida.';

    return Scaffold(
      backgroundColor: TemaAplicativo.teal,
      body: Column(
        children: [
          CabecalhoKazux(
            title: titulo,
            subtitle: subtitulo,
            leading: BotaoIconeKazux(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: TemaAplicativo.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: contaSelecionadaId,
                      decoration: const InputDecoration(
                        labelText: 'Conta',
                        prefixIcon: Icon(Icons.account_balance_rounded),
                      ),
                      items: widget.data.contas.map((conta) {
                        final id = conta['id'] as int;
                        final nome = conta['nome'] as String;
                        final tipo = conta['tipo'] as String;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('$nome - $tipo'),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => contaSelecionadaId = valor);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    CartaoKazux(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      color: TemaAplicativo.surfaceAlt,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: TemaAplicativo.teal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              zerar
                                  ? 'Saldo que será zerado'
                                  : 'Saldo atual em $nomeContaSelecionada',
                              style: const TextStyle(
                                color: TemaAplicativo.textMid,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            formatarMoeda(saldoAtual),
                            style: TextStyle(
                              color: saldoAtual >= 0
                                  ? TemaAplicativo.teal
                                  : TemaAplicativo.danger,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!zerar) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: valorController,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [FormatadorMilharKazux()],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: TemaAplicativo.textDark,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor para remover',
                          prefixText: 'R\$ ',
                          suffixText: ',00',
                          prefixIcon: Icon(Icons.payments_rounded),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: motivoController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        hintText: 'Saque, pagamento, ajuste...',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: Icon(
                        zerar
                            ? Icons.restart_alt_rounded
                            : Icons.remove_rounded,
                      ),
                      label: Text(
                        zerar ? 'Zerar saldo agora' : 'Remover da conta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatorioContasSheet extends StatelessWidget {
  const _RelatorioContasSheet({required this.data});

  final _DadosPainel data;

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = (data.usuario?['nome'] as String?) ?? 'usuário atual';
    final primeiroNome = nomeUsuario.split(' ').first;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: TemaAplicativo.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TemaAplicativo.textLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: TemaAplicativo.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: TemaAplicativo.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relatório de $primeiroNome',
                          style: const TextStyle(
                            color: TemaAplicativo.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Somente dados do usuário logado neste celular.',
                          style: TextStyle(color: TemaAplicativo.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TituloSecao('Contas de $primeiroNome'),
              if (data.contas.isEmpty)
                const CartaoKazux(child: Text('Nenhuma conta cadastrada.'))
              else
                ...data.contas.map(
                  (conta) => _ResumoConta(data: data, conta: conta),
                ),
              const SizedBox(height: 18),
              TituloSecao('Transações de $primeiroNome'),
              if (data.todasTransacoes.isEmpty)
                const CartaoKazux(child: Text('Nenhuma transação cadastrada.'))
              else
                ...data.todasTransacoes.map(
                  (transacao) => _RegistroRelatorioConta(transacao: transacao),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ResumoConta extends StatelessWidget {
  const _ResumoConta({required this.data, required this.conta});

  final _DadosPainel data;
  final Map<String, dynamic> conta;

  @override
  Widget build(BuildContext context) {
    final nome = conta['nome'] as String;
    final tipo = conta['tipo'] as String;
    final saldoInicial = (conta['saldoInicial'] as num).toDouble();
    final transacoesConta = data.todasTransacoes
        .where((transacao) => transacao.conta == nome)
        .toList();
    final entradas = transacoesConta
        .where((transacao) => transacao.isReceita)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    final saidas = transacoesConta
        .where((transacao) => transacao.isDespesa)
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    final saldo = saldoInicial + entradas - saidas;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoKazux(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: TemaAplicativo.mint,
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: TemaAplicativo.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          color: TemaAplicativo.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        tipo,
                        style: const TextStyle(
                          color: TemaAplicativo.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatarMoeda(saldo),
                  style: TextStyle(
                    color: saldo >= 0
                        ? TemaAplicativo.teal
                        : TemaAplicativo.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ResumoContaValor(
                    label: 'Entrou',
                    value: entradas,
                    color: TemaAplicativo.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResumoContaValor(
                    label: 'Saiu',
                    value: saidas,
                    color: TemaAplicativo.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoContaValor extends StatelessWidget {
  const _ResumoContaValor({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TemaAplicativo.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TemaAplicativo.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatarMoeda(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RegistroRelatorioConta extends StatelessWidget {
  const _RegistroRelatorioConta({required this.transacao});

  final ModeloTransacao transacao;

  @override
  Widget build(BuildContext context) {
    final cor = transacao.isReceita
        ? TemaAplicativo.teal
        : corPorCategoria(transacao.categoria);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                    '${formatarDataCurta(transacao.data)} · ${transacao.conta} · ${transacao.categoria}',
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
    );
  }
}

class _MiniBalance extends StatelessWidget {
  const _MiniBalance({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            formatarMoeda(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviaMeta extends StatelessWidget {
  const _PreviaMeta({required this.meta});

  final Map<String, dynamic> meta;

  @override
  Widget build(BuildContext context) {
    final atual = (meta['valorAtual'] as num).toDouble();
    final alvo = (meta['valorAlvo'] as num).toDouble();
    final progresso = alvo == 0 ? 0.0 : (atual / alvo).clamp(0.0, 1.0);
    final prazo = DateTime.tryParse((meta['prazo'] as String?) ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoKazux(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: TemaAplicativo.mint,
                  child: Icon(
                    meta['icone'] == 'flight'
                        ? Icons.flight_takeoff_rounded
                        : Icons.shield_rounded,
                    color: TemaAplicativo.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    meta['nome'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: TemaAplicativo.textDark,
                    ),
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
            if (prazo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.event_rounded,
                    color: TemaAplicativo.textLight,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Prazo: ${formatarDataCurta(prazo)}',
                    style: const TextStyle(
                      color: TemaAplicativo.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progresso,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              color: TemaAplicativo.teal,
              backgroundColor: TemaAplicativo.surfaceAlt,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatarMoeda(atual)} de ${formatarMoeda(alvo)}',
              style: const TextStyle(
                color: TemaAplicativo.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTransacao extends StatelessWidget {
  const _ItemTransacao({required this.transacao});

  final ModeloTransacao transacao;

  @override
  Widget build(BuildContext context) {
    final cor = transacao.isReceita
        ? TemaAplicativo.teal
        : corPorCategoria(transacao.categoria);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                    '${transacao.categoria} · ${transacao.conta}',
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
    );
  }
}

class _DadosPainel {
  const _DadosPainel({
    required this.usuario,
    required this.transacoes,
    required this.todasTransacoes,
    required this.contas,
    required this.metas,
    required this.saldo,
    required this.receitas,
    required this.despesas,
  });

  final Map<String, dynamic>? usuario;
  final List<ModeloTransacao> transacoes;
  final List<ModeloTransacao> todasTransacoes;
  final List<Map<String, dynamic>> contas;
  final List<Map<String, dynamic>> metas;
  final double saldo;
  final double receitas;
  final double despesas;

  double percentualCategoria(String category) {
    if (despesas == 0) {
      return 0;
    }
    final total = transacoes
        .where(
          (transacao) => transacao.isDespesa && transacao.categoria == category,
        )
        .fold<double>(0, (sum, transacao) => sum + transacao.valor);
    return total / despesas * 100;
  }
}
