import 'dart:async';

import 'package:flutter/material.dart';
import '../../servicos/servico_autenticacao_local.dart';
import '../../servicos/servico_backup_automatico.dart';
import '../../servicos/servico_banco_dados.dart';
import '../../tema/tema_aplicativo.dart';
import '../inicio/tela_inicio.dart';

class TelaPin extends StatefulWidget {
  const TelaPin({super.key, this.modoConfiguracao = false});

  final bool modoConfiguracao;

  @override
  State<TelaPin> createState() => _TelaPinState();
}

class _TelaPinState extends State<TelaPin> {
  String pin = '';
  bool carregando = false;
  bool biometriaDisponivel = false;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
    final disponivel = await ServicoAutenticacaoLocal.podeUsarBiometria();
    if (mounted) {
      setState(() => biometriaDisponivel = disponivel);
    }
  }

  Future<void> _tap(String valor) async {
    if (carregando) {
      return;
    }

    if (valor == 'back') {
      if (pin.isNotEmpty) {
        setState(() => pin = pin.substring(0, pin.length - 1));
      }
      return;
    }

    if (valor == 'face') {
      await _entrarComBiometria();
      return;
    }

    if (pin.length >= 6) {
      return;
    }

    setState(() => pin += valor);
    if (pin.length == 6) {
      await _validarPin();
    }
  }

  Future<void> _validarPin() async {
    setState(() => carregando = true);
    final pinValido = await ServicoBancoDados.validarPin(pin);
    if (!mounted) {
      return;
    }
    setState(() => carregando = false);

    if (!pinValido) {
      setState(() => pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorreto. Tente novamente.')),
      );
      return;
    }

    _concluirAcesso();
  }

  Future<void> _entrarComBiometria() async {
    if (!biometriaDisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face ID/Touch ID não está disponível neste aparelho.'),
        ),
      );
      return;
    }

    setState(() => carregando = true);
    final autenticado = await ServicoAutenticacaoLocal.autenticar();
    if (!mounted) {
      return;
    }
    setState(() => carregando = false);

    if (autenticado) {
      _concluirAcesso();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometria não confirmada. Use o PIN.')),
    );
  }

  void _concluirAcesso() {
    if (widget.modoConfiguracao) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Segurança confirmada.')));
      Navigator.pop(context, true);
      return;
    }

    unawaited(ServicoBackupAutomatico.aoEntrarNaConta());
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TelaInicio()),
      (_) => false,
    );
  }

  Future<void> _alterarPin() async {
    final atualController = TextEditingController();
    final novoController = TextEditingController();
    final confirmarController = TextEditingController();

    final novoPin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alterar PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: atualController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'PIN atual'),
              ),
              TextField(
                controller: novoController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Novo PIN'),
              ),
              TextField(
                controller: confirmarController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Confirmar PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final atual = atualController.text.trim();
                final novo = novoController.text.trim();
                final confirmar = confirmarController.text.trim();
                final valido = RegExp(r'^\d{6}$').hasMatch(novo);

                if (!valido || novo != confirmar) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Digite e confirme um PIN de 6 números.'),
                    ),
                  );
                  return;
                }

                final pinAtualValido = await ServicoBancoDados.validarPin(
                  atual,
                );
                if (!context.mounted) {
                  return;
                }
                if (!pinAtualValido) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN atual incorreto.')),
                  );
                  return;
                }

                Navigator.pop(context, novo);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    atualController.dispose();
    novoController.dispose();
    confirmarController.dispose();

    if (novoPin == null) {
      return;
    }

    await ServicoBancoDados.atualizarPin(novoPin);
    if (!mounted) {
      return;
    }
    setState(() => pin = '');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN atualizado com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teclas = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'face',
      '0',
      'back',
    ];

    return Scaffold(
      backgroundColor: TemaAplicativo.tealDark,
      appBar: AppBar(
        backgroundColor: TemaAplicativo.tealDark,
        title: const Text('Segurança'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight -
                    44,
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 52),
                  const SizedBox(height: 18),
                  Text(
                    widget.modoConfiguracao
                        ? 'Confirmar segurança'
                        : 'Digite seu PIN',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.modoConfiguracao
                        ? 'Confirme seu PIN de 6 dígitos ou use a biometria para validar o acesso.'
                        : 'Use o PIN de 6 dígitos ou a biometria do aparelho para acessar o Kazux.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final filled = index < pin.length;
                      return Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: filled ? Colors.white : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  if (carregando)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    TextButton.icon(
                      onPressed: _alterarPin,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Alterar PIN'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: teclas.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.55,
                        ),
                    itemBuilder: (context, index) {
                      final valor = teclas[index];
                      final isFace = valor == 'face';
                      final label = isFace
                          ? 'Face ID'
                          : valor == 'back'
                          ? '⌫'
                          : valor;
                      return Material(
                        color: Colors.white.withValues(
                          alpha: isFace && !biometriaDisponivel ? 0.04 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: carregando ? null : () => _tap(valor),
                          child: Center(
                            child: isFace
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fingerprint_rounded,
                                        color: biometriaDisponivel
                                            ? Colors.white
                                            : Colors.white38,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: biometriaDisponivel
                                              ? Colors.white70
                                              : Colors.white38,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    biometriaDisponivel
                        ? 'Biometria disponível neste aparelho.'
                        : 'No simulador, ative Face ID em Features > Face ID > Enrolled.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
