import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum DeadlineType {
  shoot('rodaje', 'Rodaje', '🎥', Icons.videocam_outlined),
  draft('draft', 'Entrega Draft', '📝', Icons.rate_review_outlined),
  publish('publicacion', 'Publicación', '🚀', Icons.rocket_launch_outlined);

  const DeadlineType(this.db, this.label, this.emoji, this.icon);
  final String db;
  final String label;
  final String emoji;
  final IconData icon;

  static DeadlineType fromDb(String v) =>
      values.firstWhere((e) => e.db == v, orElse: () => shoot);

  Color get dotColor => switch (this) {
    shoot => AppColors.secondary,
    draft => AppColors.onTertiaryContainer,
    publish => AppColors.secondaryFixedDim,
  };

  Color get chipBg => switch (this) {
    shoot => AppColors.secondaryContainer.withValues(alpha: 0.4),
    draft => AppColors.tertiaryFixed,
    publish => AppColors.secondaryContainer.withValues(alpha: 0.4),
  };

  Color get chipFg => switch (this) {
    shoot => AppColors.onSecondaryContainer,
    draft => AppColors.onTertiaryFixed,
    publish => AppColors.onSecondaryContainer,
  };
}

class DeadlineTask {
  const DeadlineTask({
    this.id,
    required this.deadlineId,
    required this.label,
    this.done = false,
  });

  final int? id;
  final int deadlineId;
  final String label;
  final bool done;

  DeadlineTask copyWith({bool? done}) => DeadlineTask(
    id: id,
    deadlineId: deadlineId,
    label: label,
    done: done ?? this.done,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'deadline_id': deadlineId,
    'label': label,
    'done': done ? 1 : 0,
  };

  static DeadlineTask fromMap(Map<String, Object?> m) => DeadlineTask(
    id: m['id'] as int?,
    deadlineId: m['deadline_id'] as int,
    label: m['label'] as String,
    done: (m['done'] as int) == 1,
  );
}

class Deadline {
  const Deadline({
    this.id,
    this.campaignId,
    required this.title,
    required this.type,
    required this.dateTime,
    this.description,
    this.allDay = false,
    this.done = false,
    this.awaitingApproval = false,
    this.tasks = const [],
    this.brand,
  });

  final int? id;
  final int? campaignId;
  final String title;
  final String? description;
  final DeadlineType type;
  final DateTime dateTime;
  final bool allDay;
  final bool done;

  /// Borrador entregado y pendiente de validación por la marca.
  final bool awaitingApproval;
  final List<DeadlineTask> tasks;

  /// Marca de la campaña asociada (join), solo lectura.
  final String? brand;

  bool get isUrgent {
    if (done) return false;
    final diff = dateTime.difference(DateTime.now());
    return diff.inHours <= 36 && diff.inHours >= -24;
  }

  bool get isOverdue => !done && dateTime.isBefore(DateTime.now());

  int get tasksDone => tasks.where((t) => t.done).length;

  Deadline copyWith({
    String? title,
    String? description,
    DeadlineType? type,
    DateTime? dateTime,
    bool? allDay,
    bool? done,
    bool? awaitingApproval,
    List<DeadlineTask>? tasks,
    String? brand,
    int? campaignId,
  }) => Deadline(
    id: id,
    campaignId: campaignId ?? this.campaignId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    dateTime: dateTime ?? this.dateTime,
    allDay: allDay ?? this.allDay,
    done: done ?? this.done,
    awaitingApproval: awaitingApproval ?? this.awaitingApproval,
    tasks: tasks ?? this.tasks,
    brand: brand ?? this.brand,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'campaign_id': campaignId,
    'title': title,
    'description': description,
    'type': type.db,
    'date_time': dateTime.toIso8601String(),
    'all_day': allDay ? 1 : 0,
    'done': done ? 1 : 0,
    'awaiting_approval': awaitingApproval ? 1 : 0,
  };

  static Deadline fromMap(Map<String, Object?> m) => Deadline(
    id: m['id'] as int?,
    campaignId: m['campaign_id'] as int?,
    title: m['title'] as String,
    description: m['description'] as String?,
    type: DeadlineType.fromDb(m['type'] as String),
    dateTime: DateTime.parse(m['date_time'] as String),
    allDay: (m['all_day'] as int) == 1,
    done: (m['done'] as int) == 1,
    awaitingApproval: (m['awaiting_approval'] as int) == 1,
    brand: m['brand'] as String?,
  );
}
