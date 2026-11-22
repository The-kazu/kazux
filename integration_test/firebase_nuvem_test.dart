import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kazux/modelos/modelo_transacao.dart';
import 'package:kazux/servicos/servico_backup_automatico.dart';
import 'package:kazux/servicos/servico_banco_dados.dart';
import 'package:kazux/servicos/servico_firebase.dart';

const _testeRealAtivado = bool.fromEnvironment('KAZUX_TESTE_FIREBASE_REAL');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Firebase real: autenticação, backup e isolamento entre contas',
    (tester) async {
      final marcador = DateTime.now().microsecondsSinceEpoch;
      final emailA = 'kazux-auditoria-a-$marcador@example.com';
      final emailB = 'kazux-auditoria-b-$marcador@example.com';
      final senhaA = 'Kazux#A$marcador';
      final senhaB = 'Kazux#B$marcador';
      final contasDeTeste = [(emailA, senhaA), (emailB, senhaB)];
      int? usuarioOriginalId;

      try {
        usuarioOriginalId =
            (await ServicoBancoDados.getUsuario())?['id'] as int?;
        await ServicoBancoDados.salvarUsuario(
          nome: 'Auditoria Firebase A',
          email: emailA,
          telefone: '',
          senha: senhaA,
          pin: '864209',
        );
        final conexaoA = await ServicoFirebase.conectarUsuarioAtivo();
        expect(conexaoA.sucesso, isTrue, reason: conexaoA.mensagem);
        final uidA = FirebaseAuth.instance.currentUser!.uid;

        final idConta = await ServicoBancoDados.inserirConta(
          nome: 'Conta Auditoria',
          tipo: 'Corrente',
          saldoInicial: 125.75,
        );
        final idTransacao = await ServicoBancoDados.inserirTransacao(
          ModeloTransacao(
            descricao: 'Auditoria do backup na nuvem',
            valor: 37.50,
            tipo: 'Despesa',
            categoria: 'Alimentação',
            conta: 'Nubank',
            data: DateTime.now(),
          ),
        );
        final idMeta = await ServicoBancoDados.inserirMeta({
          'nome': 'Meta Auditoria',
          'valorAlvo': 500.0,
          'valorAtual': 125.0,
          'prazo': DateTime.now()
              .add(const Duration(days: 60))
              .toIso8601String(),
          'icone': 'shield',
          'cor': 'teal',
        });
        await ServicoBancoDados.salvarLimiteGasto(
          categoria: 'Alimentação',
          limite: 300,
        );
        final envioA = await ServicoFirebase.enviarBackup();
        expect(envioA.sucesso, isTrue, reason: envioA.mensagem);
        final backupA = FirebaseFirestore.instance
            .collection('backups_kazux')
            .doc(uidA);
        final documentoA = await backupA.get(
          const GetOptions(source: Source.server),
        );
        expect(documentoA.exists, isTrue);
        final dadosNuvem = documentoA.data()!['dados'] as Map<String, dynamic>;
        final conteudo = jsonEncode(dadosNuvem);
        expect(conteudo, contains('Auditoria do backup na nuvem'));
        expect(conteudo, contains('Conta Auditoria'));
        expect(conteudo, contains('Meta Auditoria'));
        expect(conteudo, contains('Alimentação'));
        expect(conteudo, isNot(contains(senhaA)));
        expect(conteudo, isNot(contains('864209')));
        expect(conteudo, isNot(contains('usuarioId')));

        await ServicoBancoDados.removerTransacao(idTransacao);
        await ServicoBancoDados.removerMeta(idMeta);
        final limite = (await ServicoBancoDados.getLimitesGastos()).single;
        await ServicoBancoDados.removerLimiteGasto(limite['id'] as int);
        await ServicoBancoDados.atualizarConta(
          id: idConta,
          nome: 'Conta Auditoria',
          tipo: 'Corrente',
          saldoInicial: 0,
        );
        expect(await ServicoBancoDados.getTransacoes(), isEmpty);

        await ServicoBancoDados.salvarUsuario(
          nome: 'Auditoria Firebase B',
          email: emailB,
          telefone: '',
          senha: senhaB,
          pin: '572831',
        );
        final conexaoB = await ServicoFirebase.conectarUsuarioAtivo();
        expect(conexaoB.sucesso, isTrue, reason: conexaoB.mensagem);
        final envioB = await ServicoFirebase.enviarBackup();
        expect(envioB.sucesso, isTrue, reason: envioB.mensagem);
        expect(await ServicoBancoDados.getMetas(), isEmpty);

        await expectLater(
          backupA.get(const GetOptions(source: Source.server)),
          throwsA(
            isA<FirebaseException>().having(
              (erro) => erro.code,
              'código',
              'permission-denied',
            ),
          ),
        );
        await expectLater(
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uidA)
              .get(const GetOptions(source: Source.server)),
          throwsA(
            isA<FirebaseException>().having(
              (erro) => erro.code,
              'código',
              'permission-denied',
            ),
          ),
        );
        await expectLater(
          backupA.update({'auditoriaInvasao': true}),
          throwsA(
            isA<FirebaseException>().having(
              (erro) => erro.code,
              'código',
              'permission-denied',
            ),
          ),
        );

        await FirebaseAuth.instance.signOut();
        await expectLater(
          backupA.get(const GetOptions(source: Source.server)),
          throwsA(
            isA<FirebaseException>().having(
              (erro) => erro.code,
              'código',
              'permission-denied',
            ),
          ),
        );
        await expectLater(
          backupA.update({'auditoriaInvasao': true}),
          throwsA(
            isA<FirebaseException>().having(
              (erro) => erro.code,
              'código',
              'permission-denied',
            ),
          ),
        );

        expect(
          await ServicoBancoDados.validarLogin(email: emailA, senha: senhaA),
          isTrue,
        );
        final retornoA = await ServicoFirebase.conectarUsuarioAtivo();
        expect(retornoA.sucesso, isTrue, reason: retornoA.mensagem);
        final restauracao = await ServicoFirebase.restaurarBackup();
        expect(restauracao.sucesso, isTrue, reason: restauracao.mensagem);
        expect(
          (await ServicoBancoDados.getTransacoes()).single.descricao,
          'Auditoria do backup na nuvem',
        );
        expect(
          (await ServicoBancoDados.getContas()).singleWhere(
            (conta) => conta['nome'] == 'Conta Auditoria',
          )['saldoInicial'],
          125.75,
        );
        expect(
          (await ServicoBancoDados.getMetas()).single['nome'],
          'Meta Auditoria',
        );
        expect(
          (await ServicoBancoDados.getLimitesGastos()).single['limite'],
          300,
        );

        final ativacaoAutomatica = await ServicoBackupAutomatico.ativar();
        expect(
          ativacaoAutomatica.sucesso,
          isTrue,
          reason: ativacaoAutomatica.mensagem,
        );
        await ServicoBancoDados.inserirTransacao(
          ModeloTransacao(
            descricao: 'Envio automatico da auditoria',
            valor: 12.25,
            tipo: 'Despesa',
            categoria: 'Lazer',
            conta: 'Conta Auditoria',
            data: DateTime.now(),
          ),
        );
        await tester.pump(const Duration(seconds: 3));
        await ServicoBackupAutomatico.sincronizarAgora();
        final backupAutomatico = await backupA.get(
          const GetOptions(source: Source.server),
        );
        expect(
          jsonEncode(backupAutomatico.data()!['dados']),
          contains('Envio automatico da auditoria'),
        );
      } finally {
        await ServicoBackupAutomatico.desativar();
        ServicoBackupAutomatico.aoSairDaConta();
        final db = await ServicoBancoDados.database;
        await db.transaction((txn) async {
          final usuarios = await txn.query(
            'usuarios',
            where: 'email IN (?, ?)',
            whereArgs: [emailA, emailB],
          );
          for (final usuario in usuarios) {
            final id = usuario['id'] as int;
            for (final tabela in [
              'contas',
              'transacoes',
              'metas',
              'limites_gastos',
              'notificacoes',
            ]) {
              await txn.delete(tabela, where: 'usuarioId = ?', whereArgs: [id]);
            }
            await txn.delete('usuarios', where: 'id = ?', whereArgs: [id]);
          }
          if (usuarioOriginalId != null) {
            await txn.update('usuarios', {'ativo': 0});
            await txn.update(
              'usuarios',
              {'ativo': 1},
              where: 'id = ?',
              whereArgs: [usuarioOriginalId],
            );
          }
        });
        if (Firebase.apps.isNotEmpty) {
          for (final (email, senha) in contasDeTeste) {
            User? usuario;
            try {
              usuario = (await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: senha,
              )).user;
            } on FirebaseAuthException catch (erro) {
              if (erro.code == 'user-not-found' ||
                  erro.code == 'invalid-credential') {
                continue;
              }
              rethrow;
            }
            if (usuario == null) {
              continue;
            }
            final uid = usuario.uid;
            await FirebaseFirestore.instance
                .collection('backups_kazux')
                .doc(uid)
                .delete();
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .delete();
            await usuario.delete();
          }
          await FirebaseAuth.instance.signOut();
        }
      }
    },
    skip: !_testeRealAtivado,
  );
}
