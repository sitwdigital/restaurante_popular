import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../services/push_notifications_service.dart';

const kBlue       = Color(0xFF006395);
const kBlueDark   = Color(0xFF204181);
const kGreen      = Color(0xFF009C47);
const kRed        = Color(0xFFB7292F);
const kBg         = Color(0xFFF2F3F5);
const kText       = Color(0xFF333333);

const _homeBox       = 'home_cache_box';
const _notifListKey  = 'notifications_list';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    final box = await Hive.openBox(_homeBox);
    final raw = (box.get(_notifListKey) as List?)?.whereType<Map>().toList() ?? [];
    final list = raw.map(AppNotification.fromMap).toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await PushNotificationsService.markAllRead();
    await _loadFromHive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBlue,
        elevation: 0.5,
        title: const Text('Notificações',
          style: TextStyle(color: kBlueDark, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _items.any((e) => !e.read) ? _markAllRead : null,
            child: const Text('Marcar tudo como lido'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFromHive,
              child: _items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _NotificationCard(n: _items[i]),
                    ),
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(n.createdAt);
    final leadingColor = switch (n.type) {
      'unidade_adicionada' => kGreen,
      'manutencao'         => Colors.orange,
      'alerta'             => kRed,
      _                    => kBlue,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone/indicador
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: leadingColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                n.type == 'unidade_adicionada' ? Icons.store_mall_directory_rounded
                : n.type == 'manutencao'      ? Icons.build_rounded
                : n.type == 'alerta'          ? Icons.warning_amber_rounded
                : Icons.notifications_active_rounded,
                color: leadingColor,
              ),
            ),
            const SizedBox(width: 12),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(n.title,
                        style: const TextStyle(
                          color: kText, fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                    if (!n.read)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: kBlue, shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Text(n.message,
                    style: const TextStyle(color: kText, fontSize: 13, height: 1.35)),
                  const SizedBox(height: 8),
                  Text(date,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Icon(Icons.notifications_none_rounded, size: 64, color: kBlueDark),
        SizedBox(height: 12),
        Center(child: Text('Sem notificações por aqui',
            style: TextStyle(color: kText, fontWeight: FontWeight.w700))),
        SizedBox(height: 6),
        Center(child: Text('Quando houver novidades, elas aparecem aqui.',
            style: TextStyle(color: kText))),
      ],
    );
  }
}
