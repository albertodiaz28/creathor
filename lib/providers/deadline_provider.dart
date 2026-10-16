import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../models/deadline.dart';
import '../repositories/deadline_repository.dart';

enum CalendarView { week, month }

class DeadlineProvider extends ChangeNotifier {
  DeadlineProvider({DeadlineRepository? repo})
    : _repo = repo ?? DeadlineRepository();

  final DeadlineRepository _repo;

  List<Deadline> _all = [];
  bool _loaded = false;
  CalendarView _view = CalendarView.week;
  DeadlineType? _typeFilter;
  DateTime _anchor = dateOnly(DateTime.now());
  DateTime? _selectedDay;

  bool get loaded => _loaded;
  CalendarView get view => _view;
  DeadlineType? get typeFilter => _typeFilter;
  DateTime get anchor => _anchor;
  DateTime? get selectedDay => _selectedDay;
  List<Deadline> get all => _all;

  /// Lunes de la semana del ancla.
  DateTime get weekStart =>
      _anchor.subtract(Duration(days: _anchor.weekday - 1));

  List<DateTime> get weekDays =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  DateTime get rangeStart => _view == CalendarView.week
      ? weekStart
      : DateTime(_anchor.year, _anchor.month, 1);

  DateTime get rangeEnd => _view == CalendarView.week
      ? weekStart.add(const Duration(days: 7))
      : DateTime(_anchor.year, _anchor.month + 1, 1);

  /// Días del mes en curso (vista mes) para la tira horizontal.
  List<DateTime> get monthDays {
    final start = DateTime(_anchor.year, _anchor.month, 1);
    final end = DateTime(_anchor.year, _anchor.month + 1, 1);
    return List.generate(
      end.difference(start).inDays,
      (i) => start.add(Duration(days: i)),
    );
  }

  List<DateTime> get stripDays =>
      _view == CalendarView.week ? weekDays : monthDays;

  List<Deadline> get inRange => _all
      .where(
        (d) =>
            !d.dateTime.isBefore(rangeStart) && d.dateTime.isBefore(rangeEnd),
      )
      .toList();

  /// Eventos mostrados en el timeline tras aplicar día y tipo.
  List<Deadline> get visible => inRange.where((d) {
    if (_typeFilter != null && d.type != _typeFilter) return false;
    if (_selectedDay != null && !isSameDay(d.dateTime, _selectedDay!)) {
      return false;
    }
    return true;
  }).toList();

  List<Deadline> onDay(DateTime day) =>
      _all.where((d) => isSameDay(d.dateTime, day)).toList();

  int get keyDeliveriesInRange => inRange.where((d) => !d.done).length;

  /// Deadlines de draft pendientes de validación por la marca.
  List<Deadline> get awaitingApproval =>
      _all.where((d) => d.awaitingApproval && !d.done).toList();

  Future<void> load() async {
    _all = await _repo.all();
    _loaded = true;
    notifyListeners();
  }

  void setView(CalendarView v) {
    _view = v;
    _selectedDay = null;
    notifyListeners();
  }

  void setTypeFilter(DeadlineType? t) {
    _typeFilter = t;
    notifyListeners();
  }

  void selectDay(DateTime? d) {
    _selectedDay =
        (d != null && _selectedDay != null && isSameDay(d, _selectedDay!))
        ? null
        : d;
    notifyListeners();
  }

  void shift(int direction) {
    _anchor = _view == CalendarView.week
        ? _anchor.add(Duration(days: 7 * direction))
        : DateTime(_anchor.year, _anchor.month + direction, 1);
    _selectedDay = null;
    notifyListeners();
  }

  void goToday() {
    _anchor = dateOnly(DateTime.now());
    _selectedDay = null;
    notifyListeners();
  }

  Future<void> add(Deadline d, {List<String> tasks = const []}) async {
    await _repo.insert(d, tasks: tasks);
    await load();
  }

  Future<void> update(Deadline d) async {
    await _repo.update(d);
    await load();
  }

  Future<void> toggleDone(Deadline d) async {
    await _repo.update(d.copyWith(done: !d.done, awaitingApproval: false));
    await load();
  }

  Future<void> markAwaiting(Deadline d, bool awaiting) async {
    await _repo.update(d.copyWith(awaitingApproval: awaiting));
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> toggleTask(DeadlineTask t) async {
    await _repo.updateTask(t.copyWith(done: !t.done));
    await load();
  }

  Future<void> addTask(int deadlineId, String label) async {
    await _repo.addTask(deadlineId, label);
    await load();
  }

  Future<void> deleteTask(int id) async {
    await _repo.deleteTask(id);
    await load();
  }
}
