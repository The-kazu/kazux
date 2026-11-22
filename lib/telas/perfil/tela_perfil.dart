import 'package:flutter/material.dart';
import '../../servicos/servico_backup_automatico.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../../componentes/componentes_kazux.dart';
import '../contas/tela_contas.dart';
import '../categorias/tela_categorias.dart';
import '../autenticacao/tela_login.dart';
import 'tela_editar_perfil.dart';
import '../metas/tela_metas.dart';
import '../seguranca/tela_pin.dart';
import 'tela_backup_nuvem.dart';
import 'tela_aparencia.dart';
import '../assistente/tela_assistente.dart';

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  late Future<_DadosPerfil> futuro;

  @override
  void initState() {
    super.initState();
    futuro = _load();
  }

  Future<_DadosPerfil> _load() async {
    final usuario = await ServicoBancoDados.getUsuario();
    final contas = await ServicoBancoDados.getContas();
    final metas = await ServicoBancoDados.getMetas();
    final transacoes = await ServicoBancoDados.getTransacoes();
    return _DadosPerfil(
      usuario: usuario,
      contas: contas.length,
      metas: metas.length,
      transacoes: transacoes.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<_DadosPerfil>(
        future: futuro,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final nome = (data?.usuario?['nome'] as String?) ?? 'Usuário';
          final email = (data?.usuario?['email'] as String?) ?? '';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 18,
                    20,
                    24,
                  ),
                  decoration: const BoxDecoration(
                    color: TemaAplicativo.teal,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _StatBox(
                            label: 'Contas',
                            valor: '${data?.contas ?? 0}',
                          ),
                          _StatBox(
                            label: 'Metas',
                            valor: '${data?.metas ?? 0}',
                          ),
                          _StatBox(
                            label: 'Transações',
                            valor: '${data?.transacoes ?? 0}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _MenuItem(
                      icon: Icons.person_rounded,
                      title: 'Meu perfil',
                      subtitle: 'Dados pessoais e preferências',
                      onTap: () async {
                        await Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder: (_) => const TelaEditarPerfil(),
                          ),
                        );
                        setState(() => futuro = _load());
                      },
                    ),
                    _MenuItem(
                      icon: Icons.account_balance_rounded,
                      title: 'Minhas contas',
                      subtitle: 'Nubank, Carteira e Investimentos',
                      onTap: () async {
                        await Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(builder: (_) => const TelaContas()),
                        );
                        setState(() => futuro = _load());
                      },
                    ),
                    _MenuItem(
                      icon: Icons.category_rounded,
                      title: 'Categorias',
                      subtitle: 'Organize receitas e despesas',
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder: (_) => const TelaCategorias(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.flag_rounded,
                      title: 'Metas financeiras',
                      subtitle: 'Acompanhe objetivos e progresso',
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(builder: (_) => const TelaMetas()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.dark_mode_rounded,
                      title: 'Aparência',
                      subtitle: 'Tema claro, escuro ou automático',
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder: (_) => const TelaAparencia(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.lock_rounded,
                      title: 'Segurança',
                      subtitle: 'PIN, Face ID e acesso local',
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(builder: (_) => const TelaPin()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.cloud_done_rounded,
                      title: 'Backup em nuvem',
                      subtitle: 'Firebase: login, envio e restauração',
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder: (_) => const TelaBackupNuvem(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.smart_toy_rounded,
                      title: 'Assistente inteligente',
                      subtitle: 'Preparado para ativação da IA',
                      onTap: () {
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder: (_) => const TelaAssistente(),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Sair da conta',
                      subtitle: 'Voltar para a tela de login',
                      danger: true,
                      onTap: () {
                        ServicoBackupAutomatico.aoSairDaConta();
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const TelaLogin()),
                          (_) => false,
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cor = danger ? TemaAplicativo.danger : TemaAplicativo.teal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoKazux(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.12),
              child: Icon(icon, color: cor),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: danger ? TemaAplicativo.danger : TemaAplicativo.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _DadosPerfil {
  const _DadosPerfil({
    required this.usuario,
    required this.contas,
    required this.metas,
    required this.transacoes,
  });

  final Map<String, dynamic>? usuario;
  final int contas;
  final int metas;
  final int transacoes;
}
