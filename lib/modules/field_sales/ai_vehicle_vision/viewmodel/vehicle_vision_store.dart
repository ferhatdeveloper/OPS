// Dosya Adı: vehicle_vision_store.dart
// Açıklama: Araç vision dens state + SQLite vehicles kaydı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../vehicles/viewmodel/vehicle_card_store.dart';
import '../engine/vehicle_vision_analyzer.dart';
import '../model/vehicle_vision_result.dart';

/// {@template vehicle_vision_phase}
/// Ekran aşaması.
/// {@endtemplate}
enum VehicleVisionPhase {
  /// Fotoğraf bekleniyor
  idle,

  /// Analiz çalışıyor
  analyzing,

  /// Form doğrulama
  review,

  /// Kaydediliyor
  saving,
}

/// {@template vehicle_vision_state}
/// Dens araç vision durumu.
/// {@endtemplate}
class VehicleVisionState {
  /// [phase]
  final VehicleVisionPhase phase;

  /// [vehicle]
  final VehicleVisionResult? vehicle;

  /// [thumb]
  final Uint8List? thumb;

  /// [statusKey]
  final String? statusKey;

  /// {@macro vehicle_vision_state}
  const VehicleVisionState({
    this.phase = VehicleVisionPhase.idle,
    this.vehicle,
    this.thumb,
    this.statusKey,
  });

  VehicleVisionState copyWith({
    VehicleVisionPhase? phase,
    VehicleVisionResult? vehicle,
    Uint8List? thumb,
    String? statusKey,
    bool clearStatus = false,
    bool clearVehicle = false,
  }) {
    return VehicleVisionState(
      phase: phase ?? this.phase,
      vehicle: clearVehicle ? null : (vehicle ?? this.vehicle),
      thumb: thumb ?? this.thumb,
      statusKey: clearStatus ? null : (statusKey ?? this.statusKey),
    );
  }
}

/// {@template vehicle_vision_store}
/// Analiz + düzenlenebilir form + vehicles upsert.
/// Genişletilmiş alanlar SharedPreferences’te tutulur.
/// {@endtemplate}
class VehicleVisionStore {
  static const _prefsKey = 'ai_vehicle_vision_records_v1';

  final VehicleVisionAnalyzer _analyzer;
  final Uuid _uuid;
  final VehicleCardStore _vehicleCards;

  VehicleVisionState _state = const VehicleVisionState();

  /// {@macro vehicle_vision_store}
  VehicleVisionStore({
    VehicleVisionAnalyzer? analyzer,
    Uuid? uuid,
    VehicleCardStore? vehicleCards,
  })  : _analyzer = analyzer ?? VehicleVisionAnalyzer(),
        _uuid = uuid ?? const Uuid(),
        _vehicleCards = vehicleCards ?? VehicleCardStore();

  VehicleVisionState get state => _state;

  void setPhase(VehicleVisionPhase phase) {
    _state = _state.copyWith(phase: phase);
  }

  void setStatusKey(String? key) {
    _state = _state.copyWith(
      statusKey: key,
      clearStatus: key == null,
    );
  }

  void updateVehicle(VehicleVisionResult vehicle) {
    _state = _state.copyWith(
      vehicle: vehicle,
      phase: VehicleVisionPhase.review,
    );
  }

  /// Fotoğraf → AI analiz
  Future<void> analyzeBytes({
    required Uint8List bytes,
    required String imageBase64,
    String imageMimeType = 'image/jpeg',
  }) async {
    _state = _state.copyWith(
      phase: VehicleVisionPhase.analyzing,
      thumb: bytes,
      clearStatus: true,
      clearVehicle: true,
    );
    final result = await _analyzer.analyzeImage(
      imageBase64: imageBase64,
      imageMimeType: imageMimeType,
    );
    if (!result.isOk) {
      _state = _state.copyWith(
        phase: VehicleVisionPhase.idle,
        statusKey: result.l10nKey ?? 'ai.request_failed',
      );
      return;
    }
    _state = _state.copyWith(
      phase: VehicleVisionPhase.review,
      vehicle: result.vehicle,
      clearStatus: true,
    );
  }

  /// Plaka zorunlu; vehicles + yerel kayıt.
  Future<bool> save({required VehicleVisionResult edited}) async {
    final plate = edited.plate.trim();
    if (plate.isEmpty) {
      _state = _state.copyWith(
        statusKey: 'field_sales.ai_vehicle_vision.need_plate',
      );
      return false;
    }
    _state = _state.copyWith(phase: VehicleVisionPhase.saving);
    try {
      final name = edited.displayName;
      final card = await _vehicleCards.upsertByPlate(
        plate: plate,
        name: name,
      );
      if (card == null) {
        _state = _state.copyWith(
          phase: VehicleVisionPhase.review,
          statusKey: 'field_sales.ai_vehicle_vision.need_plate',
        );
        return false;
      }

      await _appendLocalRecord(
        vehicleId: card.id,
        result: edited.copyWith(
          plate: plate.toUpperCase(),
          manualOverride: true,
          confidence: 1,
        ),
      );

      _state = _state.copyWith(
        phase: VehicleVisionPhase.idle,
        vehicle: edited.copyWith(
          plate: plate.toUpperCase(),
          manualOverride: true,
          confidence: 1,
        ),
        statusKey: 'field_sales.ai_vehicle_vision.saved',
      );
      return true;
    } catch (_) {
      _state = _state.copyWith(
        phase: VehicleVisionPhase.review,
        statusKey: 'field_sales.ai_vehicle_vision.err_save',
      );
      return false;
    }
  }

  Future<void> _appendLocalRecord({
    required String vehicleId,
    required VehicleVisionResult result,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final list = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              list.add(Map<String, dynamic>.from(e));
            }
          }
        }
      } catch (_) {}
    }
    list.insert(0, {
      'id': _uuid.v4(),
      'vehicle_id': vehicleId,
      'saved_at': DateTime.now().toIso8601String(),
      ...result.toJson(),
    });
    if (list.length > 100) {
      list.removeRange(100, list.length);
    }
    await prefs.setString(_prefsKey, jsonEncode(list));
  }
}
