import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Envia avisos do Kazux para a central de notificações do aparelho.
class ServicoNotificacoesLocais {
  ServicoNotificacoesLocais._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) {
      return;
    }
    const configuracao = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: configuracao);
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _inicializado = true;
  }

  static Future<void> mostrarAlertas(List<Map<String, dynamic>> alertas) async {
    if (alertas.isEmpty) {
      return;
    }
    await inicializar();
    for (var indice = 0; indice < alertas.length; indice++) {
      final alerta = alertas[indice];
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000) + indice,
        title: alerta['titulo'] as String,
        body: alerta['mensagem'] as String,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'alertas_gastos',
            'Alertas de gastos',
            channelDescription: 'Avisos sobre limites de gastos do Kazux',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}
