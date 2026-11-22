import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kazux/modelos/modelo_transacao.dart';
import 'package:kazux/servicos/servico_assistente_ia.dart';
import 'package:kazux/servicos/servico_banco_dados.dart';
import 'package:kazux/servicos/servico_tema.dart';
import 'package:kazux/telas/inicio/tela_inicio.dart';
import 'package:kazux/telas/perfil/tela_backup_nuvem.dart';
import 'package:kazux/telas/perfil/tela_perfil.dart';
import 'package:kazux/telas/relatorios/tela_relatorios.dart';
import 'package:kazux/telas/transacoes/tela_adicionar_transacao.dart';
import 'package:kazux/telas/transacoes/tela_transacoes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('contas, PIN e dados financeiros ficam isolados no iOS', (
    tester,
  ) async {
    final sufixo = DateTime.now().microsecondsSinceEpoch;
    final emailA = 'auditoria-a-$sufixo@exemplo.test';
    final emailNovoA = 'auditoria-a-novo-$sufixo@exemplo.test';
    final emailB = 'auditoria-b-$sufixo@exemplo.test';
    final hoje = DateTime.now();

    await ServicoBancoDados.salvarUsuario(
      nome: 'Usuário A',
      email: emailA,
      telefone: '',
      senha: 'senha-forte-a',
      pin: '481592',
    );
    final usuarioA = await ServicoBancoDados.getUsuario();
    final idA = usuarioA!['id'];
    expect(await ServicoBancoDados.validarPin('481592'), isTrue);
    expect(await ServicoBancoDados.validarPin('123456'), isFalse);
    expect(await ServicoBancoDados.getTransacoes(), isEmpty);
    expect(await ServicoBancoDados.getMetas(), isEmpty);
    expect(
      (await ServicoBancoDados.getContas()).every(
        (conta) => (conta['saldoInicial'] as num) == 0,
      ),
      isTrue,
    );

    final transacaoId = await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Compra de teste',
        valor: 125.50,
        tipo: 'Despesa',
        categoria: 'Alimentação',
        conta: 'Nubank',
        data: hoje,
      ),
    );
    await ServicoBancoDados.inserirMeta({
      'nome': 'Reserva de teste',
      'valorAlvo': 1000.0,
      'valorAtual': 100.0,
      'prazo': hoje.add(const Duration(days: 90)).toIso8601String(),
      'icone': 'shield',
      'cor': 'teal',
    });
    await ServicoBancoDados.salvarLimiteGasto(
      categoria: 'Alimentação',
      limite: 200,
    );
    final limites = await ServicoBancoDados.getResumoLimitesGastos(hoje);
    expect(limites.single['gasto'], 125.50);
    expect(limites.single['percentual'], closeTo(0.6275, 0.0001));

    await expectLater(
      ServicoBancoDados.salvarUsuario(
        nome: 'Outro usuário',
        email: emailA.toUpperCase(),
        telefone: '',
        senha: 'outra-senha',
        pin: '123987',
      ),
      throwsStateError,
    );
    expect((await ServicoBancoDados.getUsuario())!['id'], idA);
    expect((await ServicoBancoDados.getTransacoes()).length, 1);

    await ServicoBancoDados.salvarUsuario(
      nome: 'Usuário B',
      email: emailB,
      telefone: '',
      senha: 'senha-forte-b',
      pin: '739204',
    );
    expect(await ServicoBancoDados.getTransacoes(), isEmpty);
    expect(await ServicoBancoDados.getMetas(), isEmpty);
    expect(await ServicoBancoDados.getLimitesGastos(), isEmpty);
    expect(await ServicoBancoDados.validarPin('481592'), isFalse);

    expect(
      await ServicoBancoDados.validarLogin(
        email: emailA,
        senha: 'senha-errada',
      ),
      isFalse,
    );
    expect(
      await ServicoBancoDados.validarLogin(
        email: emailA,
        senha: 'senha-forte-a',
      ),
      isTrue,
    );
    expect((await ServicoBancoDados.getTransacoes()).single.id, transacaoId);
    expect((await ServicoBancoDados.getMetas()).length, 1);

    await ServicoBancoDados.atualizarPerfil(
      nome: 'Usuário A Editado',
      email: emailNovoA,
      telefone: '123',
    );
    expect((await ServicoBancoDados.getUsuario())!['id'], idA);
    expect((await ServicoBancoDados.getTransacoes()).length, 1);
    await expectLater(
      ServicoBancoDados.atualizarPerfil(
        nome: 'Conflito',
        email: emailB,
        telefone: '',
      ),
      throwsStateError,
    );
    expect((await ServicoBancoDados.getUsuario())!['email'], emailNovoA);

    final nubank = (await ServicoBancoDados.getContas()).singleWhere(
      (conta) => conta['nome'] == 'Nubank',
    );
    await ServicoBancoDados.atualizarConta(
      id: nubank['id'] as int,
      nome: 'Banco de teste',
      tipo: nubank['tipo'] as String,
      saldoInicial: 500,
    );
    expect(
      (await ServicoBancoDados.getTransacoes()).single.conta,
      'Banco de teste',
    );
    await expectLater(
      ServicoBancoDados.atualizarConta(
        id: nubank['id'] as int,
        nome: 'Carteira',
        tipo: 'Conta corrente',
        saldoInicial: 500,
      ),
      throwsStateError,
    );

    await ServicoBancoDados.removerTransacao(transacaoId);
    expect(await ServicoBancoDados.getTransacoes(), isEmpty);
    expect(
      await ServicoBancoDados.validarLogin(
        email: emailNovoA,
        senha: 'senha-forte-a',
      ),
      isTrue,
    );
  });

  testWidgets('relatórios alternam entre barras e pizza com gastos reais', (
    tester,
  ) async {
    final hoje = DateTime.now();
    final sufixo = hoje.microsecondsSinceEpoch;
    await ServicoBancoDados.salvarUsuario(
      nome: 'Gráficos',
      email: 'graficos-$sufixo@exemplo.test',
      telefone: '',
      senha: 'senha-graficos',
      pin: '286419',
    );
    for (final categoria in ['Alimentação', 'Transporte']) {
      await ServicoBancoDados.inserirTransacao(
        ModeloTransacao(
          descricao: 'Gasto $categoria',
          valor: categoria == 'Alimentação' ? 100 : 50,
          tipo: 'Despesa',
          categoria: categoria,
          conta: 'Nubank',
          data: hoje,
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: TelaRelatorios(
          mesSelecionado: hoje,
          onMesAnterior: () {},
          onMesProximo: () {},
          podeVoltarMes: true,
          podeAvancarMes: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('palitos')), findsOneWidget);
    expect(find.text('Alimentação'), findsWidgets);
    expect(find.text('Transporte'), findsWidgets);

    await tester.tap(find.text('Pizza'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pizza')), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('ações da IA respeitam contas e transações do usuário ativo', (
    tester,
  ) async {
    final sufixo = DateTime.now().microsecondsSinceEpoch;
    await ServicoBancoDados.salvarUsuario(
      nome: 'Usuário da IA A',
      email: 'ia-a-$sufixo@exemplo.test',
      telefone: '',
      senha: 'senha-ia-a',
      pin: '135790',
    );
    final idA = await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Despesa protegida',
        valor: 42,
        tipo: 'Despesa',
        categoria: 'Lazer',
        conta: 'Nubank',
        data: DateTime.now(),
      ),
    );

    await ServicoBancoDados.salvarUsuario(
      nome: 'Usuário da IA B',
      email: 'ia-b-$sufixo@exemplo.test',
      telefone: '',
      senha: 'senha-ia-b',
      pin: '246801',
    );
    await expectLater(
      ServicoAssistenteIA.executarAcao(
        AcaoAssistenteIA(
          tipo: 'apagar_transacao',
          dados: {'id_transacao': idA, 'descricao': 'Despesa protegida'},
        ),
      ),
      throwsException,
    );
    await expectLater(
      ServicoAssistenteIA.executarAcao(
        const AcaoAssistenteIA(
          tipo: 'adicionar_transacao',
          dados: {
            'descricao': 'Não registrar',
            'valor': 25,
            'tipo': 'Despesa',
            'categoria': 'Lazer',
            'conta': 'Banco inexistente',
          },
        ),
      ),
      throwsException,
    );
    expect(await ServicoBancoDados.getTransacoes(), isEmpty);

    await ServicoAssistenteIA.executarAcao(
      const AcaoAssistenteIA(
        tipo: 'adicionar_transacao',
        dados: {
          'descricao': 'Despesa autorizada',
          'valor': 25,
          'tipo': 'Despesa',
          'categoria': 'Lazer',
          'conta': 'Nubank',
        },
      ),
    );
    final idB = (await ServicoBancoDados.getTransacoes()).single.id!;
    await ServicoAssistenteIA.executarAcao(
      AcaoAssistenteIA(
        tipo: 'apagar_transacao',
        dados: {'id_transacao': idB, 'descricao': 'Nome inventado'},
      ),
    );
    expect(await ServicoBancoDados.getTransacoes(), isEmpty);
    expect(
      await ServicoBancoDados.validarLogin(
        email: 'ia-a-$sufixo@exemplo.test',
        senha: 'senha-ia-a',
      ),
      isTrue,
    );
    expect((await ServicoBancoDados.getTransacoes()).single.id, idA);
  });

  testWidgets('resumo da IA acompanha saldo, parcelas e relatórios do app', (
    tester,
  ) async {
    final hoje = DateTime.now();
    final email = 'ia-resumo-${hoje.microsecondsSinceEpoch}@exemplo.test';
    await ServicoBancoDados.salvarUsuario(
      nome: 'Resumo de teste',
      email: email,
      telefone: '',
      senha: 'senha-resumo',
      pin: '314159',
    );
    await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Pagamento fictício',
        valor: 1000,
        tipo: 'Receita',
        categoria: 'Salário',
        conta: 'Nubank',
        data: hoje,
      ),
    );
    await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Mercado fictício',
        valor: 100,
        tipo: 'Despesa',
        categoria: 'Alimentação',
        conta: 'Nubank',
        data: hoje,
      ),
    );
    final proximoMes = DateTime(hoje.year, hoje.month + 1, 5);
    await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Compra fictícia (2/2)',
        valor: 50,
        tipo: 'Despesa',
        categoria: 'Lazer',
        conta: 'Nubank',
        data: proximoMes,
      ),
    );

    final contexto = await ServicoAssistenteIA.montarContextoFinanceiro();
    expect(contexto['saldo_total_estimado'], 900);
    expect(contexto['receitas_mes'], 1000);
    expect(contexto['despesas_mes'], 100);
    expect(contexto['contas'], isNotEmpty);
    expect((contexto['contas'] as List).first['saldo_ate_mes_atual'], 900);
    expect(contexto['receitas_por_categoria_mes'], {'Salário': 1000});
    expect(contexto['maiores_gastos_por_categoria'], {'Alimentação': 100});
    expect(contexto['total_parcelas_futuras'], 1);
    final historico = contexto['historico_mensal'] as List;
    expect(historico, hasLength(25));
    expect(historico[12]['saldo_do_mes'], 900);
    expect(historico[13]['despesas'], 50);
    expect(historico[13]['gastos_por_categoria'], {'Lazer': 50});
    expect(
      (contexto['transacoes_recentes'] as List).every(
        (item) => item['descricao'] != 'Compra fictícia (2/2)',
      ),
      isTrue,
    );
    final conteudo = jsonEncode(contexto);
    expect(conteudo, isNot(contains(email)));
    expect(conteudo, isNot(contains('senha-resumo')));
    expect(conteudo, isNot(contains('314159')));
  });

  testWidgets(
    'compra parcelada pela tela cria lançamentos em meses seguintes',
    (tester) async {
      final agora = DateTime.now();
      await ServicoBancoDados.salvarUsuario(
        nome: 'Parcelas de teste',
        email: 'parcelas-${agora.microsecondsSinceEpoch}@exemplo.test',
        telefone: '',
        senha: 'senha-parcelas',
        pin: '864213',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TelaAdicionarTransacao(),
                  ),
                ),
                child: const Text('Abrir transação'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir transação'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '1200');
      await tester.enterText(
        find.byType(TextField).at(1),
        'Compra parcelada teste',
      );
      await tester.ensureVisible(find.text('Compra parcelada'));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('2x'), findsOneWidget);
      final seletor = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(
        seletor.items!.map((item) => item.value),
        containsAll(List.generate(11, (index) => index + 2)),
      );
      seletor.onChanged!(12);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar parcelas'));
      await tester.tap(find.text('Salvar parcelas'));
      await tester.pumpAndSettle();

      final transacoes = await ServicoBancoDados.getTransacoes();
      expect(transacoes, hasLength(12));
      expect(transacoes.map((item) => item.valor), everyElement(100));
      expect(
        transacoes.map((item) => item.descricao),
        containsAll([
          'Compra parcelada teste (1/12)',
          'Compra parcelada teste (12/12)',
        ]),
      );
      expect(
        transacoes.map((item) => item.data.month),
        containsAll([
          agora.month,
          DateTime(agora.year, agora.month + 11).month,
        ]),
      );
    },
  );

  testWidgets('metas editam e apagam; alertas respeitam limite mensal', (
    tester,
  ) async {
    final agora = DateTime.now();
    await ServicoBancoDados.salvarUsuario(
      nome: 'Planejamento de teste',
      email: 'planejamento-${agora.microsecondsSinceEpoch}@exemplo.test',
      telefone: '',
      senha: 'senha-planejamento',
      pin: '235711',
    );
    final prazo = agora.add(const Duration(days: 60)).toIso8601String();
    final idMeta = await ServicoBancoDados.inserirMeta({
      'nome': 'Viagem de teste',
      'valorAlvo': 2000.0,
      'valorAtual': 100.0,
      'prazo': prazo,
      'icone': 'flight',
      'cor': 'teal',
    });
    await ServicoBancoDados.atualizarMeta(
      id: idMeta,
      meta: {
        'nome': 'Viagem atualizada',
        'valorAlvo': 2500.0,
        'valorAtual': 200.0,
        'prazo': prazo,
        'icone': 'flight',
        'cor': 'teal',
      },
    );
    expect(
      (await ServicoBancoDados.getMetas()).single['nome'],
      'Viagem atualizada',
    );
    await ServicoBancoDados.removerMeta(idMeta);
    expect(await ServicoBancoDados.getMetas(), isEmpty);

    await ServicoBancoDados.salvarLimiteGasto(
      categoria: 'Alimentação',
      limite: 100,
    );
    await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Mercado 1',
        valor: 85,
        tipo: 'Despesa',
        categoria: 'Alimentação',
        conta: 'Nubank',
        data: agora,
      ),
    );
    final alertasAtencao = await ServicoBancoDados.avaliarLimitesGastos();
    expect(alertasAtencao.single['tipo'], 'limite_atencao');
    expect(await ServicoBancoDados.avaliarLimitesGastos(), isEmpty);
    await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Mercado 2',
        valor: 20,
        tipo: 'Despesa',
        categoria: 'Alimentação',
        conta: 'Nubank',
        data: agora,
      ),
    );
    final alertasExcesso = await ServicoBancoDados.avaliarLimitesGastos();
    expect(alertasExcesso.single['tipo'], 'limite_excedido');
    expect((await ServicoBancoDados.getNotificacoes()).length, 2);
  });

  testWidgets('tema escuro e claro persistem após recarregar preferência', (
    tester,
  ) async {
    final modoAnterior = ServicoTema.modo.value;
    try {
      await ServicoTema.alterar(ThemeMode.dark);
      await ServicoTema.carregar();
      expect(ServicoTema.modo.value, ThemeMode.dark);
      await ServicoTema.alterar(ThemeMode.light);
      await ServicoTema.carregar();
      expect(ServicoTema.modo.value, ThemeMode.light);
    } finally {
      await ServicoTema.alterar(modoAnterior);
    }
  });

  testWidgets('cinco abas e backup mantêm a navegação inferior', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TelaInicio()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Relatórios').last);
    await tester.pumpAndSettle();
    expect(find.byType(TelaRelatorios), findsOneWidget);

    await tester.tap(find.text('Transações').last);
    await tester.pumpAndSettle();
    expect(find.byType(TelaTransacoes), findsOneWidget);

    await tester.tap(find.text('Assistente').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Assistente Financeiro'), findsWidgets);

    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(find.byType(TelaPerfil), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Backup em nuvem'),
      280,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Backup em nuvem'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaBackupNuvem), findsOneWidget);
    expect(find.text('Backup automático'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('backup local restaura dados sem expor senha ou PIN', (
    tester,
  ) async {
    final agora = DateTime.now();
    await ServicoBancoDados.salvarUsuario(
      nome: 'Backup de teste',
      email: 'backup-${agora.microsecondsSinceEpoch}@exemplo.test',
      telefone: '',
      senha: 'senha-nao-enviar',
      pin: '905314',
    );
    final id = await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Receita para restaurar',
        valor: 250,
        tipo: 'Receita',
        categoria: 'Freela',
        conta: 'Nubank',
        data: agora,
      ),
    );
    final dados = await ServicoBancoDados.exportarDadosParaBackup();
    final conteudo = jsonEncode(dados);
    expect(conteudo, isNot(contains('senha-nao-enviar')));
    expect(conteudo, isNot(contains('905314')));

    await ServicoBancoDados.removerTransacao(id);
    expect(await ServicoBancoDados.getTransacoes(), isEmpty);
    await ServicoBancoDados.restaurarDadosDoBackup(dados);
    expect(
      (await ServicoBancoDados.getTransacoes()).single.descricao,
      'Receita para restaurar',
    );
    expect((await ServicoBancoDados.getContas()).length, 3);

    await expectLater(
      ServicoBancoDados.restaurarDadosDoBackup({
        ...dados,
        'transacoes': [
          {'descricao': 'Registro incompleto'},
        ],
      }),
      throwsA(anything),
    );
    expect(
      (await ServicoBancoDados.getTransacoes()).single.descricao,
      'Receita para restaurar',
    );
  });
}
