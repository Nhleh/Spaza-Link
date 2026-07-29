import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import '../data/admin_messaging_repository.dart';
import '../providers/messaging_provider.dart';

class AdminCommunicationScreen extends ConsumerStatefulWidget {
  const AdminCommunicationScreen({super.key, this.initialOwnerId});

  /// When arriving from a shop's "Message owner" button.
  final String? initialOwnerId;

  @override
  ConsumerState<AdminCommunicationScreen> createState() =>
      _AdminCommunicationScreenState();
}

class _AdminCommunicationScreenState
    extends ConsumerState<AdminCommunicationScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _broadcast = true;
  String? _ownerId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialOwnerId != null) {
      _broadcast = false;
      _ownerId = widget.initialOwnerId;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      _snack('Title and message are required.', AppColors.error);
      return;
    }
    if (!_broadcast && (_ownerId == null || _ownerId!.isEmpty)) {
      _snack('Pick a shop owner to message.', AppColors.error);
      return;
    }
    setState(() => _sending = true);
    try {
      final repo = ref.read(adminMessagingRepositoryProvider);
      if (_broadcast) {
        await repo.sendBroadcast(_title.text, _body.text);
      } else {
        await repo.sendDirect(_ownerId!, _title.text, _body.text);
      }
      ref.invalidate(sentMessagesProvider);
      if (!mounted) return;
      _title.clear();
      _body.clear();
      _snack(
        _broadcast
            ? 'Broadcast sent to all customers.'
            : 'Message sent.',
        AppColors.brandGreenPrimary,
      );
    } catch (e) {
      _snack('Could not send: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    final owners = ref.watch(ownerOptionsProvider);
    final sent = ref.watch(sentMessagesProvider);

    return Scaffold(
      backgroundColor: AppColors.adminDarkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adminDarkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Communication',
            style: TextStyle(
                color: AppColors.darkOnSurface, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Send a message',
                    style: TextStyle(
                        color: AppColors.darkOnSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                // Audience toggle
                Row(children: [
                  _audienceBtn('All customers', Icons.campaign_rounded, true),
                  const SizedBox(width: 10),
                  _audienceBtn('One shop owner', Icons.person_rounded, false),
                ]),
                if (!_broadcast) ...[
                  const SizedBox(height: 16),
                  owners.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Could not load owners: $e',
                        style: const TextStyle(color: AppColors.error)),
                    data: (list) => _ownerDropdown(list),
                  ),
                ],
                const SizedBox(height: 16),
                _field(_title, 'Title', 'e.g. Public holiday delivery times'),
                const SizedBox(height: 12),
                _field(_body, 'Message', 'Write your message…', lines: 5),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_broadcast
                        ? 'Send to all customers'
                        : 'Send message'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandGreenPrimary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Sent',
              style: TextStyle(
                  color: AppColors.darkOnSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          sent.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                  color: AppColors.brandGreenPrimary),
            )),
            error: (e, _) => Text('Could not load: $e',
                style: const TextStyle(color: AppColors.error)),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No messages sent yet.',
                        style:
                            TextStyle(color: AppColors.darkOnSurfaceVariant)),
                  )
                : Column(children: list.map(_sentTile).toList()),
          ),
        ],
      ),
    );
  }

  Widget _audienceBtn(String label, IconData icon, bool broadcast) {
    final selected = _broadcast == broadcast;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _broadcast = broadcast),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandGreenPrimary.withValues(alpha: 0.15)
                : AppColors.adminDarkSurfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.brandGreenPrimary
                  : AppColors.adminDarkOutline,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 18,
                color: selected
                    ? AppColors.brandGreenPrimary
                    : AppColors.darkOnSurfaceVariant),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? AppColors.brandGreenPrimary
                        : AppColors.darkOnSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _ownerDropdown(List<OwnerOption> list) {
    return DropdownButtonFormField<String>(
      initialValue: _ownerId,
      isExpanded: true,
      dropdownColor: AppColors.adminDarkSurface,
      style: const TextStyle(color: AppColors.darkOnSurface),
      decoration: _inputDecoration('Shop owner', null),
      hint: const Text('Select a shop owner',
          style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
      items: list
          .map((o) => DropdownMenuItem(
                value: o.ownerId,
                child: Text('${o.shopName} — ${o.ownerName}',
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _ownerId = v),
    );
  }

  Widget _field(TextEditingController c, String label, String hint,
      {int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      style: const TextStyle(color: AppColors.darkOnSurface),
      decoration: _inputDecoration(label, hint),
    );
  }

  InputDecoration _inputDecoration(String label, String? hint) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        hintStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        filled: true,
        fillColor: AppColors.adminDarkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.adminDarkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.adminDarkOutline),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
        ),
        child: child,
      );

  Widget _sentTile(SentMessage m) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.adminDarkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.adminDarkOutline, width: 0.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(m.isBroadcast ? Icons.campaign_rounded : Icons.person_rounded,
              size: 18, color: AppColors.brandGreenPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title,
                  style: const TextStyle(
                      color: AppColors.darkOnSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(m.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.darkOnSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${m.isBroadcast ? 'All customers' : 'Direct'} · '
                '${m.createdAt.day}/${m.createdAt.month}/${m.createdAt.year}',
                style: const TextStyle(
                    color: AppColors.darkOnSurfaceVariant, fontSize: 11),
              ),
            ]),
          ),
        ]),
      );
}
