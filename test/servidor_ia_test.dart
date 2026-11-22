import 'package:flutter_test/flutter_test.dart';
import '../servidor_ia/servidor_ia.dart';

void main() {
  test('lê o texto da resposta HTTP da OpenAI após itens de raciocínio', () {
    final texto = extrairTextoRespostaOpenAI({
      'output': [
        {'type': 'reasoning', 'summary': []},
        {
          'type': 'message',
          'content': [
            {
              'type': 'output_text',
              'text': '{"resposta":"Olá!","acao":"nenhuma","dados":"{}"}',
            },
          ],
        },
      ],
    });

    expect(texto, '{"resposta":"Olá!","acao":"nenhuma","dados":"{}"}');
  });

  test('resposta sem mensagem de texto é rejeitável', () {
    expect(extrairTextoRespostaOpenAI({'output': []}), isEmpty);
  });

  test('recusa da OpenAI é identificada sem propor ação', () {
    final recusa = extrairRecusaRespostaOpenAI({
      'output': [
        {
          'type': 'message',
          'content': [
            {'type': 'refusal', 'refusal': 'Não posso ajudar com isso.'},
          ],
        },
      ],
    });

    expect(recusa, 'Não posso ajudar com isso.');
  });

  test('erro da API não devolve detalhes sensíveis ao aplicativo', () {
    final erro = erroDaOpenAI(401, {
      'error': {
        'code': 'invalid_api_key',
        'message': 'Chave secreta de exemplo',
      },
    });

    expect(erro.mensagem, contains('chave'));
    expect(erro.mensagem, isNot(contains('secreta')));
  });

  test('falta de créditos recebe uma mensagem específica', () {
    final erro = erroDaOpenAI(429, {
      'error': {'code': 'credit_balance_exhausted'},
    });

    expect(erro.mensagem, contains('créditos'));
  });
}
