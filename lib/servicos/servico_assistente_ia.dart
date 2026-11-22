import 'dart:convert';
import 'package:http/http.dart' as http;
import '../componentes/componentes_kazux.dart';
import '../modelos/modelo_transacao.dart';
import 'servico_banco_dados.dart';

class RespostaAssistenteIA {
  const RespostaAssistenteIA({required this.texto, this.acao});

  final String texto;
  final AcaoAssistenteIA? acao;
}

class AcaoAssistenteIA {
  const AcaoAssistenteIA({required this.tipo, required this.dados});

  final String tipo;
  final Map<String, dynamic> dados;

  bool get exigeConfirmacao => tipo != 'nenhuma';

  String get descricao {
    return switch (tipo) {
      'adicionar_transacao' => 'Adicionar a transação "${dados['descricao']}".',
      'apagar_transacao' =>
        'Apagar a transação "${dados['descricao'] ?? 'selecionada'}".',
      'criar_meta' => 'Criar a meta "${dados['nome']}".',
      'criar_limite' => 'Criar ou alterar o limite de ${dados['categoria']}.',
      _ => 'Fazer uma alteração nos seus dados.',
    };
  }
}

class ServicoAssistenteIA {
  ServicoAssistenteIA._();

  static const String _urlPadrao = 'http://127.0.0.1:8787/api/assistente';
  static const String _urlServidor = String.fromEnvironment(
    'KAZUX_IA_URL',
    defaultValue: _urlPadrao,
  );

  static Future<RespostaAssistenteIA> perguntar(String pergunta) async {
    final contexto = await montarContextoFinanceiro();
    final resposta = await http
        .post(
          Uri.parse(_urlServidor),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'mensagem': pergunta, 'contexto': contexto}),
        )
        .timeout(const Duration(seconds: 65));

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception(
        dados['erro']?.toString() ?? 'Não foi possível consultar a IA.',
      );
    }

    final texto = dados['resposta']?.toString().trim() ?? '';
    if (texto.isEmpty) {
      throw Exception('A IA não retornou uma resposta.');
    }
    final tipo = dados['acao']?.toString() ?? 'nenhuma';
    final dadosAcao = dados['dados'] is Map
        ? Map<String, dynamic>.from(dados['dados'] as Map)
        : <String, dynamic>{};
    AcaoAssistenteIA? acao;
    if (tipo != 'nenhuma') {
      try {
        acao = await _validarAcao(
          AcaoAssistenteIA(tipo: tipo, dados: dadosAcao),
        );
      } catch (erro) {
        return RespostaAssistenteIA(
          texto:
              '$texto\n\nNão propus a alteração: ${_mensagemValidacao(erro)}',
        );
      }
    }
    return RespostaAssistenteIA(texto: texto, acao: acao);
  }

  // Executa somente a ação que o usuário aprovou na tela do assistente.
  static Future<String> executarAcao(AcaoAssistenteIA acao) async {
    final acaoValidada = await _validarAcao(acao);
    final dados = acaoValidada.dados;
    switch (acao.tipo) {
      case 'adicionar_transacao':
        final valor = _numero(dados['valor']);
        final tipo = dados['tipo']?.toString();
        final descricao = dados['descricao']?.toString().trim() ?? '';
        final categoria = dados['categoria']?.toString().trim() ?? '';
        final conta = dados['conta']?.toString().trim() ?? '';
        final tipoSeguro = tipo!;
        final data =
            DateTime.tryParse(dados['data']?.toString() ?? '') ??
            DateTime.now();
        await ServicoBancoDados.inserirTransacao(
          ModeloTransacao(
            descricao: descricao,
            valor: valor,
            tipo: tipoSeguro,
            categoria: categoria,
            conta: conta,
            data: data,
          ),
        );
        if (tipoSeguro == 'Despesa') {
          await ServicoBancoDados.avaliarLimitesGastos(mes: data);
        }
        return 'Transação adicionada com sucesso.';
      case 'apagar_transacao':
        final id = int.parse(dados['id_transacao'].toString());
        final removidos = await ServicoBancoDados.removerTransacao(id);
        if (removidos == 0) {
          throw Exception('A transação já não existe nesta conta.');
        }
        return 'Transação apagada com sucesso.';
      case 'criar_meta':
        final nome = dados['nome']?.toString().trim() ?? '';
        final alvo = _numero(dados['valor_alvo']);
        final atual = _numero(dados['valor_atual']);
        final prazo =
            DateTime.tryParse(dados['prazo']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 90));
        await ServicoBancoDados.inserirMeta({
          'nome': nome,
          'valorAlvo': alvo,
          'valorAtual': atual,
          'prazo': prazo.toIso8601String(),
          'icone': 'shield',
          'cor': 'teal',
        });
        return 'Meta criada com sucesso.';
      case 'criar_limite':
        final categoria = dados['categoria']?.toString().trim() ?? '';
        final limite = _numero(dados['limite']);
        await ServicoBancoDados.salvarLimiteGasto(
          categoria: categoria,
          limite: limite,
        );
        await ServicoBancoDados.avaliarLimitesGastos();
        return 'Limite de gastos salvo com sucesso.';
      default:
        throw Exception('Ação solicitada pela IA não é reconhecida.');
    }
  }

  static double _numero(dynamic valor) {
    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;
    return numero.isFinite ? numero : 0;
  }

  static String _mensagemValidacao(Object erro) => erro
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('Bad state: ', '');

  static Future<AcaoAssistenteIA> _validarAcao(AcaoAssistenteIA acao) async {
    final dados = acao.dados;
    switch (acao.tipo) {
      case 'adicionar_transacao':
        final valor = _numero(dados['valor']);
        final tipo = dados['tipo']?.toString();
        final descricao = dados['descricao']?.toString().trim() ?? '';
        final categoria = dados['categoria']?.toString().trim() ?? '';
        final conta = dados['conta']?.toString().trim() ?? '';
        if (valor <= 0 ||
            descricao.isEmpty ||
            categoria.isEmpty ||
            conta.isEmpty ||
            (tipo != 'Receita' && tipo != 'Despesa')) {
          throw Exception('Faltam dados para registrar a transação.');
        }
        final contas = await ServicoBancoDados.getContas();
        if (!contas.any((item) => item['nome'] == conta)) {
          throw Exception('A conta "$conta" não existe para este usuário.');
        }
        break;
      case 'apagar_transacao':
        final id = int.tryParse(dados['id_transacao']?.toString() ?? '');
        if (id == null) {
          throw Exception('Não foi possível identificar a transação.');
        }
        final transacoes = await ServicoBancoDados.getTransacoes();
        final encontrada = transacoes.where((item) => item.id == id);
        if (encontrada.isEmpty) {
          throw Exception('A transação não existe nesta conta.');
        }
        final recentes = transacoes
            .where((item) => !item.data.isAfter(fimMes(DateTime.now())))
            .take(12);
        if (recentes.every((item) => item.id != id)) {
          throw Exception(
            'Só é possível apagar uma transação recente pela IA.',
          );
        }
        return AcaoAssistenteIA(
          tipo: acao.tipo,
          dados: {
            ...dados,
            'id_transacao': id,
            'descricao': encontrada.first.descricao,
          },
        );
      case 'criar_meta':
        final nome = dados['nome']?.toString().trim() ?? '';
        final alvo = _numero(dados['valor_alvo']);
        final atual = _numero(dados['valor_atual']);
        if (nome.isEmpty || alvo <= 0 || atual < 0 || atual > alvo) {
          throw Exception('Os dados da meta são inválidos.');
        }
        break;
      case 'criar_limite':
        final categoria = dados['categoria']?.toString().trim() ?? '';
        final limite = _numero(dados['limite']);
        if (categoria.isEmpty || limite <= 0) {
          throw Exception('Os dados do limite são inválidos.');
        }
        break;
      default:
        throw Exception('Ação solicitada pela IA não é reconhecida.');
    }
    return acao;
  }

  static Future<Map<String, dynamic>> montarContextoFinanceiro() async {
    final agora = DateTime.now();
    final usuario = await ServicoBancoDados.getUsuario();
    final transacoes = await ServicoBancoDados.getTransacoes();
    final metas = await ServicoBancoDados.getMetas();
    final contas = await ServicoBancoDados.getContas();
    final limites = await ServicoBancoDados.getResumoLimitesGastos(agora);
    final notificacoes = await ServicoBancoDados.getNotificacoes();
    final mes = transacoes.where((item) => mesmoMes(item.data, agora)).toList();
    final ateMesAtual = transacoes
        .where((item) => !item.data.isAfter(fimMes(agora)))
        .toList();
    final receitas = _somar(mes.where((item) => item.isReceita));
    final despesas = _somar(mes.where((item) => item.isDespesa));
    final gastosCategoria = <String, double>{};
    final receitasCategoria = <String, double>{};
    final totaisPorMes = <String, Map<String, double>>{};
    final gastosPorMes = <String, Map<String, double>>{};
    final receitasPorMes = <String, Map<String, double>>{};
    for (final item in transacoes) {
      final chaveMes =
          '${item.data.year}-${item.data.month.toString().padLeft(2, '0')}';
      final totais = totaisPorMes.putIfAbsent(
        chaveMes,
        () => {'receitas': 0, 'despesas': 0},
      );
      final tipo = item.isReceita ? 'receitas' : 'despesas';
      totais[tipo] = (totais[tipo] ?? 0) + item.valor;
      final categoriasDoMes = (item.isReceita ? receitasPorMes : gastosPorMes)
          .putIfAbsent(chaveMes, () => {});
      categoriasDoMes[item.categoria] =
          (categoriasDoMes[item.categoria] ?? 0) + item.valor;
      if (!mesmoMes(item.data, agora)) continue;
      final categorias = item.isReceita ? receitasCategoria : gastosCategoria;
      categorias[item.categoria] =
          (categorias[item.categoria] ?? 0) + item.valor;
    }
    final categoriasGastos = gastosCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoriasReceitas = receitasCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final saldoInicial = contas.fold<double>(
      0,
      (total, conta) => total + (conta['saldoInicial'] as num).toDouble(),
    );
    final receitasAteMes = _somar(ateMesAtual.where((item) => item.isReceita));
    final despesasAteMes = _somar(ateMesAtual.where((item) => item.isDespesa));
    final parcelasFuturas = transacoes
        .where(
          (item) =>
              item.isDespesa &&
              item.data.isAfter(fimMes(agora)) &&
              RegExp(r'\(\d+/\d+\)$').hasMatch(item.descricao),
        )
        .toList();
    final historicoMensal = <Map<String, dynamic>>[];
    for (var deslocamento = -12; deslocamento <= 12; deslocamento++) {
      final referencia = somarMeses(agora, deslocamento);
      final chave =
          '${referencia.year}-${referencia.month.toString().padLeft(2, '0')}';
      final totais = totaisPorMes[chave];
      final entrada = totais?['receitas'] ?? 0;
      final saida = totais?['despesas'] ?? 0;
      historicoMensal.add({
        'mes': chave,
        'receitas': entrada,
        'despesas': saida,
        'saldo_do_mes': entrada - saida,
        'receitas_por_categoria': receitasPorMes[chave] ?? {},
        'gastos_por_categoria': gastosPorMes[chave] ?? {},
      });
    }

    return {
      'mes_referencia': nomeMesAno(agora),
      'usuario': (usuario?['nome'] as String?)?.split(' ').first ?? 'Usuário',
      'saldo_total_estimado': saldoInicial + receitasAteMes - despesasAteMes,
      'receitas_mes': receitas,
      'despesas_mes': despesas,
      'saldo_mes': receitas - despesas,
      'contas_disponiveis': contas.map((item) => item['nome']).toList(),
      'contas': contas.take(30).map((conta) {
        final nome = conta['nome'] as String;
        final movimentos = ateMesAtual.where((item) => item.conta == nome);
        final receitasConta = _somar(
          movimentos.where((item) => item.isReceita),
        );
        final despesasConta = _somar(
          movimentos.where((item) => item.isDespesa),
        );
        return {
          'nome': nome,
          'tipo': conta['tipo'],
          'saldo_inicial': conta['saldoInicial'],
          'saldo_ate_mes_atual':
              (conta['saldoInicial'] as num).toDouble() +
              receitasConta -
              despesasConta,
        };
      }).toList(),
      'total_contas': contas.length,
      'maiores_gastos_por_categoria': {
        for (final item in categoriasGastos.take(12)) item.key: item.value,
      },
      'gastos_outras_categorias_mes': _somarValores(
        categoriasGastos.skip(12).map((item) => item.value),
      ),
      'receitas_por_categoria_mes': {
        for (final item in categoriasReceitas.take(12)) item.key: item.value,
      },
      'receitas_outras_categorias_mes': _somarValores(
        categoriasReceitas.skip(12).map((item) => item.value),
      ),
      'historico_mensal': historicoMensal,
      'parcelas_futuras': parcelasFuturas
          .take(24)
          .map(
            (item) => {
              'descricao': item.descricao,
              'valor': item.valor,
              'conta': item.conta,
              'data': item.data.toIso8601String(),
            },
          )
          .toList(),
      'total_parcelas_futuras': parcelasFuturas.length,
      'transacoes_recentes': ateMesAtual
          .take(12)
          .map(
            (item) => {
              'id': item.id,
              'descricao': item.descricao,
              'valor': item.valor,
              'tipo': item.tipo,
              'categoria': item.categoria,
              'conta': item.conta,
              'data': item.data.toIso8601String(),
            },
          )
          .toList(),
      'total_transacoes': transacoes.length,
      'metas': metas
          .take(30)
          .map(
            (meta) => {
              'nome': meta['nome'],
              'valor_atual': meta['valorAtual'],
              'valor_alvo': meta['valorAlvo'],
              'prazo': meta['prazo'],
            },
          )
          .toList(),
      'total_metas': metas.length,
      'limites_de_gastos': limites
          .take(30)
          .map(
            (item) => {
              'categoria': item['categoria'],
              'limite': item['limite'],
              'gasto': item['gasto'],
            },
          )
          .toList(),
      'total_limites': limites.length,
      'notificacoes_nao_lidas': notificacoes
          .where((item) => item['lida'] == 0)
          .length,
      'alertas_recentes': notificacoes
          .take(10)
          .map(
            (item) => {
              'titulo': item['titulo'],
              'categoria': item['categoria'],
              'mes_referencia': item['mesReferencia'],
              'lida': item['lida'] == 1,
            },
          )
          .toList(),
    };
  }

  static double _somarValores(Iterable<double> valores) =>
      valores.fold<double>(0, (total, valor) => total + valor);

  static double _somar(Iterable<ModeloTransacao> transacoes) =>
      transacoes.fold<double>(0, (total, transacao) => total + transacao.valor);
}
