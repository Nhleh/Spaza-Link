/// Advertisement record managed by the admin. Mirrors the `advertisements`
/// table. Kept local to the admin app (only `spazalink_core` is shared).
class Advertisement {
  const Advertisement({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.active = true,
    this.startsAt,
    this.endsAt,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool active;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int sortOrder;
  final DateTime? createdAt;

  bool get isEmpty => id.isEmpty;

  /// True when the ad would currently be visible to customers.
  bool get isLive {
    if (!active) return false;
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  factory Advertisement.fromRow(Map<String, dynamic> r) {
    DateTime? dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return Advertisement(
      id: r['id'] as String? ?? '',
      title: r['title'] as String? ?? '',
      imageUrl: r['image_url'] as String? ?? '',
      linkUrl: r['link_url'] as String?,
      active: r['active'] as bool? ?? true,
      startsAt: dt(r['starts_at']),
      endsAt: dt(r['ends_at']),
      sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: dt(r['created_at']),
    );
  }

  Map<String, dynamic> toRow() => {
        'title': title,
        'image_url': imageUrl,
        'link_url': (linkUrl == null || linkUrl!.isEmpty) ? null : linkUrl,
        'active': active,
        'starts_at': startsAt?.toUtc().toIso8601String(),
        'ends_at': endsAt?.toUtc().toIso8601String(),
        'sort_order': sortOrder,
      };

  Advertisement copyWith({
    String? title,
    String? imageUrl,
    String? linkUrl,
    bool? active,
    DateTime? startsAt,
    DateTime? endsAt,
    int? sortOrder,
  }) =>
      Advertisement(
        id: id,
        title: title ?? this.title,
        imageUrl: imageUrl ?? this.imageUrl,
        linkUrl: linkUrl ?? this.linkUrl,
        active: active ?? this.active,
        startsAt: startsAt ?? this.startsAt,
        endsAt: endsAt ?? this.endsAt,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}
