import 'package:flutter/foundation.dart';

enum ThreatType { promptInjection, sybilCollusion, priceFreeze }

class ThreatEvent {
  final ThreatType type;
  final String title;
  final String detail;
  final DateTime at;

  ThreatEvent({
    required this.type,
    required this.title,
    required this.detail,
    DateTime? at,
  }) : at = at ?? DateTime.now();
}

class ThreatLogStore extends ChangeNotifier {
  ThreatLogStore._();
  static final ThreatLogStore instance = ThreatLogStore._();

  final List<ThreatEvent> _events = [];
  List<ThreatEvent> get events => List.unmodifiable(_events);

  void add(ThreatEvent event) {
    _events.insert(0, event);
    notifyListeners();
  }
}
