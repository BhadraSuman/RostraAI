import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/timetable_models.dart';
import 'timetable_storage.dart';

class FirestoreSyncService {
  static FirebaseFirestore? _db;
  static bool _initialized = false;

  static bool get isAvailable => _initialized && _db != null;

  static void initialize() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _db = FirebaseFirestore.instance;
        _db!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _initialized = true;
        debugPrint('FirestoreSyncService initialized with offline persistence.');
      }
    } catch (e) {
      debugPrint('FirestoreSyncService initialization note: $e');
      _initialized = false;
    }
  }

  // --- Real-Time Stream for Today's Class Changes (CR & Student) ---
  static Stream<DocumentSnapshot<Map<String, dynamic>>>? streamTodayChanges({
    required String pageId,
    required String date,
  }) {
    if (!isAvailable) return null;
    try {
      return _db!
          .collection('pages')
          .doc(pageId)
          .collection('days')
          .doc(date)
          .snapshots();
    } catch (e) {
      debugPrint('Error streaming today changes: $e');
      return null;
    }
  }

  // --- Push Status Change (CR) ---
  static Future<void> syncStatus({
    required String pageId,
    required String date,
    required ClassStatus status,
  }) async {
    if (!isAvailable) return;
    try {
      final docRef = _db!
          .collection('pages')
          .doc(pageId)
          .collection('days')
          .doc(date);

      await docRef.set({
        'statuses': {
          status.entryId: status.toMap(),
        },
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Synced status for ${status.entryId} to Firestore.');
    } catch (e) {
      debugPrint('Failed to sync status to Firestore (offline queue): $e');
    }
  }

  // --- Push Day Override / Holiday (CR) ---
  static Future<void> syncDayOverride({
    required String pageId,
    required DayOverride override,
  }) async {
    if (!isAvailable) return;
    try {
      final docRef = _db!
          .collection('pages')
          .doc(pageId)
          .collection('days')
          .doc(override.date);

      await docRef.set({
        'dayOverride': override.toMap(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Synced day override for ${override.date} to Firestore.');
    } catch (e) {
      debugPrint('Failed to sync day override to Firestore: $e');
    }
  }

  // --- Push Timetable Weekly Schedule (CR) ---
  static Future<void> syncTimetable({
    required String pageId,
    required List<TimetableEntry> entries,
  }) async {
    if (!isAvailable) return;
    try {
      final docRef = _db!
          .collection('pages')
          .doc(pageId)
          .collection('meta')
          .doc('timetable');

      await docRef.set({
        'entries': entries.map((e) => e.toMap()).toList(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Synced weekly timetable to Firestore.');
    } catch (e) {
      debugPrint('Failed to sync timetable: $e');
    }
  }

  // --- Fetch Cloud Timetable if Available ---
  static Future<List<TimetableEntry>?> fetchTimetable({
    required String pageId,
  }) async {
    if (!isAvailable) return null;
    try {
      final snap = await _db!
          .collection('pages')
          .doc(pageId)
          .collection('meta')
          .doc('timetable')
          .get();

      if (snap.exists && snap.data() != null) {
        final raw = snap.data()!['entries'] as List<dynamic>?;
        if (raw != null) {
          return raw
              .map((m) => TimetableEntry.fromMap(m as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching cloud timetable: $e');
    }
    return null;
  }

  // --- Bind Firestore Stream to Local Storage & State ---
  static StreamSubscription? bindLiveListener({
    required String pageId,
    required String date,
    required TimetableStorage storage,
    required void Function(Map<String, ClassStatus> statuses, DayOverride? override) onUpdate,
  }) {
    final stream = streamTodayChanges(pageId: pageId, date: date);
    if (stream == null) return null;

    return stream.listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;
      final data = snapshot.data()!;

      // Parse statuses
      final rawStatuses = data['statuses'] as Map<String, dynamic>? ?? {};
      final parsedStatuses = <String, ClassStatus>{};
      rawStatuses.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          final status = ClassStatus.fromMap(val);
          parsedStatuses[key] = status;
          storage.setStatusForEntry(date: date, status: status);
        }
      });

      // Parse day override
      DayOverride? parsedOverride;
      if (data['dayOverride'] is Map<String, dynamic>) {
        parsedOverride = DayOverride.fromMap(data['dayOverride'] as Map<String, dynamic>);
        storage.saveDayOverride(parsedOverride);
      }

      onUpdate(parsedStatuses, parsedOverride);
    }, onError: (err) {
      debugPrint('Firestore live listener error: $err');
    });
  }
}
