import 'package:flutter/material.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../seguranca/tela_pin.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();
  final pinController = TextEditingController();
  final confirmarPinController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    pinController.dispose();
    confirmarPinController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;
    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (nomeController.text.trim().isEmpty || email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, email e senha.')),
      );
      return;
    }

    if (!emailValido) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um email válido.')));
      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha precisa ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }

    if (senha != confirmarSenhaController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não conferem.')));
      return;
    }

    final pin = pinController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie um PIN de 6 números.')),
      );
      return;
    }

    if (pin != confirmarPinController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Os PINs não conferem.')));
      return;
    }

    try {
      await ServicoBancoDados.salvarUsuario(
        nome: nomeController.text.trim(),
        email: email,
        telefone: telefoneController.text.trim(),
        senha: senha,
        pin: pin,
      );
    } on StateError catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(erro.message)));
      }
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaPin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaAplicativo.teal,
      appBar: AppBar(title: const Text('Criar conta')),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: const BoxDecoration(
          color: TemaAplicativo.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Preencha seus dados',
                style: TextStyle(
                  color: TemaAplicativo.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Crie seu PIN de acesso e depois use biometria, se disponível.',
                style: TextStyle(color: TemaAplicativo.textLight),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 14),
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
                controller: telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone_rounded),
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
              const SizedBox(height: 14),
              TextField(
                controller: confirmarSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.verified_user_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Crie um PIN de 6 números',
                  prefixIcon: Icon(Icons.pin_rounded),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmarPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirme seu PIN',
                  prefixIcon: Icon(Icons.pin_rounded),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 26),
              ElevatedButton.icon(
                onPressed: _criarConta,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
