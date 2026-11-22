import 'dart:async';

import 'package:flutter/material.dart';
import '../../servicos/servico_backup_automatico.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../inicio/tela_inicio.dart';
import '../seguranca/tela_pin.dart';
import 'tela_cadastro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final emailController = TextEditingController(
    text: ServicoBancoDados.emailDemonstracao,
  );
  final senhaController = TextEditingController(text: '123456');
  bool carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<bool> _validarCredenciais() async {
    if (emailController.text.trim().isEmpty ||
        senhaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe email e senha para entrar.')),
      );
      return false;
    }

    final loginValido = await ServicoBancoDados.validarLogin(
      email: emailController.text.trim(),
      senha: senhaController.text,
    );

    if (!loginValido && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email ou senha inválidos.')),
      );
    }

    return loginValido;
  }

  Future<void> _entrar() async {
    setState(() => carregando = true);
    final loginValido = await _validarCredenciais();
    if (!mounted) {
      return;
    }
    setState(() => carregando = false);

    if (!loginValido) {
      return;
    }

    unawaited(ServicoBackupAutomatico.aoEntrarNaConta());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaInicio()),
    );
  }

  Future<void> _abrirPin() async {
    final loginValido = await _validarCredenciais();
    if (!mounted || !loginValido) {
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaPin()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplicativo.teal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Entre na sua conta Kazux',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                decoration: const BoxDecoration(
                  color: TemaAplicativo.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: senhaController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: carregando ? null : _entrar,
                        icon: carregando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: carregando ? null : _abrirPin,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Acessar com PIN / Face ID'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: TemaAplicativo.teal,
                          side: const BorderSide(
                            color: TemaAplicativo.tealLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Não tem conta?',
                            style: TextStyle(color: TemaAplicativo.textLight),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TelaCadastro(),
                                ),
                              );
                            },
                            child: const Text('Criar conta'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TemaAplicativo.mint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Demonstração local: use ${ServicoBancoDados.emailDemonstracao} e senha 123456. Cadastros novos também salvam email e senha no aparelho.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TemaAplicativo.textMid,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
