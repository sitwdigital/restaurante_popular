import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_notification.dart';
import '../screens/notifications_screen.dart';

const _homeBox = 'home_cache_box';
const _notifListKey = 'notifications_list';

class PushNotificationsService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Contador reativo para o badge do sininho
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Inicializa FCM + listeners (foreground/background)
  static Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    // iOS permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Mensagens quando app está em 1º plano
    FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
      await _storeFromMessage(m);
    });

    // App aberto por toque na notificação (do background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) async {
      await _storeFromMessage(m);
      // Navega direto para a tela de notificações
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    });

    // App iniciado a partir de uma notificação "morta" (terminated)
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      await _storeFromMessage(initial);
      // Agenda a navegação para o próximo frame (APÓS montar o app)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      });
    }

    // Handler em segundo plano (isolate) – Android
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Atualiza badge ao iniciar
    await _refreshUnreadCount();
  }

  /// Converte RemoteMessage -> AppNotification e salva no Hive
  static Future<void> _storeFromMessage(RemoteMessage m) async {
    try {
      final box = await Hive.openBox(_homeBox);

      // Carrega lista atual
      final raw = (box.get(_notifListKey) as List?)?.whereType<Map>().toList() ?? [];
      final list = raw.map(AppNotification.fromMap).toList();

      final now = DateTime.now();

      // Título/corpo podem vir em notification ou em data
      final title = (m.notification?.title ??
          m.data['title'] ??
          'Atualização').toString();

      final body = (m.notification?.body ??
          m.data['message'] ??
          m.data['body'] ??
          'Você recebeu uma atualização.').toString();

      final type = (m.data['type'] ?? 'generic').toString();

      final id = m.messageId ?? 'msg_${now.millisecondsSinceEpoch}';

      // Evita duplicado por messageId
      final already = list.any((n) => n.id == id);
      if (!already) {
        list.insert(
          0,
          AppNotification(
            id: id,
            title: title,
            message: body,
            createdAt: now,
            type: type,
            read: false,
          ),
        );
        await box.put(_notifListKey, list.map((e) => e.toMap()).toList());
        await _refreshUnreadCount();
      }
    } catch (_) {
      // ignore
    }
  }

  /// Recalcula contagem não lida
  static Future<void> _refreshUnreadCount() async {
    try {
      final box = await Hive.openBox(_homeBox);
      final raw = (box.get(_notifListKey) as List?)?.whereType<Map>().toList() ?? [];
      final list = raw.map(AppNotification.fromMap).toList();
      unreadCount.value = list.where((n) => !n.read).length;
    } catch (_) {}
  }

  /// Marca todas como lidas (usado pela tela)
  static Future<void> markAllRead() async {
    final box = await Hive.openBox(_homeBox);
    final raw = (box.get(_notifListKey) as List?)?.whereType<Map>().toList() ?? [];
    final list = raw.map(AppNotification.fromMap).toList();
    for (final n in list) {
      n.read = true;
    }
    await box.put(_notifListKey, list.map((e) => e.toMap()).toList());
    await _refreshUnreadCount();
  }
}

/// Handler de mensagens em segundo plano (isolate separado)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa Hive manualmente no isolate
  try {
    WidgetsFlutterBinding.ensureInitialized();

    Directory dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);

    await PushNotificationsService._storeFromMessage(message);
  } catch (_) {
    // Em último caso, ignore falha no background
  }
}
