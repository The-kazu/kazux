import 'package:flutter/material.dart';
import '../../modelos/modelo_transacao.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../servicos/servico_notificacoes_locais.dart';
import '../../tema/tema_aplicativo.dart';
import '../../componentes/componentes_kazux.dart';

class TelaAdicionarTransacao extends StatefulWidget {
  const TelaAdicionarTransacao({super.key, this.mesReferencia});

  final DateTime? mesReferencia;

  @override
  State<TelaAdicionarTransacao> createState() => _TelaAdicionarTransacaoState();
}

class _TelaAdicionarTransacaoState extends State<TelaAdicionarTransacao> {
  final descricaoController = TextEditingController();
  final valorController = TextEditingController();
  String tipo = 'Despesa';
  String categoria = 'Alimentação';
  String conta = 'Nubank';
  List<String> contas = const ['Nubank'];
  bool carregandoContas = true;
  late DateTime data;
  bool compraParcelada = false;
  int parcelas = 2;

  final categoriasDespesa = const [
    'Alimentação',
    'Transporte',
    'Saúde',
    'Lazer',
    'Moradia',
    'Educação',
  ];
  final categoriasReceita = const ['Salário', 'Freela', 'Investimento'];

  @override
  void initState() {
    super.initState();
    final referencia = widget.mesReferencia ?? DateTime.now();
    final hoje = DateTime.now();
    final dia = referencia.year == hoje.year && referencia.month == hoje.month
        ? hoje.day
        : 1;
    data = DateTime(referencia.year, referencia.month, dia);
    _carregarContas();
  }

  @override
  void dispose() {
    descricaoController.dispose();
    valorController.dispose();
    super.dispose();
  }

  Future<void> _carregarContas() async {
    final contasBanco = await ServicoBancoDados.getContas();
    final nomes = <String>[];
    for (final item in contasBanco) {
      final nome = (item['nome'] as String).trim();
      if (nome.isNotEmpty && !nomes.contains(nome)) {
        nomes.add(nome);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      contas = nomes.isEmpty ? ['Nubank'] : nomes;
      if (!contas.contains(conta)) {
        conta = contas.first;
      }
      carregandoContas = false;
    });
  }

  double? _lerValorMonetario(String texto) {
    final limpo = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (limpo.contains(',')) {
      return double.tryParse(limpo.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(limpo.replaceAll('.', ''));
  }

  Future<void> _adicionarConta() async {
    final nomeController = TextEditingController();
    final tipoController = TextEditingController(text: 'Conta corrente');
    final saldoController = TextEditingController(text: '0');

    final novaConta = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar conta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome do banco ou conta',
                    hintText: 'Itaú, Inter, PicPay...',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tipoController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Tipo da conta',
                    hintText: 'Conta corrente, Cartão, Carteira...',
                    prefixIcon: Icon(Icons.label_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: saldoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [FormatadorMilharKazux()],
                  decoration: const InputDecoration(
                    labelText: 'Saldo inicial',
                    prefixText: 'R\$ ',
                    suffixText: ',00',
                    prefixIcon: Icon(Icons.savings_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final nome = nomeController.text.trim();
                final tipo = tipoController.text.trim().isEmpty
                    ? 'Conta corrente'
                    : tipoController.text.trim();
                final saldo = _lerValorMonetario(saldoController.text);

                if (nome.isEmpty || saldo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe o nome e um saldo válido.'),
                    ),
                  );
                  return;
                }

                try {
                  await ServicoBancoDados.inserirConta(
                    nome: nome,
                    tipo: tipo,
                    saldoInicial: saldo,
                  );
                } on StateError catch (erro) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(erro.message)));
                  }
                  return;
                }

                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context, nome);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();
    tipoController.dispose();
    saldoController.dispose();

    if (novaConta == null) {
      return;
    }

    await _carregarContas();
    if (!mounted) {
      return;
    }
    setState(() => conta = novaConta);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Conta $novaConta adicionada.')));
  }

  Future<void> _salvar() async {
    final valor = _lerValorMonetario(valorController.text);

    if (descricaoController.text.trim().isEmpty ||
        valor == null ||
        valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe descrição e um valor válido.')),
      );
      return;
    }

    final totalParcelas = tipo == 'Despesa' && compraParcelada ? parcelas : 1;
    final valorParcela = valor / totalParcelas;
    final descricaoBase = descricaoController.text.trim();

    for (var index = 0; index < totalParcelas; index++) {
      await ServicoBancoDados.inserirTransacao(
        ModeloTransacao(
          descricao: totalParcelas == 1
              ? descricaoBase
              : '$descricaoBase (${index + 1}/$totalParcelas)',
          valor: valorParcela,
          tipo: tipo,
          categoria: categoria,
          conta: conta,
          data: _dataParcela(index),
        ),
      );
    }

    if (tipo == 'Despesa') {
      final alertas = await ServicoBancoDados.avaliarLimitesGastos(mes: data);
      await ServicoNotificacoesLocais.mostrarAlertas(alertas);
    }

    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  DateTime _dataParcela(int index) {
    final mes = DateTime(data.year, data.month + index, 1);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
    final dia = data.day > ultimoDia ? ultimoDia : data.day;
    return DateTime(mes.year, mes.month, dia);
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: data,
      firstDate: DateTime(hoje.year, hoje.month - 12, 1),
      lastDate: DateTime(hoje.year, hoje.month + 12, 31),
    );

    if (selecionada != null) {
      setState(() => data = selecionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categorias = tipo == 'Receita'
        ? categoriasReceita
        : categoriasDespesa;
    if (!categorias.contains(categoria)) {
      categoria = categorias.first;
    }

    return Scaffold(
      backgroundColor: TemaAplicativo.teal,
      body: Column(
        children: [
          CabecalhoKazux(
            title: 'Nova transação',
            subtitle: 'Registre uma receita, despesa ou ajuste.',
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
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Despesa',
                          label: Text('Despesa'),
                          icon: Icon(Icons.arrow_upward_rounded),
                        ),
                        ButtonSegment(
                          value: 'Receita',
                          label: Text('Receita'),
                          icon: Icon(Icons.arrow_downward_rounded),
                        ),
                      ],
                      selected: {tipo},
                      onSelectionChanged: (valor) {
                        setState(() {
                          tipo = valor.first;
                          categoria = tipo == 'Receita'
                              ? categoriasReceita.first
                              : categoriasDespesa.first;
                          if (tipo == 'Receita') {
                            compraParcelada = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: valorController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      inputFormatters: const [FormatadorMilharKazux()],
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: TemaAplicativo.textDark,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        suffixText: ',00',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descricaoController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Mercado, salário, gasolina...',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: categorias
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => categoria = valor);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: contas.contains(conta)
                                ? conta
                                : contas.first,
                            decoration: InputDecoration(
                              labelText: carregandoContas
                                  ? 'Carregando contas...'
                                  : 'Conta',
                              prefixIcon: const Icon(
                                Icons.account_balance_rounded,
                              ),
                            ),
                            items: contas
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: carregandoContas
                                ? null
                                : (valor) {
                                    if (valor != null) {
                                      setState(() => conta = valor);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          width: 56,
                          child: IconButton.filled(
                            onPressed: _adicionarConta,
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Adicionar conta',
                            style: IconButton.styleFrom(
                              backgroundColor: TemaAplicativo.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _selecionarData,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(
                        'Data: ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: TemaAplicativo.teal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (tipo == 'Despesa') ...[
                      CartaoKazux(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: compraParcelada,
                                activeThumbColor: TemaAplicativo.teal,
                                title: const Text(
                                  'Compra parcelada',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                subtitle: const Text(
                                  'Cria parcelas automáticas nos próximos meses.',
                                ),
                                secondary: const Icon(
                                  Icons.credit_card_rounded,
                                  color: TemaAplicativo.teal,
                                ),
                                onChanged: (valor) {
                                  setState(() => compraParcelada = valor);
                                },
                              ),
                            ),
                            if (compraParcelada) ...[
                              const SizedBox(height: 10),
                              DropdownButtonFormField<int>(
                                initialValue: parcelas,
                                decoration: const InputDecoration(
                                  labelText: 'Quantidade de parcelas',
                                  prefixIcon: Icon(Icons.view_week_rounded),
                                ),
                                items: List.generate(11, (index) => index + 2)
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text('${item}x'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (valor) {
                                  if (valor != null) {
                                    setState(() => parcelas = valor);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cada parcela ficará em ${formatarMoeda((_lerValorMonetario(valorController.text) ?? 0) / parcelas)}.',
                                style: const TextStyle(
                                  color: TemaAplicativo.textLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    CartaoKazux(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: TemaAplicativo.teal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sugestão automática: ${_sugestao(descricaoController.text)}',
                              style: const TextStyle(
                                color: TemaAplicativo.textMid,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        compraParcelada && tipo == 'Despesa'
                            ? 'Salvar parcelas'
                            : 'Salvar transação',
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

  String _sugestao(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('uber') || lower.contains('gasolina')) {
      return 'Transporte';
    }
    if (lower.contains('mercado') ||
        lower.contains('ifood') ||
        lower.contains('almoço')) {
      return 'Alimentação';
    }
    if (lower.contains('salário') || lower.contains('freela')) {
      return 'Receita';
    }
    return 'categoria baseada na descrição';
  }
}
