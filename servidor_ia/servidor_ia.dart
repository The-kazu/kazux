import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ErroAssistente implements Exception {
  const ErroAssistente(this.status, this.mensagem);

  final int status;
  final String mensagem;
}

/// Servidor local do Kazux.
/// A chave da OpenAI fica apenas aqui, nunca dentro do aplicativo Flutter.
Future<void> main() async {
  final configuracao = await _lerConfiguracao();
  final chave = configuracao['OPENAI_API_KEY']?.trim() ?? '';
  final modelo = configuracao['OPENAI_MODEL']?.trim().isNotEmpty == true
      ? configuracao['OPENAI_MODEL']!.trim()
      : 'gpt-5.4-mini';
  final porta = int.tryParse(configuracao['PORT'] ?? '') ?? 8787;

  if (chave.isEmpty) {
    stderr.writeln(
      'Chave não encontrada. Crie o arquivo servidor_ia/.env e cole OPENAI_API_KEY nele.',
    );
    exitCode = 1;
    return;
  }

  final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, porta);
  stdout.writeln('IA do Kazux pronta em http://127.0.0.1:$porta');

  await for (final requisicao in servidor) {
    await _tratarRequisicao(requisicao, chave: chave, modelo: modelo);
  }
}

Future<Map<String, String>> _lerConfiguracao() async {
  final arquivo = File('${Directory.current.path}/servidor_ia/.env');
  if (!await arquivo.exists()) {
    return {};
  }

  final configuracao = <String, String>{};
  for (final linha in await arquivo.readAsLines()) {
    final texto = linha.trim();
    if (texto.isEmpty || texto.startsWith('#') || !texto.contains('=')) {
      continue;
    }
    final separador = texto.indexOf('=');
    configuracao[texto.substring(0, separador).trim()] = texto
        .substring(separador + 1)
        .trim();
  }
  return configuracao;
}

Future<void> _tratarRequisicao(
  HttpRequest requisicao, {
  required String chave,
  required String modelo,
}) async {
  _cabecalhos(requisicao.response);

  if (requisicao.headers.value('origin') != null) {
    await _responderErro(
      requisicao.response,
      HttpStatus.forbidden,
      'Esta rota aceita apenas o aplicativo local.',
    );
    return;
  }

  if (requisicao.method != 'POST' || requisicao.uri.path != '/api/assistente') {
    await _responderErro(
      requisicao.response,
      HttpStatus.notFound,
      'Rota não encontrada.',
    );
    return;
  }
  if (requisicao.headers.contentType?.mimeType != ContentType.json.mimeType) {
    await _responderErro(
      requisicao.response,
      HttpStatus.unsupportedMediaType,
      'Envie os dados em JSON.',
    );
    return;
  }

  try {
    final corpo = await _lerCorpo(requisicao);
    final decodificado = jsonDecode(corpo);
    if (decodificado is! Map<String, dynamic>) {
      throw const ErroAssistente(HttpStatus.badRequest, 'JSON inválido.');
    }
    final mensagem = (decodificado['mensagem'] as String? ?? '').trim();
    final contexto = decodificado['contexto'];

    if (mensagem.isEmpty || mensagem.length > 600) {
      await _responderErro(
        requisicao.response,
        HttpStatus.badRequest,
        'Envie uma pergunta entre 1 e 600 caracteres.',
      );
      return;
    }
    if (contexto is! Map<String, dynamic>) {
      throw const ErroAssistente(
        HttpStatus.badRequest,
        'Resumo financeiro inválido.',
      );
    }

    final respostaOpenAI = await _consultarOpenAI(
      chave: chave,
      modelo: modelo,
      mensagem: mensagem,
      contexto: contexto,
    );
    await _responderJson(requisicao.response, HttpStatus.ok, respostaOpenAI);
  } on ErroAssistente catch (erro) {
    await _responderErro(requisicao.response, erro.status, erro.mensagem);
  } on FormatException {
    await _responderErro(
      requisicao.response,
      HttpStatus.badRequest,
      'JSON inválido.',
    );
  } catch (erro) {
    stderr.writeln('Falha na consulta da IA: ${erro.runtimeType}');
    await _responderErro(
      requisicao.response,
      HttpStatus.badGateway,
      'Não foi possível consultar a IA agora. Tente novamente.',
    );
  }
}

Future<String> _lerCorpo(HttpRequest requisicao) async {
  const limiteBytes = 64 * 1024;
  if (requisicao.contentLength > limiteBytes) {
    throw const ErroAssistente(
      HttpStatus.requestEntityTooLarge,
      'O resumo enviado é grande demais.',
    );
  }
  final bytes = BytesBuilder(copy: false);
  await for (final parte in requisicao) {
    if (bytes.length + parte.length > limiteBytes) {
      throw const ErroAssistente(
        HttpStatus.requestEntityTooLarge,
        'O resumo enviado é grande demais.',
      );
    }
    bytes.add(parte);
  }
  return utf8.decode(bytes.takeBytes());
}

Future<Map<String, dynamic>> _consultarOpenAI({
  required String chave,
  required String modelo,
  required String mensagem,
  required Map<String, dynamic> contexto,
}) async {
  final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final requisicao = await cliente.postUrl(
      Uri.parse('https://api.openai.com/v1/responses'),
    );
    requisicao.headers.contentType = ContentType.json;
    requisicao.headers.set(HttpHeaders.authorizationHeader, 'Bearer $chave');

    final instrucao =
        '''
Você é o Assistente Financeiro do Kazux, um aplicativo brasileiro de controle financeiro pessoal.
Responda em português do Brasil, com linguagem clara, acolhedora e objetiva.
Use somente o resumo financeiro recebido; não invente valores, transações ou informações.
Ajude com organização financeira, economia, leitura de gastos e metas.
Não dê recomendações de investimento personalizadas, não peça senhas e não trate sua resposta como aconselhamento profissional.
Quando faltar informação, diga isso de forma direta e sugira registrar transações.
Limite a resposta a no máximo 220 palavras.
O saldo_total_estimado e os saldos das contas seguem a tela inicial: incluem os lançamentos até o fim do mês atual, mas não as parcelas de meses futuros.
Use historico_mensal para comparar os 12 meses anteriores, o mês atual e os 12 seguintes. Meses futuros são planejamento, não gastos já realizados.
Use contas, receitas_por_categoria_mes, maiores_gastos_por_categoria, metas, limites_de_gastos, parcelas_futuras e alertas_recentes para responder sobre cada parte financeira do aplicativo.
As listas de contas, metas, limites, parcelas e transações recentes podem estar resumidas. Os campos total_* mostram o tamanho real; não diga que listou tudo se houver itens omitidos.
Se o usuário pedir detalhes não presentes no resumo, diga que não há informação suficiente; nunca invente registros.

Você pode PROPOR uma ação apenas quando o pedido do usuário for claro. As ações permitidas são:
- adicionar_transacao: dados JSON com descricao, valor, tipo (Receita ou Despesa), categoria, conta e data ISO.
- apagar_transacao: dados JSON com id_transacao e descricao; use somente um id presente em transacoes_recentes.
- criar_meta: dados JSON com nome, valor_alvo, valor_atual e prazo ISO.
- criar_limite: dados JSON com categoria e limite.
Nunca invente conta, valor, categoria, data ou id. Quando algum dado necessário faltar, faça uma pergunta e use a ação nenhuma.
Uma ação proposta só será aplicada após a confirmação na tela do usuário.
Retorne o campo dados como texto JSON válido. Quando a ação for nenhuma, dados deve ser {}.

Resumo financeiro do usuário:
${jsonEncode(contexto)}
''';

    requisicao.write(
      jsonEncode({
        'model': modelo,
        'instructions': instrucao,
        'input': mensagem,
        'store': false,
        'max_output_tokens': 750,
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'resposta_assistente_kazux',
            'strict': true,
            'schema': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'resposta': {'type': 'string'},
                'acao': {
                  'type': 'string',
                  'enum': [
                    'nenhuma',
                    'adicionar_transacao',
                    'apagar_transacao',
                    'criar_meta',
                    'criar_limite',
                  ],
                },
                'dados': {'type': 'string'},
              },
              'required': ['resposta', 'acao', 'dados'],
            },
          },
        },
      }),
    );

    final resposta = await requisicao.close().timeout(
      const Duration(seconds: 50),
    );
    final corpo = await utf8.decoder
        .bind(resposta)
        .join()
        .timeout(const Duration(seconds: 50));
    Map<String, dynamic> dados;
    try {
      dados = jsonDecode(corpo) as Map<String, dynamic>;
    } catch (_) {
      throw const ErroAssistente(
        HttpStatus.badGateway,
        'A OpenAI retornou uma resposta inválida.',
      );
    }
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw erroDaOpenAI(resposta.statusCode, dados);
    }
    if (dados['status'] != 'completed') {
      throw const ErroAssistente(
        HttpStatus.badGateway,
        'A resposta da IA ficou incompleta. Tente uma pergunta mais curta.',
      );
    }
    final recusa = extrairRecusaRespostaOpenAI(dados);
    if (recusa.isNotEmpty) {
      return {
        'resposta': recusa,
        'acao': 'nenhuma',
        'dados': <String, dynamic>{},
      };
    }

    final texto = extrairTextoRespostaOpenAI(dados);
    if (texto.isEmpty) {
      throw const ErroAssistente(
        HttpStatus.badGateway,
        'A IA não retornou uma resposta. Tente novamente.',
      );
    }
    Map<String, dynamic> respostaEstruturada;
    try {
      respostaEstruturada = jsonDecode(texto) as Map<String, dynamic>;
    } catch (_) {
      throw const ErroAssistente(
        HttpStatus.badGateway,
        'A IA retornou uma resposta inválida. Tente novamente.',
      );
    }
    final acao = respostaEstruturada['acao']?.toString() ?? 'nenhuma';
    final dadosAcao = respostaEstruturada['dados']?.toString().trim() ?? '{}';
    Map<String, dynamic> dadosSeguros = {};
    try {
      final decodificado = jsonDecode(dadosAcao);
      if (decodificado is Map) {
        dadosSeguros = Map<String, dynamic>.from(decodificado);
      }
    } catch (_) {
      if (acao != 'nenhuma') {
        throw const ErroAssistente(
          HttpStatus.badGateway,
          'A IA retornou dados de alteração inválidos.',
        );
      }
    }
    return {
      'resposta': respostaEstruturada['resposta']?.toString().trim() ?? '',
      'acao': acao,
      'dados': dadosSeguros,
    };
  } finally {
    cliente.close(force: true);
  }
}

ErroAssistente erroDaOpenAI(int status, Map<String, dynamic> dados) {
  final erro = dados['error'];
  final codigo = erro is Map ? erro['code']?.toString() : null;
  stderr.writeln('OpenAI respondeu HTTP $status (${codigo ?? 'sem código'}).');
  if (status == HttpStatus.unauthorized || status == HttpStatus.forbidden) {
    return const ErroAssistente(
      HttpStatus.badGateway,
      'A chave da OpenAI é inválida ou não tem permissão.',
    );
  }
  if (codigo == 'credit_balance_exhausted' || codigo == 'insufficient_quota') {
    return const ErroAssistente(
      HttpStatus.badGateway,
      'Os créditos da API acabaram. Verifique a cobrança na OpenAI.',
    );
  }
  if (status == HttpStatus.tooManyRequests) {
    return const ErroAssistente(
      HttpStatus.badGateway,
      'Muitas consultas à IA. Aguarde um pouco e tente novamente.',
    );
  }
  if (codigo == 'model_not_found') {
    return const ErroAssistente(
      HttpStatus.badGateway,
      'O modelo configurado não está disponível para esta chave.',
    );
  }
  return const ErroAssistente(
    HttpStatus.badGateway,
    'A OpenAI não conseguiu responder agora. Tente novamente.',
  );
}

String extrairTextoRespostaOpenAI(Map<String, dynamic> resposta) {
  final output = resposta['output'];
  if (output is! List) {
    return '';
  }
  final partes = <String>[];
  for (final item in output) {
    if (item is! Map || item['type'] != 'message') {
      continue;
    }
    final content = item['content'];
    if (content is! List) {
      continue;
    }
    for (final parte in content) {
      if (parte is Map && parte['type'] == 'output_text') {
        final texto = parte['text'];
        if (texto is String && texto.isNotEmpty) {
          partes.add(texto);
        }
      }
    }
  }
  return partes.join('\n').trim();
}

String extrairRecusaRespostaOpenAI(Map<String, dynamic> resposta) {
  final output = resposta['output'];
  if (output is! List) return '';
  for (final item in output) {
    if (item is! Map || item['type'] != 'message') continue;
    final content = item['content'];
    if (content is! List) continue;
    for (final parte in content) {
      if (parte is Map && parte['type'] == 'refusal') {
        return parte['refusal']?.toString().trim() ?? '';
      }
    }
  }
  return '';
}

void _cabecalhos(HttpResponse resposta) {
  resposta.headers.contentType = ContentType.json;
}

Future<void> _responderJson(
  HttpResponse resposta,
  int status,
  Map<String, dynamic> dados,
) async {
  resposta.statusCode = status;
  resposta.write(jsonEncode(dados));
  await resposta.close();
}

Future<void> _responderErro(
  HttpResponse resposta,
  int status,
  String mensagem,
) {
  return _responderJson(resposta, status, {'erro': mensagem});
}
