import 'package:local_auth/local_auth.dart';

class ServicoAutenticacaoLocal {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> podeUsarBiometria() async {
    try {
      final aparelhoSuporta = await _auth.isDeviceSupported();
      final biometriaDisponivel = await _auth.canCheckBiometrics;
      return aparelhoSuporta && biometriaDisponivel;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> autenticar() async {
    try {
      final disponivel = await podeUsarBiometria();
      if (!disponivel) {
        return false;
      }

      return _auth.authenticate(
        localizedReason: 'Use Face ID ou Touch ID para acessar o Kazux.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
