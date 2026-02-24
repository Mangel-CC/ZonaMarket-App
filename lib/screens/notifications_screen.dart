import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingRead = false;
  bool _isDeletingAll = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final data = await ProductService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _isMarkingRead = true);
    final success = await ProductService.markNotificationsRead();
    if (mounted) {
      setState(() => _isMarkingRead = false);
      if (success) {
        // Update local state: mark all as read
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            _notifications[i] = Map<String, dynamic>.from(_notifications[i])
              ..['leida'] = 1;
          }
        });
        _showSnackBar('Notificaciones marcadas como leidas');
      } else {
        _showSnackBar('No se pudieron marcar como leidas', isError: true);
      }
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar notificaciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        content: const Text(
          'Se eliminaran todas las notificaciones. Esta accion no se puede deshacer.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeletingAll = true);
    final success = await ProductService.deleteAllNotifications();
    if (mounted) {
      setState(() => _isDeletingAll = false);
      if (success) {
        setState(() => _notifications = []);
        _showSnackBar('Notificaciones eliminadas');
      } else {
        _showSnackBar('No se pudieron eliminar', isError: true);
      }
    }
  }

  Future<void> _deleteSingle(int id, int index) async {
    final removed = _notifications[index];
    setState(() => _notifications.removeAt(index));

    final success = await ProductService.deleteNotification(id);
    if (!success && mounted) {
      setState(() => _notifications.insert(index, removed));
      _showSnackBar('No se pudo eliminar la notificacion', isError: true);
    }
  }

  bool _isRead(Map<String, dynamic> n) {
    final leida = n['leida'];
    if (leida is int) return leida == 1;
    if (leida is bool) return leida;
    return false;
  }

  int get _unreadCount => _notifications.where((n) => !_isRead(n)).length;

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Ahora';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? AppColors.destructive : AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _notifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationItem(
                    _notifications[index],
                    index,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!_isLoading && _unreadCount > 0)
                      Text(
                        '$_unreadCount sin leer',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (!_isLoading)
                      Text(
                        '${_notifications.length} ${_notifications.length == 1 ? 'notificacion' : 'notificaciones'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              if (_notifications.isNotEmpty && !_isLoading) ...[
                // Mark all as read
                if (_unreadCount > 0)
                  IconButton(
                    onPressed: _isMarkingRead ? null : _markAllRead,
                    icon: _isMarkingRead
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                        : const Icon(
                      Icons.done_all_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Marcar todo como leido',
                    splashRadius: 20,
                  ),
                // Delete all
                IconButton(
                  onPressed: _isDeletingAll ? null : _deleteAll,
                  icon: _isDeletingAll
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.destructive,
                    ),
                  )
                      : const Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: AppColors.destructive,
                  ),
                  tooltip: 'Eliminar todas',
                  splashRadius: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 36,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando tengas actividad nueva\naparecera aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif, int index) {
    final id = notif['id'] is int
        ? notif['id'] as int
        : int.tryParse(notif['id']?.toString() ?? '') ?? 0;
    final mensaje = notif['mensaje'] as String? ?? '';
    final fecha = notif['fecha'] as String? ?? '';
    final read = _isRead(notif);

    return Dismissible(
      key: ValueKey('notif-$id'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteSingle(id, index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppColors.card : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: read ? AppColors.border : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: read
                    ? AppColors.secondary
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                read
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded,
                size: 22,
                color: read ? AppColors.mutedForeground : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: read ? FontWeight.w400 : FontWeight.w600,
                      color: AppColors.foreground,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fecha.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(fecha),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Unread dot
            if (!read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
