class ModeloTransacao {
  ModeloTransacao({
    this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.categoria,
    required this.conta,
    required this.data,
  });

  final int? id;
  final String descricao;
  final double valor;
  final String tipo;
  final String categoria;
  final String conta;
  final DateTime data;

  bool get isReceita => tipo == 'Receita';
  bool get isDespesa => tipo == 'Despesa';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'categoria': categoria,
      'conta': conta,
      'data': data.toIso8601String(),
    };
  }

  factory ModeloTransacao.fromMap(Map<String, dynamic> map) {
    return ModeloTransacao(
      id: map['id'] as int?,
      descricao: map['descricao'] as String,
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'] as String,
      categoria: map['categoria'] as String,
      conta: (map['conta'] as String?) ?? 'Carteira',
      data: DateTime.tryParse((map['data'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
