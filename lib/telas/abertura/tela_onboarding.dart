import 'package:flutter/material.dart';
import '../../tema/tema_aplicativo.dart';
import '../autenticacao/tela_cadastro.dart';
import '../autenticacao/tela_login.dart';

class TelaOnboarding extends StatefulWidget {
  const TelaOnboarding({super.key});

  @override
  State<TelaOnboarding> createState() => _TelaOnboardingState();
}

class _TelaOnboardingState extends State<TelaOnboarding> {
  final controller = PageController();
  int index = 0;

  final pages = const [
    _OnboardPage(
      icon: Icons.bar_chart_rounded,
      title: 'Controle Total das Suas Finanças',
      text:
          'Acompanhe receitas, despesas e metas em um único lugar, de forma simples e visual.',
    ),
    _OnboardPage(
      icon: Icons.auto_awesome_rounded,
      title: 'Insights Para Decidir Melhor',
      text:
          'Receba análises locais, alertas e uma base preparada para a futura integração com IA.',
    ),
    _OnboardPage(
      icon: Icons.lock_rounded,
      title: 'Dados Separados e Seguros',
      text:
          'Cada usuário mantém suas próprias contas, transações e metas salvas no banco local.',
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _abrirLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaLogin()),
    );
  }

  void _abrirCadastro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaCadastro()),
    );
  }

  void _proximo() {
    if (index == pages.length - 1) {
      _abrirCadastro();
      return;
    }
    controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = index == pages.length - 1;

    return Scaffold(
      backgroundColor: TemaAplicativo.tealDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _abrirLogin,
                  child: const Text(
                    'Pular',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: controller,
                  onPageChanged: (value) => setState(() => index = value),
                  children: pages,
                ),
              ),
              Row(
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == index ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 7),
                    decoration: BoxDecoration(
                      color: i == index ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _proximo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaAplicativo.tealLight,
                ),
                child: Text(ultimo ? 'Criar minha conta' : 'Próximo'),
              ),
              TextButton(
                onPressed: _abrirLogin,
                child: Text(
                  ultimo ? 'Já tenho conta' : 'Entrar agora',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -26,
                top: -26,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(child: Icon(icon, size: 74, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(color: Colors.white60, height: 1.55)),
        const Spacer(),
      ],
    );
  }
}
