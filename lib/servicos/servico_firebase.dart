import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'servico_banco_dados.dart';

class ResultadoFirebase {
  const ResultadoFirebase({required this.sucesso, required this.mensagem});

  final bool sucesso;
  final String mensagem;
}

// Mantém o backup em nuvem separado do banco SQLite que o aplicativo usa offline.
class ServicoFirebase {
  ServicoFirebase._();

  static Future<bool> usuarioAtivoEstaConectado() async {
    final usuario = await ServicoBancoDados.getUsuario();
    if (usuario == null) return false;
    try {
      await _inicializar();
      return FirebaseAuth.instance.currentUser?.email?.toLowerCase() ==
          (usuario['email'] as String).toLowerCase();
    } catch (_) {
      return false;
    }
  }

  static Future<ResultadoFirebase> conectarUsuarioAtivo() async {
    final usuario = await ServicoBancoDados.getUsuario();
    if (usuario == null) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem: 'Usuário local não encontrado.',
      );
    }
    final email = usuario['email'] as String;
    if (email.toLowerCase() == ServicoBancoDados.emailDemonstracao) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem:
            'A conta de demonstração é local. Cadastre uma conta própria para usar o backup.',
      );
    }
    return _entrarOuCriar(
      email: email,
      senha: usuario['senha'] as String,
      nome: usuario['nome'] as String,
    );
  }

  static Future<ResultadoFirebase> _entrarOuCriar({
    required String email,
    required String senha,
    required String nome,
  }) async {
    try {
      await _inicializar();
      final auth = FirebaseAuth.instance;
      final usuarioAtual = auth.currentUser;
      final mesmoUsuario =
          usuarioAtual?.email?.toLowerCase() == email.toLowerCase();

      // Garante que o backup sempre pertence ao usuário local logado no Kazux.
      if (!mesmoUsuario) {
        if (usuarioAtual != null) await auth.signOut();
        try {
          await auth.signInWithEmailAndPassword(email: email, password: senha);
        } on FirebaseAuthException catch (erro) {
          if (erro.code != 'user-not-found' &&
              erro.code != 'invalid-credential') {
            rethrow;
          }
          try {
            await auth.createUserWithEmailAndPassword(
              email: email,
              password: senha,
            );
          } on FirebaseAuthException catch (erroCadastro) {
            if (erroCadastro.code == 'email-already-in-use') {
              return const ResultadoFirebase(
                sucesso: false,
                mensagem:
                    'A senha desta conta não confere com a conta Firebase.',
              );
            }
            rethrow;
          }
        }
      }
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(auth.currentUser!.uid)
          .set({
            'nome': nome,
            'email': email,
            'atualizadoEm': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      return const ResultadoFirebase(
        sucesso: true,
        mensagem: 'Conta Firebase conectada.',
      );
    } on FirebaseException catch (erro) {
      return ResultadoFirebase(sucesso: false, mensagem: _mensagemErro(erro));
    } catch (_) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem: 'Firebase ainda não foi configurado neste aplicativo.',
      );
    }
  }

  static Future<ResultadoFirebase> enviarBackup({
    int? usuarioIdEsperado,
  }) async {
    final usuarioLocal = await ServicoBancoDados.getUsuario();
    if (usuarioLocal == null ||
        (usuarioIdEsperado != null &&
            usuarioLocal['id'] != usuarioIdEsperado)) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem: 'A conta ativa mudou. Tente enviar o backup novamente.',
      );
    }
    final idLocal = usuarioLocal['id'] as int;
    final emailLocal = (usuarioLocal['email'] as String).toLowerCase();
    final conexao = await conectarUsuarioAtivo();
    if (!conexao.sucesso) {
      return conexao;
    }
    try {
      final usuarioFirebase = FirebaseAuth.instance.currentUser;
      if (usuarioFirebase?.email?.toLowerCase() != emailLocal) {
        throw StateError('A conta Firebase mudou durante o backup.');
      }
      final dados = await ServicoBancoDados.exportarDadosParaBackup(
        usuarioIdEsperado: idLocal,
      );
      if ((await ServicoBancoDados.getUsuario())?['id'] != idLocal ||
          FirebaseAuth.instance.currentUser?.uid != usuarioFirebase!.uid) {
        throw StateError('A conta ativa mudou durante o backup.');
      }
      final uid = usuarioFirebase.uid;
      await FirebaseFirestore.instance.collection('backups_kazux').doc(uid).set(
        {
          'versao': 1,
          'atualizadoEm': FieldValue.serverTimestamp(),
          'dados': dados,
        },
      );
      return const ResultadoFirebase(
        sucesso: true,
        mensagem: 'Backup enviado para a nuvem.',
      );
    } on FirebaseException catch (erro) {
      return ResultadoFirebase(sucesso: false, mensagem: _mensagemErro(erro));
    } catch (_) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem: 'Não foi possível preparar ou enviar o backup.',
      );
    }
  }

  static Future<ResultadoFirebase> restaurarBackup() async {
    final usuarioLocal = await ServicoBancoDados.getUsuario();
    if (usuarioLocal == null) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem: 'Usuário local não encontrado.',
      );
    }
    final idLocal = usuarioLocal['id'] as int;
    final emailLocal = (usuarioLocal['email'] as String).toLowerCase();
    final conexao = await conectarUsuarioAtivo();
    if (!conexao.sucesso) {
      return conexao;
    }
    try {
      final usuarioFirebase = FirebaseAuth.instance.currentUser;
      if (usuarioFirebase?.email?.toLowerCase() != emailLocal) {
        throw StateError('A conta Firebase mudou durante a restauração.');
      }
      final uid = usuarioFirebase!.uid;
      final documento = await FirebaseFirestore.instance
          .collection('backups_kazux')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      final dados = documento.data()?['dados'];
      if (dados is! Map) {
        return const ResultadoFirebase(
          sucesso: false,
          mensagem: 'Nenhum backup encontrado para esta conta.',
        );
      }
      if ((await ServicoBancoDados.getUsuario())?['id'] != idLocal ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        throw StateError('A conta ativa mudou durante a restauração.');
      }
      await ServicoBancoDados.restaurarDadosDoBackup(
        Map<String, dynamic>.from(dados),
        usuarioIdEsperado: idLocal,
      );
      return const ResultadoFirebase(
        sucesso: true,
        mensagem: 'Backup restaurado neste aparelho.',
      );
    } on FirebaseException catch (erro) {
      return ResultadoFirebase(sucesso: false, mensagem: _mensagemErro(erro));
    } catch (_) {
      return const ResultadoFirebase(
        sucesso: false,
        mensagem:
            'Backup inválido ou incompatível. Os dados locais foram mantidos.',
      );
    }
  }

  static Future<void> _inicializar() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  static String _mensagemErro(FirebaseException erro) {
    if (erro.code == 'permission-denied') {
      return 'O Firebase bloqueou o acesso. Verifique as regras do Firestore.';
    }
    if (erro.code == 'network-request-failed') {
      return 'Sem internet para acessar o Firebase.';
    }
    if (erro.code == 'operation-not-allowed') {
      return 'Ative Email/Senha em Authentication no painel do Firebase.';
    }
    return 'Não foi possível conectar ao Firebase: ${erro.message ?? erro.code}';
  }
}
