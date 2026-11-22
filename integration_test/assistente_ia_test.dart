import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kazux/modelos/modelo_transacao.dart';
import 'package:kazux/servicos/servico_assistente_ia.dart';
import 'package:kazux/servicos/servico_banco_dados.dart';
import 'package:kazux/telas/inicio/tela_inicio.dart';

const _testeReal = bool.fromEnvironment('KAZUX_TESTE_IA_REAL');

Future<void> _aguardarNaTela(
  WidgetTester tester,
  bool Function() pronto,
) async {
  final limite = DateTime.now().add(const Duration(seconds: 75));
  while (DateTime.now().isBefore(limite)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (pronto()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  final textos = find
      .byType(Text, skipOffstage: false)
      .evaluate()
      .map((elemento) => (elemento.widget as Text).data)
      .whereType<String>()
      .take(30)
      .toList();
  final usuarios = find
      .byKey(const ValueKey('mensagem_usuario'), skipOffstage: false)
      .evaluate()
      .length;
  fail(
    'A resposta da IA não apareceu em 75 segundos. '
    'Mensagens do usuário: $usuarios. Textos na tela: $textos',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'o app iOS consulta a OpenAI pelo servidor local com dados fictícios',
    (tester) async {
      final agora = DateTime.now();
      await ServicoBancoDados.salvarUsuario(
        nome: 'Teste da IA',
        email: 'teste-ia-${agora.microsecondsSinceEpoch}@exemplo.test',
        telefone: '',
        senha: 'senha-teste-ia',
        pin: '564738',
      );
      await ServicoBancoDados.inserirTransacao(
        ModeloTransacao(
          descricao: 'Receita fictícia',
          valor: 1200,
          tipo: 'Receita',
          categoria: 'Salário',
          conta: 'Nubank',
          data: agora,
        ),
      );

      final resposta = await ServicoAssistenteIA.perguntar(
        'Qual é meu saldo estimado? Responda de forma breve.',
      );

      expect(resposta.texto, isNotEmpty);
      expect(resposta.acao, isNull);
    },
    skip: !_testeReal,
  );

  testWidgets('a conversa iOS mostra a resposta real da OpenAI na tela', (
    tester,
  ) async {
    final agora = DateTime.now();
    await ServicoBancoDados.salvarUsuario(
      nome: 'Teste visual da IA',
      email: 'teste-ia-tela-${agora.microsecondsSinceEpoch}@exemplo.test',
      telefone: '',
      senha: 'senha-teste-ia-tela',
      pin: '364829',
    );
    await ServicoBancoDados.inserirTransacao(
      ModeloTransacao(
        descricao: 'Receita fictícia para o teste visual',
        valor: 1200,
        tipo: 'Receita',
        categoria: 'Salário',
        conta: 'Nubank',
        data: agora,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: TelaInicio()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistente').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mensagem_assistente')), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Qual é meu saldo estimado? Responda de forma breve.',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Qual é meu saldo estimado? Responda de forma breve.',
    );
    tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed!();
    await _aguardarNaTela(
      tester,
      () =>
          find.byKey(const ValueKey('mensagem_assistente')).evaluate().length ==
              2 &&
          tester
                  .widget<FloatingActionButton>(
                    find.byType(FloatingActionButton),
                  )
                  .onPressed !=
              null,
    );
    expect(
      find.byKey(const ValueKey('mensagem_erro_assistente')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('mensagem_assistente')), findsNWidgets(2));
    expect(find.text('Confirmar alteração'), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      'Qual é a categoria da minha receita fictícia?',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Qual é a categoria da minha receita fictícia?',
    );
    tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed!();
    await _aguardarNaTela(
      tester,
      () =>
          find.textContaining('Salário').evaluate().isNotEmpty &&
          tester
                  .widget<FloatingActionButton>(
                    find.byType(FloatingActionButton),
                  )
                  .onPressed !=
              null,
    );
    expect(find.textContaining('Salário'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mensagem_erro_assistente')),
      findsNothing,
    );
  }, skip: !_testeReal);

  testWidgets('a ação da IA só altera o limite após confirmação no iOS', (
    tester,
  ) async {
    final agora = DateTime.now();
    await ServicoBancoDados.salvarUsuario(
      nome: 'Teste da confirmação',
      email: 'teste-ia-confirmar-${agora.microsecondsSinceEpoch}@exemplo.test',
      telefone: '',
      senha: 'senha-teste-confirmar',
      pin: '859314',
    );
    await tester.pumpWidget(const MaterialApp(home: TelaInicio()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assistente').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Crie um limite mensal de R\$ 500 para a categoria Alimentação.',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Crie um limite mensal de R\$ 500 para a categoria Alimentação.',
    );
    tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed!();
    await tester.pump();
    expect(
      find.text(
        'Crie um limite mensal de R\$ 500 para a categoria Alimentação.',
      ),
      findsOneWidget,
    );
    await _aguardarNaTela(
      tester,
      () =>
          find.text('Confirmar alteração').evaluate().isNotEmpty ||
          find
              .byKey(const ValueKey('mensagem_erro_assistente'))
              .evaluate()
              .isNotEmpty,
    );
    expect(
      find.byKey(const ValueKey('mensagem_erro_assistente')),
      findsNothing,
    );
    expect(find.text('Confirmar alteração'), findsOneWidget);
    expect(await ServicoBancoDados.getLimitesGastos(), isEmpty);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    final limites = await ServicoBancoDados.getLimitesGastos();
    expect(limites, hasLength(1));
    expect(limites.single['categoria'], 'Alimentação');
    expect(limites.single['limite'], 500);
  }, skip: !_testeReal);
}
