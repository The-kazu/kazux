import 'package:flutter/material.dart';
import '../../componentes/componentes_kazux.dart';
import '../../servicos/servico_backup_automatico.dart';
import '../../servicos/servico_firebase.dart';
import '../../tema/tema_aplicativo.dart';

class TelaBackupNuvem extends StatefulWidget {
  const TelaBackupNuvem({super.key});

  @override
  State<TelaBackupNuvem> createState() => _TelaBackupNuvemState();
}

class _TelaBackupNuvemState extends State<TelaBackupNuvem> {
  bool carregando = false;
  bool backupAutomaticoAtivo = false;

  @override
  void initState() {
    super.initState();
    _carregarEstado();
  }

  Future<void> _carregarEstado() async {
    final ativo = await ServicoBackupAutomatico.estaAtivo();
    if (mounted) setState(() => backupAutomaticoAtivo = ativo);
  }

  Future<void> _executar(Future<ResultadoFirebase> Function() acao) async {
    setState(() => carregando = true);
    ResultadoFirebase resultado;
    try {
      resultado = await acao();
    } catch (_) {
      resultado = const ResultadoFirebase(
        sucesso: false,
        mensagem: 'Não foi possível concluir a operação. Tente novamente.',
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => carregando = false);
    await _carregarEstado();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultado.mensagem)));
  }

  Future<void> _alterarBackupAutomatico(bool ativar) async {
    if (ativar) {
      await _executar(ServicoBackupAutomatico.ativar);
      return;
    }
    setState(() => carregando = true);
    await ServicoBackupAutomatico.desativar();
    if (!mounted) return;
    setState(() {
      carregando = false;
      backupAutomaticoAtivo = false;
    });
  }

  Future<void> _restaurar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
          'Os dados financeiros deste aparelho serão substituídos pelo último backup da nuvem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _executar(ServicoBackupAutomatico.restaurarBackup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CabecalhoKazux(
              title: 'Backup em nuvem',
              subtitle: 'Firebase: login e cópia segura dos seus dados.',
              leading: BotaoIconeKazux(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const CartaoKazux(
                  color: TemaAplicativo.tealDark,
                  child: Row(
                    children: [
                      Icon(Icons.cloud_done_rounded, color: Color(0xFF7EFFD4)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'O backup salva contas, transações, metas e limites. A senha autentica no Firebase, mas senha e PIN não entram no backup.',
                          style: TextStyle(color: Colors.white, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Backup automático'),
                  subtitle: ValueListenableBuilder<String>(
                    valueListenable: ServicoBackupAutomatico.status,
                    builder: (context, valor, _) => Text(valor),
                  ),
                  value: backupAutomaticoAtivo,
                  onChanged: carregando ? null : _alterarBackupAutomatico,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: carregando
                      ? null
                      : () => _executar(ServicoBackupAutomatico.ativar),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Conectar conta Firebase'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: carregando
                      ? null
                      : () => _executar(ServicoFirebase.enviarBackup),
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Enviar backup agora'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: carregando ? null : _restaurar,
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: const Text('Restaurar último backup'),
                ),
                if (carregando) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
