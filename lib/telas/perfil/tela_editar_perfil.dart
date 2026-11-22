import 'package:flutter/material.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../../componentes/componentes_kazux.dart';

class TelaEditarPerfil extends StatefulWidget {
  const TelaEditarPerfil({super.key});

  @override
  State<TelaEditarPerfil> createState() => _TelaEditarPerfilState();
}

class _TelaEditarPerfilState extends State<TelaEditarPerfil> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final usuario = await ServicoBancoDados.getUsuario();
    nomeController.text = (usuario?['nome'] as String?) ?? '';
    emailController.text = (usuario?['email'] as String?) ?? '';
    telefoneController.text = (usuario?['telefone'] as String?) ?? '';
    if (mounted) {
      setState(() => carregando = false);
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe nome e email.')));
      return;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um email válido.')));
      return;
    }

    try {
      await ServicoBancoDados.atualizarPerfil(
        nome: nomeController.text.trim(),
        email: emailController.text.trim(),
        telefone: telefoneController.text.trim(),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CabecalhoKazux(
            title: 'Meu perfil',
            subtitle: 'Atualize seus dados pessoais.',
            leading: BotaoIconeKazux(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CartaoKazux(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: TemaAplicativo.mint,
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: TemaAplicativo.teal,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: nomeController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome completo',
                                  prefixIcon: Icon(Icons.person_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: telefoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telefone',
                                  prefixIcon: Icon(Icons.phone_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _salvar,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Salvar perfil'),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
