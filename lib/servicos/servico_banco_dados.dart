// Junta caminhos de arquivos de forma correta no macOS, iOS, Android e outros sistemas.
import 'package:path/path.dart';
// Pacote usado para criar e acessar o banco SQLite local do aplicativo.
import 'package:sqflite/sqflite.dart';
// Modelo usado para transformar transações em dados que o banco consegue salvar.
import '../modelos/modelo_transacao.dart';

// Classe central que concentra todas as operações do banco local do Kazux.
class ServicoBancoDados {
  // Email usado na conta de demonstração que já vem pronta para a apresentação.
  static const String emailDemonstracao = 'demo@kazux.example';
  // Senha padrão da conta de demonstração.
  static const String _senhaPadrao = '123456';
  // Guarda a conexão aberta com o banco para o app não abrir várias conexões repetidas.
  static Database? _database;

  // O backup automático observa apenas mudanças nos dados que fazem parte da cópia.
  static Future<void> Function(int usuarioId)? aoAlterarDadosFinanceiros;

  static Future<void> _avisarAlteracao(int usuarioId) async {
    final callback = aoAlterarDadosFinanceiros;
    if (callback != null) await callback(usuarioId);
  }

  // Entrega a conexão do banco; se ainda não existe, cria uma nova.
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB();
    return _database!;
  }

  // Cria ou abre o arquivo físico kazux.db dentro da área de dados do aplicativo.
  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'kazux.db');

    return openDatabase(
      path,
      // Versão do banco; quando aumenta, o app executa as migrações necessárias.
      version: 6,
      // Executado apenas na primeira vez que o banco é criado no aparelho.
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
      // Executado quando o app encontra um banco antigo e precisa atualizar a estrutura.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
        if (oldVersion < 3) {
          await _migrateToV3(db);
        }
        if (oldVersion < 4) {
          await _migrateToV4(db);
        }
        if (oldVersion < 5) {
          await _migrateToV5(db);
        }
        if (oldVersion < 6) {
          await _migrateToV6(db);
        }
      },
    );
  }

  // Cria as tabelas principais: usuários, contas, transações e metas.
  static Future<void> _createSchema(Database db) async {
    // Tabela de usuários: salva nome, email, senha, PIN e qual conta está ativa.
    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        telefone TEXT,
        senha TEXT NOT NULL DEFAULT '123456',
        pin TEXT,
        ativo INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabela de contas financeiras: Nubank, Carteira, Investimentos e seus saldos iniciais.
    await db.execute('''
      CREATE TABLE contas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        saldoInicial REAL NOT NULL DEFAULT 0
      )
    ''');

    // Tabela de transações: salva receitas e despesas ligadas ao usuário ativo.
    await db.execute('''
      CREATE TABLE transacoes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        categoria TEXT NOT NULL,
        conta TEXT NOT NULL DEFAULT 'Carteira',
        data TEXT NOT NULL
      )
    ''');

    // Tabela de metas: salva objetivos financeiros, valores e progresso.
    await db.execute('''
      CREATE TABLE metas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        valorAlvo REAL NOT NULL,
        valorAtual REAL NOT NULL,
        prazo TEXT NOT NULL,
        icone TEXT NOT NULL,
        cor TEXT NOT NULL
      )
    ''');

    await _criarTabelasPlanejamento(db);
  }

  // Limites mensais por categoria e avisos gerados pelo próprio aplicativo.
  static Future<void> _criarTabelasPlanejamento(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS limites_gastos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        limite REAL NOT NULL,
        UNIQUE(usuarioId, categoria)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notificacoes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuarioId INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        tipo TEXT NOT NULL,
        categoria TEXT,
        mesReferencia TEXT,
        criadaEm TEXT NOT NULL,
        lida INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS indice_alerta_limite_unico
      ON notificacoes(usuarioId, tipo, categoria, mesReferencia)
    ''');
  }

  // Migração V2: adiciona campos antigos que faltavam nas transações e cria tabelas faltantes.
  static Future<void> _migrateToV2(Database db) async {
    final colunas = await db.rawQuery('PRAGMA table_info(transacoes)');
    final nomes = colunas.map((column) => column['name']).toSet();

    if (!nomes.contains('conta')) {
      await db.execute(
        "ALTER TABLE transacoes ADD COLUMN conta TEXT NOT NULL DEFAULT 'Carteira'",
      );
    }
    if (!nomes.contains('data')) {
      await db.execute(
        "ALTER TABLE transacoes ADD COLUMN data TEXT NOT NULL DEFAULT '${DateTime.now().toIso8601String()}'",
      );
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        telefone TEXT,
        senha TEXT NOT NULL DEFAULT '123456',
        pin TEXT,
        ativo INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        saldoInicial REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS metas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valorAlvo REAL NOT NULL,
        valorAtual REAL NOT NULL,
        prazo TEXT NOT NULL,
        icone TEXT NOT NULL,
        cor TEXT NOT NULL
      )
    ''');

    await _seedIfEmpty(db);
  }

  // Migração V3: garante que usuários antigos tenham senha salva.
  static Future<void> _migrateToV3(Database db) async {
    final colunas = await db.rawQuery('PRAGMA table_info(usuarios)');
    final nomes = colunas.map((column) => column['name']).toSet();
    if (!nomes.contains('senha')) {
      await db.execute(
        "ALTER TABLE usuarios ADD COLUMN senha TEXT NOT NULL DEFAULT '123456'",
      );
    }

    await db.update('usuarios', {
      'email': emailDemonstracao,
      'senha': _senhaPadrao,
    }, where: 'id = (SELECT id FROM usuarios ORDER BY id ASC LIMIT 1)');
  }

  // Migração V4: adiciona o campo ativo para separar qual usuário está logado.
  static Future<void> _migrateToV4(Database db) async {
    final colunas = await db.rawQuery('PRAGMA table_info(usuarios)');
    final nomes = colunas.map((column) => column['name']).toSet();
    if (!nomes.contains('ativo')) {
      await db.execute(
        'ALTER TABLE usuarios ADD COLUMN ativo INTEGER NOT NULL DEFAULT 0',
      );
    }

    final ativos = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM usuarios WHERE ativo = 1'),
    );
    if (ativos == 0) {
      await db.update(
        'usuarios',
        {'ativo': 1},
        where: 'id = (SELECT id FROM usuarios ORDER BY id DESC LIMIT 1)',
      );
    }
  }

  // Migração V5: liga contas, transações e metas ao usuário correto pelo usuarioId.
  static Future<void> _migrateToV5(Database db) async {
    final usuarioId = await _idUsuarioAtivo(db);
    await _adicionarUsuarioIdSePrecisar(db, 'contas', usuarioId);
    await _adicionarUsuarioIdSePrecisar(db, 'transacoes', usuarioId);
    await _adicionarUsuarioIdSePrecisar(db, 'metas', usuarioId);
    await _garantirContasPadrao(db, usuarioId: usuarioId, saldoDemo: false);
  }

  // Migração V6: inclui planejamento de gastos e central de notificações.
  static Future<void> _migrateToV6(Database db) =>
      _criarTabelasPlanejamento(db);

  // Adiciona usuarioId em tabelas antigas para impedir mistura de dados entre contas.
  static Future<void> _adicionarUsuarioIdSePrecisar(
    Database db,
    String tabela,
    int usuarioId,
  ) async {
    final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
    final nomes = colunas.map((column) => column['name']).toSet();
    if (!nomes.contains('usuarioId')) {
      await db.execute(
        'ALTER TABLE $tabela ADD COLUMN usuarioId INTEGER NOT NULL DEFAULT 0',
      );
    }
    await db.update(tabela, {'usuarioId': usuarioId}, where: 'usuarioId = 0');
  }

  // Se o banco estiver vazio, cria a estrutura mínima para o app funcionar.
  static Future<void> _seedIfEmpty(Database db) async {
    final usuarios = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM usuarios'),
    );
    if (usuarios == 0) {
      final usuarioId = await _idUsuarioAtivo(db);
      await _adicionarUsuarioIdSePrecisar(db, 'contas', usuarioId);
      await _adicionarUsuarioIdSePrecisar(db, 'transacoes', usuarioId);
      await _adicionarUsuarioIdSePrecisar(db, 'metas', usuarioId);
      await _garantirContasPadrao(db, usuarioId: usuarioId, saldoDemo: false);
    }
  }

  // Preenche o banco novo com dados de demonstração para facilitar a apresentação do TCC.
  static Future<void> _seed(Database db) async {
    final usuarioId = await db.insert('usuarios', {
      'nome': 'Usuário de demonstração',
      'email': emailDemonstracao,
      'telefone': '',
      'senha': _senhaPadrao,
      'pin': '123456',
      'ativo': 1,
    });

    await _garantirContasPadrao(db, usuarioId: usuarioId, saldoDemo: true);

    final now = DateTime.now();
    final exemplos = [
      ModeloTransacao(
        descricao: 'Salário',
        valor: 4000,
        tipo: 'Receita',
        categoria: 'Salário',
        conta: 'Nubank',
        data: now.subtract(const Duration(days: 1)),
      ),
      ModeloTransacao(
        descricao: 'Freela mobile',
        valor: 2400,
        tipo: 'Receita',
        categoria: 'Freela',
        conta: 'Nubank',
        data: now.subtract(const Duration(days: 4)),
      ),
      ModeloTransacao(
        descricao: 'iFood',
        valor: 45.90,
        tipo: 'Despesa',
        categoria: 'Alimentação',
        conta: 'Nubank',
        data: now,
      ),
      ModeloTransacao(
        descricao: 'Gasolina',
        valor: 120,
        tipo: 'Despesa',
        categoria: 'Transporte',
        conta: 'Nubank',
        data: now.subtract(const Duration(days: 1)),
      ),
      ModeloTransacao(
        descricao: 'Academia',
        valor: 89.90,
        tipo: 'Despesa',
        categoria: 'Saúde',
        conta: 'Nubank',
        data: now.subtract(const Duration(days: 2)),
      ),
      ModeloTransacao(
        descricao: 'Aluguel',
        valor: 800,
        tipo: 'Despesa',
        categoria: 'Moradia',
        conta: 'Nubank',
        data: now.subtract(const Duration(days: 3)),
      ),
      ModeloTransacao(
        descricao: 'Netflix',
        valor: 55.90,
        tipo: 'Despesa',
        categoria: 'Lazer',
        conta: 'Nubank',
        data: now.subtract(const Duration(days: 4)),
      ),
      ModeloTransacao(
        descricao: 'Curso online',
        valor: 60,
        tipo: 'Despesa',
        categoria: 'Educação',
        conta: 'Nubank',
        data: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final transacao in exemplos) {
      await db.insert('transacoes', {
        ...transacao.toMap(),
        'usuarioId': usuarioId,
      });
    }

    await db.insert('metas', {
      'usuarioId': usuarioId,
      'nome': 'Viagem Europa',
      'valorAlvo': 6000.0,
      'valorAtual': 3720.0,
      'prazo': DateTime(now.year, 12, 20).toIso8601String(),
      'icone': 'flight',
      'cor': 'info',
    });
    await db.insert('metas', {
      'usuarioId': usuarioId,
      'nome': 'Reserva de Emergência',
      'valorAlvo': 12000.0,
      'valorAtual': 10080.0,
      'prazo': DateTime(now.year + 1, 3, 10).toIso8601String(),
      'icone': 'shield',
      'cor': 'teal',
    });
  }

  // Busca o id do usuário logado; se não existir, ativa ou cria um usuário padrão.
  static Future<int> _idUsuarioAtivo(Database db) async {
    final usuariosAtivos = await db.query(
      'usuarios',
      where: 'ativo = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );
    if (usuariosAtivos.isNotEmpty) {
      final usuarioId = usuariosAtivos.first['id'] as int;
      // Proteção extra: se um banco antigo deixou mais de um usuário ativo,
      // mantém só o mais recente para os relatórios não misturarem contas.
      await db.update(
        'usuarios',
        {'ativo': 0},
        where: 'id != ?',
        whereArgs: [usuarioId],
      );
      return usuarioId;
    }

    final usuarios = await db.query('usuarios', orderBy: 'id DESC', limit: 1);
    if (usuarios.isNotEmpty) {
      final id = usuarios.first['id'] as int;
      await db.update('usuarios', {'ativo': 0});
      await db.update(
        'usuarios',
        {'ativo': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }

    return db.insert('usuarios', {
      'nome': 'Usuário de demonstração',
      'email': emailDemonstracao,
      'telefone': '',
      'senha': _senhaPadrao,
      'pin': '123456',
      'ativo': 1,
    });
  }

  // Retorna os dados do usuário ativo para telas de perfil, login e segurança.
  static Future<Map<String, dynamic>?> getUsuario() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final usuarios = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [usuarioId],
      limit: 1,
    );
    return usuarios.isEmpty ? null : usuarios.first;
  }

  // Confere se o PIN digitado é igual ao PIN salvo no banco para o usuário ativo.
  static Future<bool> validarPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin.trim())) {
      return false;
    }
    final usuario = await getUsuario();
    final pinSalvo = usuario?['pin'] as String?;
    return pinSalvo != null && pinSalvo == pin.trim();
  }

  // Atualiza o PIN de segurança do usuário ativo.
  static Future<void> atualizarPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin.trim())) {
      throw ArgumentError('O PIN deve ter exatamente 6 números.');
    }
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    await db.update(
      'usuarios',
      {'pin': pin.trim()},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  // Cria uma conta nova sem substituir dados de um email já cadastrado.
  static Future<void> salvarUsuario({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String pin,
  }) async {
    final db = await database;
    final emailNormalizado = email.trim().toLowerCase();
    final usuarioId = await db.transaction<int>((txn) async {
      final existentes = await txn.query(
        'usuarios',
        where: 'LOWER(email) = ?',
        whereArgs: [emailNormalizado],
        limit: 1,
      );
      if (existentes.isNotEmpty) {
        throw StateError('Este email já está cadastrado. Entre na sua conta.');
      }
      await txn.update('usuarios', {'ativo': 0});
      return txn.insert('usuarios', {
        'nome': nome.trim(),
        'email': emailNormalizado,
        'telefone': telefone.trim(),
        'senha': senha,
        'pin': pin,
        'ativo': 1,
      });
    });
    await _garantirContasPadrao(db, usuarioId: usuarioId, saldoDemo: false);
  }

  // Edita apenas o perfil da conta ativa; senha, PIN e dados financeiros permanecem.
  static Future<void> atualizarPerfil({
    required String nome,
    required String email,
    required String telefone,
  }) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final emailNormalizado = email.trim().toLowerCase();
    await db.transaction((txn) async {
      final existentes = await txn.query(
        'usuarios',
        where: 'LOWER(email) = ? AND id != ?',
        whereArgs: [emailNormalizado, usuarioId],
        limit: 1,
      );
      if (existentes.isNotEmpty) {
        throw StateError('Este email pertence a outra conta.');
      }
      await txn.update(
        'usuarios',
        {
          'nome': nome.trim(),
          'email': emailNormalizado,
          'telefone': telefone.trim(),
        },
        where: 'id = ?',
        whereArgs: [usuarioId],
      );
    });
  }

  // Apaga transações e metas do usuário ativo e zera os saldos das contas.
  static Future<void> limparDadosFinanceiros() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    await db.delete(
      'transacoes',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
    await db.delete('metas', where: 'usuarioId = ?', whereArgs: [usuarioId]);
    await db.update(
      'contas',
      {'saldoInicial': 0.0},
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
    await _avisarAlteracao(usuarioId);
  }

  // Valida email e senha; quando encontra o usuário, marca ele como conta ativa.
  static Future<bool> validarLogin({
    required String email,
    required String senha,
  }) async {
    final db = await database;
    final emailDigitado = email.trim().toLowerCase();
    final senhaDigitada = senha.trim();

    final usuarios = await db.query(
      'usuarios',
      where: 'LOWER(email) = ? AND senha = ?',
      whereArgs: [emailDigitado, senhaDigitada],
      limit: 1,
    );
    if (usuarios.isEmpty) {
      return false;
    }

    final usuarioId = usuarios.first['id'] as int;
    await db.update('usuarios', {'ativo': 0});
    await db.update(
      'usuarios',
      {'ativo': 1},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
    await _garantirContasPadrao(db, usuarioId: usuarioId, saldoDemo: false);
    return true;
  }

  // Garante que todo usuário tenha as três contas principais do app.
  static Future<void> _garantirContasPadrao(
    Database db, {
    required int usuarioId,
    required bool saldoDemo,
  }) async {
    final quantidade = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM contas WHERE usuarioId = ?', [
        usuarioId,
      ]),
    );
    if ((quantidade ?? 0) > 0) {
      return;
    }

    final saldos = saldoDemo
        ? {'Nubank': 4200.0, 'Carteira': 320.0, 'Investimentos': 2200.0}
        : {'Nubank': 0.0, 'Carteira': 0.0, 'Investimentos': 0.0};

    await db.insert('contas', {
      'usuarioId': usuarioId,
      'nome': 'Nubank',
      'tipo': 'Conta corrente',
      'saldoInicial': saldos['Nubank'],
    });
    await db.insert('contas', {
      'usuarioId': usuarioId,
      'nome': 'Carteira',
      'tipo': 'Dinheiro',
      'saldoInicial': saldos['Carteira'],
    });
    await db.insert('contas', {
      'usuarioId': usuarioId,
      'nome': 'Investimentos',
      'tipo': 'Reserva',
      'saldoInicial': saldos['Investimentos'],
    });
  }

  // Lista as contas financeiras do usuário ativo.
  static Future<List<Map<String, dynamic>>> getContas() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    await _garantirContasPadrao(db, usuarioId: usuarioId, saldoDemo: false);
    return db.query(
      'contas',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'id ASC',
    );
  }

  // Cria uma nova conta/banco para o usuário ativo usar nas transações.
  static Future<int> inserirConta({
    required String nome,
    required String tipo,
    double saldoInicial = 0,
  }) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final nomeLimpo = nome.trim();
    final id = await db.transaction<int>((txn) async {
      final existente = await txn.query(
        'contas',
        where: 'usuarioId = ? AND LOWER(nome) = ?',
        whereArgs: [usuarioId, nomeLimpo.toLowerCase()],
        limit: 1,
      );
      if (existente.isNotEmpty) {
        throw StateError('Já existe uma conta com esse nome.');
      }
      return txn.insert('contas', {
        'usuarioId': usuarioId,
        'nome': nomeLimpo,
        'tipo': tipo.trim(),
        'saldoInicial': saldoInicial,
      });
    });
    await _avisarAlteracao(usuarioId);
    return id;
  }

  // Atualiza nome, tipo e saldo inicial de uma conta do usuário ativo.
  static Future<int> atualizarConta({
    required int id,
    required String nome,
    required String tipo,
    required double saldoInicial,
  }) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final nomeLimpo = nome.trim();
    final alteradas = await db.transaction<int>((txn) async {
      final atuais = await txn.query(
        'contas',
        where: 'id = ? AND usuarioId = ?',
        whereArgs: [id, usuarioId],
        limit: 1,
      );
      if (atuais.isEmpty) {
        throw StateError('Conta não encontrada.');
      }
      final duplicadas = await txn.query(
        'contas',
        where: 'usuarioId = ? AND id != ? AND LOWER(nome) = ?',
        whereArgs: [usuarioId, id, nomeLimpo.toLowerCase()],
        limit: 1,
      );
      if (duplicadas.isNotEmpty) {
        throw StateError('Já existe uma conta com esse nome.');
      }
      final nomeAntigo = atuais.first['nome'] as String;
      final alteradas = await txn.update(
        'contas',
        {'nome': nomeLimpo, 'tipo': tipo.trim(), 'saldoInicial': saldoInicial},
        where: 'id = ? AND usuarioId = ?',
        whereArgs: [id, usuarioId],
      );
      if (nomeAntigo != nomeLimpo) {
        await txn.update(
          'transacoes',
          {'conta': nomeLimpo},
          where: 'usuarioId = ? AND conta = ?',
          whereArgs: [usuarioId, nomeAntigo],
        );
      }
      return alteradas;
    });
    if (alteradas > 0) await _avisarAlteracao(usuarioId);
    return alteradas;
  }

  // Zera todos os saldos iniciais das contas do usuário ativo.
  static Future<void> zerarSaldosIniciais() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    await db.update(
      'contas',
      {'saldoInicial': 0.0},
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
    await _avisarAlteracao(usuarioId);
  }

  // Busca todas as receitas e despesas do usuário ativo, ordenadas pelas mais recentes.
  static Future<List<ModeloTransacao>> getTransacoes() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final linhas = await db.query(
      'transacoes',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'data DESC, id DESC',
    );
    return linhas.map(ModeloTransacao.fromMap).toList();
  }

  // Salva uma nova receita ou despesa no banco para o usuário ativo.
  static Future<int> inserirTransacao(ModeloTransacao transacao) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final id = await db.insert('transacoes', {
      ...transacao.toMap(),
      'usuarioId': usuarioId,
    });
    await _avisarAlteracao(usuarioId);
    return id;
  }

  // Lista os limites mensais configurados pelo usuário para cada categoria.
  static Future<List<Map<String, dynamic>>> getLimitesGastos() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    return db.query(
      'limites_gastos',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'categoria COLLATE NOCASE ASC',
    );
  }

  // Cria ou atualiza o limite de gasto de uma categoria para o usuário ativo.
  static Future<void> salvarLimiteGasto({
    required String categoria,
    required double limite,
  }) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    await db.insert('limites_gastos', {
      'usuarioId': usuarioId,
      'categoria': categoria.trim(),
      'limite': limite,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _avisarAlteracao(usuarioId);
  }

  static Future<void> removerLimiteGasto(int id) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final removidos = await db.delete(
      'limites_gastos',
      where: 'id = ? AND usuarioId = ?',
      whereArgs: [id, usuarioId],
    );
    if (removidos > 0) await _avisarAlteracao(usuarioId);
  }

  // Junta limite, gasto e percentual do mês para a tela de planejamento.
  static Future<List<Map<String, dynamic>>> getResumoLimitesGastos(
    DateTime mes,
  ) async {
    final limites = await getLimitesGastos();
    final transacoes = await getTransacoes();
    final resumo = <Map<String, dynamic>>[];
    for (final limite in limites) {
      final categoria = limite['categoria'] as String;
      final gasto = transacoes
          .where(
            (item) =>
                item.isDespesa &&
                item.categoria == categoria &&
                item.data.year == mes.year &&
                item.data.month == mes.month,
          )
          .fold<double>(0, (total, item) => total + item.valor);
      final valorLimite = (limite['limite'] as num).toDouble();
      resumo.add({
        ...limite,
        'gasto': gasto,
        'percentual': valorLimite <= 0 ? 0.0 : gasto / valorLimite,
      });
    }
    return resumo;
  }

  // Cria alertas ao atingir 80% ou ultrapassar um limite mensal de gastos.
  static Future<List<Map<String, dynamic>>> avaliarLimitesGastos({
    DateTime? mes,
  }) async {
    final referencia = mes ?? DateTime.now();
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final resumo = await getResumoLimitesGastos(referencia);
    final alertas = <Map<String, dynamic>>[];
    final mesTexto =
        '${referencia.year}-${referencia.month.toString().padLeft(2, '0')}';

    for (final item in resumo) {
      final percentual = item['percentual'] as double;
      if (percentual < 0.8) {
        continue;
      }
      final excedeu = percentual >= 1;
      final tipo = excedeu ? 'limite_excedido' : 'limite_atencao';
      final categoria = item['categoria'] as String;
      final limite = (item['limite'] as num).toDouble();
      final gasto = item['gasto'] as double;
      final titulo = excedeu ? 'Limite ultrapassado' : 'Atenção ao limite';
      final mensagem = excedeu
          ? 'Você gastou ${gasto.toStringAsFixed(2)} em $categoria e passou do limite de ${limite.toStringAsFixed(2)}.'
          : 'Você já usou ${(percentual * 100).toStringAsFixed(0)}% do limite de $categoria neste mês.';

      try {
        await db.insert('notificacoes', {
          'usuarioId': usuarioId,
          'titulo': titulo,
          'mensagem': mensagem,
          'tipo': tipo,
          'categoria': categoria,
          'mesReferencia': mesTexto,
          'criadaEm': DateTime.now().toIso8601String(),
          'lida': 0,
        });
        alertas.add({'titulo': titulo, 'mensagem': mensagem, 'tipo': tipo});
      } on DatabaseException catch (_) {
        // O alerta deste nível já foi criado para a categoria no mês atual.
      }
    }
    return alertas;
  }

  static Future<List<Map<String, dynamic>>> getNotificacoes() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    return db.query(
      'notificacoes',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'criadaEm DESC',
    );
  }

  static Future<void> marcarNotificacoesComoLidas() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    await db.update(
      'notificacoes',
      {'lida': 1},
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );
  }

  // Monta uma cópia sem senha, PIN ou identificadores locais para enviar à nuvem.
  static Future<Map<String, dynamic>> exportarDadosParaBackup({
    int? usuarioIdEsperado,
  }) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    if (usuarioIdEsperado != null && usuarioIdEsperado != usuarioId) {
      throw StateError('A conta ativa mudou durante o backup.');
    }
    await _garantirContasPadrao(db, usuarioId: usuarioId, saldoDemo: false);
    Map<String, dynamic> limpar(Map<String, dynamic> item) {
      final copia = Map<String, dynamic>.from(item);
      copia.remove('id');
      copia.remove('usuarioId');
      return copia;
    }

    return db.transaction((txn) async {
      Future<List<Map<String, dynamic>>> buscar(String tabela) =>
          txn.query(tabela, where: 'usuarioId = ?', whereArgs: [usuarioId]);
      final contas = await buscar('contas');
      final transacoes = await buscar('transacoes');
      final metas = await buscar('metas');
      final limites = await buscar('limites_gastos');
      return {
        'contas': contas.map(limpar).toList(),
        'transacoes': transacoes
            .map((item) => ModeloTransacao.fromMap(item).toMap()..remove('id'))
            .toList(),
        'metas': metas.map(limpar).toList(),
        'limites': limites.map(limpar).toList(),
      };
    });
  }

  // Troca os dados financeiros locais pelo último backup do usuário logado.
  static Future<void> restaurarDadosDoBackup(
    Map<String, dynamic> dados, {
    int? usuarioIdEsperado,
  }) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    if (usuarioIdEsperado != null && usuarioIdEsperado != usuarioId) {
      throw StateError('A conta ativa mudou durante a restauração.');
    }
    final contas = (dados['contas'] as List? ?? []).cast<Map>();
    final transacoes = (dados['transacoes'] as List? ?? []).cast<Map>();
    final metas = (dados['metas'] as List? ?? []).cast<Map>();
    final limites = (dados['limites'] as List? ?? []).cast<Map>();

    await db.transaction((txn) async {
      await txn.delete(
        'contas',
        where: 'usuarioId = ?',
        whereArgs: [usuarioId],
      );
      await txn.delete(
        'transacoes',
        where: 'usuarioId = ?',
        whereArgs: [usuarioId],
      );
      await txn.delete('metas', where: 'usuarioId = ?', whereArgs: [usuarioId]);
      await txn.delete(
        'limites_gastos',
        where: 'usuarioId = ?',
        whereArgs: [usuarioId],
      );

      for (final item in contas) {
        await txn.insert('contas', {
          ...Map<String, dynamic>.from(item),
          'usuarioId': usuarioId,
        });
      }
      for (final item in transacoes) {
        await txn.insert('transacoes', {
          ...Map<String, dynamic>.from(item),
          'usuarioId': usuarioId,
        });
      }
      for (final item in metas) {
        await txn.insert('metas', {
          ...Map<String, dynamic>.from(item),
          'usuarioId': usuarioId,
        });
      }
      for (final item in limites) {
        await txn.insert('limites_gastos', {
          ...Map<String, dynamic>.from(item),
          'usuarioId': usuarioId,
        });
      }
    });
  }

  // Remove uma transação específica, sem apagar dados de outros usuários.
  static Future<int> removerTransacao(int id) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final removidos = await db.delete(
      'transacoes',
      where: 'id = ? AND usuarioId = ?',
      whereArgs: [id, usuarioId],
    );
    if (removidos > 0) await _avisarAlteracao(usuarioId);
    return removidos;
  }

  // Lista as metas financeiras do usuário ativo, mostrando primeiro as mais avançadas.
  static Future<List<Map<String, dynamic>>> getMetas() async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    return db.query(
      'metas',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy:
          'CASE WHEN valorAlvo <= 0 THEN 0 ELSE valorAtual / valorAlvo END DESC',
    );
  }

  // Salva uma nova meta financeira para o usuário ativo.
  static Future<int> inserirMeta(Map<String, dynamic> meta) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final id = await db.insert('metas', {...meta, 'usuarioId': usuarioId});
    await _avisarAlteracao(usuarioId);
    return id;
  }

  // Atualiza uma meta financeira existente do usuário ativo.
  static Future<int> atualizarMeta({
    required int id,
    required Map<String, dynamic> meta,
  }) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final alteradas = await db.update(
      'metas',
      meta,
      where: 'id = ? AND usuarioId = ?',
      whereArgs: [id, usuarioId],
    );
    if (alteradas > 0) await _avisarAlteracao(usuarioId);
    return alteradas;
  }

  // Remove uma meta específica, protegendo os dados dos outros usuários.
  static Future<int> removerMeta(int id) async {
    final db = await database;
    final usuarioId = await _idUsuarioAtivo(db);
    final removidos = await db.delete(
      'metas',
      where: 'id = ? AND usuarioId = ?',
      whereArgs: [id, usuarioId],
    );
    if (removidos > 0) await _avisarAlteracao(usuarioId);
    return removidos;
  }
}
