import 'package:flutter_test/flutter_test.dart';
import 'package:kazux/modelos/modelo_transacao.dart';

void main() {
  final data = DateTime.utc(2026, 11, 27);
  ModeloTransacao transacao(String tipo) => ModeloTransacao(
    id: 1, descricao: 'Exemplo', valor: 100, tipo: tipo,
    categoria: 'Geral', conta: 'Carteira', data: data);
  Map<String, dynamic> mapa() => transacao('Receita').toMap();

  test('Receita é classificada corretamente', () {
    expect(transacao('Receita').isReceita, isTrue);
    expect(transacao('Receita').isDespesa, isFalse);
  });
  test('Despesa é classificada corretamente', () {
    expect(transacao('Despesa').isDespesa, isTrue);
    expect(transacao('Despesa').isReceita, isFalse);
  });
  test('Tipo desconhecido não é receita nem despesa', () {
    expect(transacao('').isReceita, isFalse);
    expect(transacao('').isDespesa, isFalse);
  });
  test('Serialização preserva os campos', () {
    expect(mapa(), {'id': 1, 'descricao': 'Exemplo', 'valor': 100.0,
      'tipo': 'Receita', 'categoria': 'Geral', 'conta': 'Carteira',
      'data': data.toIso8601String()});
  });
  test('Desserialização preserva a transação', () {
    expect(ModeloTransacao.fromMap(mapa()).toMap(), mapa());
  });
  test('Conta ausente usa Carteira', () {
    expect(ModeloTransacao.fromMap(mapa()..remove('conta')).conta, 'Carteira');
  });
  test('Valor inteiro é convertido em double', () {
    expect(ModeloTransacao.fromMap(mapa()..['valor'] = 42).valor, 42.0);
  });
  test('Valor de tipo inválido gera exceção', () {
    expect(() => ModeloTransacao.fromMap(mapa()..['valor'] = 'abc'),
      throwsA(isA<TypeError>()));
  });
}
