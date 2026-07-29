import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/messages_repository.dart';
import '../providers/messages_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(messagesProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.brandGreenPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreenPrimary,
        onRefresh: () async => ref.invalidate(messagesProvider),
        child: async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.brandGreenPrimary)),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Could not load messages.\n$e',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.lightOnSurfaceVariant),
                ),
              ),
            ),
          ]),
          data: (messages) {
            if (messages.isEmpty) return const _EmptyInbox();
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: messages.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _MessageTile(message: messages[i]),
            );
          },
        ),
      ),
    );
  }
}

class _MessageTile extends ConsumerWidget {
  const _MessageTile({required this.message});
  final AdminMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: () async {
        if (!message.read) {
          await ref.read(messagesRepositoryProvider).markRead(message.id);
          ref.invalidate(messagesProvider);
        }
        if (context.mounted) _showDetail(context, message);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: message.read
                ? AppColors.lightOutlineVariant
                : AppColors.brandGreenPrimary,
            width: message.read ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandGreenSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                message.isBroadcast
                    ? Icons.campaign_rounded
                    : Icons.mail_rounded,
                color: AppColors.brandGreenPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: message.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!message.read)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.brandGreenPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.body,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.lightOnSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmt(message.createdAt),
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.lightOnSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, AdminMessage m) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                  m.isBroadcast
                      ? Icons.campaign_rounded
                      : Icons.mail_rounded,
                  color: AppColors.brandGreenPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text(m.isBroadcast ? 'Announcement' : 'Message',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.lightOnSurfaceVariant)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text(m.title,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text(_fmt(m.createdAt),
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.lightOnSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            Text(m.body,
                style: AppTypography.bodyMedium.copyWith(height: 1.5)),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 140),
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: AppColors.lightOutline),
        const SizedBox(height: AppSpacing.lg),
        Text('No messages yet',
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Updates and announcements from SpazaLink will appear here.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.lightOnSurfaceVariant),
        ),
      ],
    );
  }
}
