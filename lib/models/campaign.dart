enum CampaignStatus {
  production('production', 'En producción'),
  pending('pending', 'Pendiente de cobro'),
  paid('paid', 'Cobrada');

  const CampaignStatus(this.db, this.label);
  final String db;
  final String label;

  static CampaignStatus fromDb(String v) =>
      values.firstWhere((e) => e.db == v, orElse: () => production);
}

enum PaymentTerms {
  days30('30', '30 días', 'Estándar', 30),
  days60('60', '60 días', 'Corporativo', 60),
  upfront50('50', '50% upfront', 'Con anticipo', 30);

  const PaymentTerms(this.db, this.label, this.hint, this.days);
  final String db;
  final String label;
  final String hint;
  final int days;

  static PaymentTerms fromDb(String v) =>
      values.firstWhere((e) => e.db == v, orElse: () => days30);
}

class Campaign {
  const Campaign({
    this.id,
    required this.brand,
    required this.title,
    required this.grossFee,
    required this.agencyPct,
    required this.taxPct,
    required this.terms,
    required this.status,
    required this.createdAt,
    this.invoiceDate,
    this.dueDate,
    this.draftDeadline,
    this.publishDate,
    this.contactName,
    this.contactRole,
    this.agencyName,
    this.note,
  });

  final int? id;
  final String brand;
  final String title;
  final double grossFee;
  final double agencyPct;
  final double taxPct;
  final PaymentTerms terms;
  final CampaignStatus status;
  final DateTime createdAt;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final DateTime? draftDeadline;
  final DateTime? publishDate;
  final String? contactName;
  final String? contactRole;
  final String? agencyName;
  final String? note;

  double get agencyCut => grossFee * agencyPct / 100;
  double get taxCut => grossFee * taxPct / 100;
  double get net => (grossFee - agencyCut - taxCut).clamp(0, double.infinity);
  double get netPct => grossFee == 0 ? 0 : net / grossFee * 100;

  Campaign copyWith({
    int? id,
    String? brand,
    String? title,
    double? grossFee,
    double? agencyPct,
    double? taxPct,
    PaymentTerms? terms,
    CampaignStatus? status,
    DateTime? createdAt,
    DateTime? invoiceDate,
    DateTime? dueDate,
    DateTime? draftDeadline,
    DateTime? publishDate,
    String? contactName,
    String? contactRole,
    String? agencyName,
    String? note,
  }) => Campaign(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    title: title ?? this.title,
    grossFee: grossFee ?? this.grossFee,
    agencyPct: agencyPct ?? this.agencyPct,
    taxPct: taxPct ?? this.taxPct,
    terms: terms ?? this.terms,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    dueDate: dueDate ?? this.dueDate,
    draftDeadline: draftDeadline ?? this.draftDeadline,
    publishDate: publishDate ?? this.publishDate,
    contactName: contactName ?? this.contactName,
    contactRole: contactRole ?? this.contactRole,
    agencyName: agencyName ?? this.agencyName,
    note: note ?? this.note,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'brand': brand,
    'title': title,
    'gross_fee': grossFee,
    'agency_pct': agencyPct,
    'tax_pct': taxPct,
    'terms': terms.db,
    'status': status.db,
    'created_at': createdAt.toIso8601String(),
    'invoice_date': invoiceDate?.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'draft_deadline': draftDeadline?.toIso8601String(),
    'publish_date': publishDate?.toIso8601String(),
    'contact_name': contactName,
    'contact_role': contactRole,
    'agency_name': agencyName,
    'note': note,
  };

  static Campaign fromMap(Map<String, Object?> m) => Campaign(
    id: m['id'] as int?,
    brand: m['brand'] as String,
    title: m['title'] as String,
    grossFee: (m['gross_fee'] as num).toDouble(),
    agencyPct: (m['agency_pct'] as num).toDouble(),
    taxPct: (m['tax_pct'] as num).toDouble(),
    terms: PaymentTerms.fromDb(m['terms'] as String),
    status: CampaignStatus.fromDb(m['status'] as String),
    createdAt: DateTime.parse(m['created_at'] as String),
    invoiceDate: _date(m['invoice_date']),
    dueDate: _date(m['due_date']),
    draftDeadline: _date(m['draft_deadline']),
    publishDate: _date(m['publish_date']),
    contactName: m['contact_name'] as String?,
    contactRole: m['contact_role'] as String?,
    agencyName: m['agency_name'] as String?,
    note: m['note'] as String?,
  );

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}

enum DeliverableStatus {
  pending('pending', 'Pendiente'),
  draft('draft', 'Borrador'),
  approved('approved', 'Aprobado'),
  published('published', 'Publicado');

  const DeliverableStatus(this.db, this.label);
  final String db;
  final String label;

  static DeliverableStatus fromDb(String v) =>
      values.firstWhere((e) => e.db == v, orElse: () => pending);

  DeliverableStatus get next => switch (this) {
    pending => draft,
    draft => approved,
    approved => published,
    published => pending,
  };

  bool get isDone => this == approved || this == published;
}

class Deliverable {
  const Deliverable({
    this.id,
    required this.campaignId,
    required this.name,
    this.status = DeliverableStatus.pending,
    this.note,
  });

  final int? id;
  final int campaignId;
  final String name;
  final DeliverableStatus status;
  final String? note;

  Deliverable copyWith({DeliverableStatus? status, String? note}) =>
      Deliverable(
        id: id,
        campaignId: campaignId,
        name: name,
        status: status ?? this.status,
        note: note ?? this.note,
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'campaign_id': campaignId,
    'name': name,
    'status': status.db,
    'note': note,
  };

  static Deliverable fromMap(Map<String, Object?> m) => Deliverable(
    id: m['id'] as int?,
    campaignId: m['campaign_id'] as int,
    name: m['name'] as String,
    status: DeliverableStatus.fromDb(m['status'] as String),
    note: m['note'] as String?,
  );
}

/// Plantillas de entregables mostradas como chips en el formulario.
const kDeliverablePresets = <String>[
  '1x Reel IG',
  '3x Stories',
  '1x TikTok',
  'Derechos 3 meses',
  'Post Carrusel',
  '1x YouTube Short',
];
