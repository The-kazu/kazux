import 'dart:async';
import 'package:flutter/material.dart';
import '../../tema/tema_aplicativo.dart';
import 'tela_onboarding.dart';

class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key});

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelaOnboarding()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplicativo.teal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Kazux',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seu dinheiro, inteligente',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 44),
            const SizedBox(
              width: 42,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
