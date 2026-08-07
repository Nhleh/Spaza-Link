/// A Shop advertisement managed from the Admin dashboard. Only ads that are
/// active and within their optional schedule window reach the customer app
/// (enforced by RLS), so anything returned here is safe to display.
class AdvertisementModel {
  const AdvertisementModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.active = true,
    this.startsAt,
    this.endsAt,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool active;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int sortOrder;

  factory AdvertisementModel.fromRow(Map<String, dynamic> r) {
    DateTime? dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return AdvertisementModel(
      id: r['id'] as String? ?? '',
      title: r['title'] as String? ?? '',
      imageUrl: r['image_url'] as String? ?? '',
      linkUrl: r['link_url'] as String?,
      active: r['active'] as bool? ?? true,
      startsAt: dt(r['starts_at']),
      endsAt: dt(r['ends_at']),
      sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
