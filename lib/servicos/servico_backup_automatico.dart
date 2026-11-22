import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'servico_banco_dados.dart';
import 'servico_firebase.dart';

class ServicoBackupAutomatico {
  ServicoBackupAutomatico._();

  static final ValueNotifier<String> status = ValueNotifier('Desativado');
  static final _observador = _ObservadorBackup();
  static Timer? _agendamento;
  static Future<void>? _envioEmCurso;
  static Future<void> _filaAlteracoes = Future.value();
  static bool _iniciado = false;
  static bool _sessaoAtiva = false;
  static bool _restaurando = false;
  static int? _usuarioAtivoId;

  static String _chaveAtivo(int id) => 'backup_auto_ativo_$id';
  static String _chaveVersao(int id) => 'backup_auto_versao_$id';
  static String _chaveEnviada(int id) => 'backup_auto_enviada_$id';

  static void iniciar() {
    if (_iniciado) return;
    _iniciado = true;
    ServicoBancoDados.aoAlterarDadosFinanceiros = registrarAlteracao;
    WidgetsBinding.instance.addObserver(_observador);
    Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(sincronizarAgora()),
    );
  }

  static Future<void> aoEntrarNaConta() async {
    iniciar();
    final usuario = await ServicoBancoDados.getUsuario();
    if (usuario == null) return;
    final id = usuario['id'] as int;
    _sessaoAtiva = true;
    _usuarioAtivoId = id;
    final preferencias = await SharedPreferences.getInstance();
    final chave = _chaveAtivo(id);

    // Quem ja conectou esta conta antes recebe o backup automatico sem novo cadastro.
    if (!preferencias.containsKey(chave) &&
        await ServicoFirebase.usuarioAtivoEstaConectado() &&
        (await ServicoBancoDados.getUsuario())?['id'] == id) {
      await preferencias.setBool(chave, true);
      await registrarAlteracao(id);
    }
    if (!_sessaoAtiva || _usuarioAtivoId != id) return;
    await _atualizarStatus(id, preferencias);
    _agendar(const Duration(seconds: 2));
  }

  static void aoSairDaConta() {
    _sessaoAtiva = false;
    _usuarioAtivoId = null;
    _agendamento?.cancel();
    status.value = 'Desativado';
  }

  static Future<bool> estaAtivo() async {
    final usuario = await ServicoBancoDados.getUsuario();
    if (usuario == null) return false;
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getBool(_chaveAtivo(usuario['id'] as int)) ?? false;
  }

  static Future<ResultadoFirebase> ativar() async {
    iniciar();
    final usuarioInicial = await ServicoBancoDados.getUsuario();
    if (usuarioInicial == null) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem: 'Usuário local não encontrado.',
      );
    }
    final conexao = await ServicoFirebase.conectarUsuarioAtivo();
    if (!conexao.sucesso) return conexao;
    final usuario = await ServicoBancoDados.getUsuario();
    if (usuario == null || usuario['id'] != usuarioInicial['id']) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem: 'A conta ativa mudou. Tente conectar novamente.',
      );
    }
    final id = usuario['id'] as int;
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setBool(_chaveAtivo(id), true);
    _sessaoAtiva = true;
    _usuarioAtivoId = id;
    await registrarAlteracao(id);
    status.value = 'Aguardando envio';
    _agendar(Duration.zero);
    return const ResultadoFirebase(
      sucesso: true,
      mensagem: 'Conta conectada. Backup automático ativado.',
    );
  }

  static Future<void> desativar() async {
    final usuario = await ServicoBancoDados.getUsuario();
    if (usuario == null) return;
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setBool(_chaveAtivo(usuario['id'] as int), false);
    _agendamento?.cancel();
    status.value = 'Desativado';
  }

  static Future<void> registrarAlteracao(int usuarioId) {
    _filaAlteracoes = _filaAlteracoes.then((_) async {
      try {
        final preferencias = await SharedPreferences.getInstance();
        final chave = _chaveVersao(usuarioId);
        await preferencias.setInt(chave, (preferencias.getInt(chave) ?? 0) + 1);
        if (_sessaoAtiva &&
            _usuarioAtivoId == usuarioId &&
            (preferencias.getBool(_chaveAtivo(usuarioId)) ?? false)) {
          status.value = 'Aguardando envio';
          _agendar(const Duration(seconds: 2));
        }
      } catch (_) {
        status.value = 'Backup pendente';
      }
    });
    return _filaAlteracoes;
  }

  static void _agendar(Duration atraso) {
    _agendamento?.cancel();
    if (!_sessaoAtiva || _restaurando) return;
    _agendamento = Timer(atraso, () => unawaited(sincronizarAgora()));
  }

  static Future<void> sincronizarAgora() {
    if (_envioEmCurso != null) return _envioEmCurso!;
    final envio = _sincronizar();
    _envioEmCurso = envio;
    return envio.whenComplete(() => _envioEmCurso = null);
  }

  static Future<void> _sincronizar() async {
    if (!_sessaoAtiva || _restaurando) return;
    final id = _usuarioAtivoId;
    if (id == null) return;
    try {
      final preferencias = await SharedPreferences.getInstance();
      if (!(preferencias.getBool(_chaveAtivo(id)) ?? false)) return;
      if ((await ServicoBancoDados.getUsuario())?['id'] != id) return;
      final versao = preferencias.getInt(_chaveVersao(id)) ?? 0;
      final enviada = preferencias.getInt(_chaveEnviada(id)) ?? 0;
      if (versao <= enviada) {
        status.value = 'Atualizado';
        return;
      }

      status.value = 'Enviando backup';
      final resultado = await ServicoFirebase.enviarBackup(
        usuarioIdEsperado: id,
      );
      if (!resultado.sucesso) {
        if (_sessaoAtiva &&
            _usuarioAtivoId == id &&
            (preferencias.getBool(_chaveAtivo(id)) ?? false)) {
          status.value = 'Pendente: ${resultado.mensagem}';
          _agendar(const Duration(minutes: 1));
        }
        return;
      }
      await preferencias.setInt(_chaveEnviada(id), versao);
      if (_sessaoAtiva &&
          _usuarioAtivoId == id &&
          (preferencias.getBool(_chaveAtivo(id)) ?? false)) {
        if ((preferencias.getInt(_chaveVersao(id)) ?? 0) > versao) {
          status.value = 'Aguardando envio';
          _agendar(const Duration(seconds: 2));
        } else {
          status.value = 'Atualizado';
        }
      }
    } catch (_) {
      bool ativo;
      try {
        final preferencias = await SharedPreferences.getInstance();
        ativo = preferencias.getBool(_chaveAtivo(id)) ?? false;
      } catch (_) {
        ativo = true;
      }
      if (_sessaoAtiva && _usuarioAtivoId == id && ativo) {
        status.value = 'Backup pendente';
        _agendar(const Duration(minutes: 1));
      }
    } finally {
      if (_sessaoAtiva && _usuarioAtivoId != id) {
        _agendar(Duration.zero);
      }
    }
  }

  static Future<ResultadoFirebase> restaurarBackup() async {
    _agendamento?.cancel();
    _restaurando = true;
    try {
      await _envioEmCurso;
      final usuarioInicial = await ServicoBancoDados.getUsuario();
      final resultado = await ServicoFirebase.restaurarBackup();
      if (resultado.sucesso) {
        final usuario = await ServicoBancoDados.getUsuario();
        if (usuario != null && usuario['id'] == usuarioInicial?['id']) {
          final id = usuario['id'] as int;
          final preferencias = await SharedPreferences.getInstance();
          await preferencias.setInt(
            _chaveEnviada(id),
            preferencias.getInt(_chaveVersao(id)) ?? 0,
          );
          status.value = 'Atualizado';
        }
      }
      return resultado;
    } finally {
      _restaurando = false;
      _agendar(const Duration(seconds: 2));
    }
  }

  static Future<void> _atualizarStatus(
    int id,
    SharedPreferences preferencias,
  ) async {
    if (!(preferencias.getBool(_chaveAtivo(id)) ?? false)) {
      status.value = 'Desativado';
    } else if ((preferencias.getInt(_chaveVersao(id)) ?? 0) >
        (preferencias.getInt(_chaveEnviada(id)) ?? 0)) {
      status.value = 'Aguardando envio';
    } else {
      status.value = 'Atualizado';
    }
  }
}

class _ObservadorBackup with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (ServicoBackupAutomatico._sessaoAtiva) {
        unawaited(ServicoBackupAutomatico.aoEntrarNaConta());
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(ServicoBackupAutomatico.sincronizarAgora());
    }
  }
}
