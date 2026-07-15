// Dosya Adı: loading_provider.dart
// Açıklama: Yükleme durumunu yöneten provider
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// {@template LoadingState}
/// Yükleme durumunu temsil eden sınıf
/// {@endtemplate}
class LoadingState {
  final String message;
  final double progress;
  final bool isLoading;

  const LoadingState({
    this.message = '',
    this.progress = 0.0,
    this.isLoading = false,
  });

  LoadingState copyWith({
    String? message,
    double? progress,
    bool? isLoading,
  }) {
    return LoadingState(
      message: message ?? this.message,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// {@template LoadingNotifier}
/// Yükleme durumunu yöneten notifier
/// {@endtemplate}
class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(const LoadingState());

  void startLoading(String message) {
    state = state.copyWith(
      message: message,
      progress: 0.0,
      isLoading: true,
    );
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }

  void stopLoading() {
    state = state.copyWith(
      message: '',
      progress: 0.0,
      isLoading: false,
    );
  }
}

/// Yükleme durumunu sağlayan provider
final loadingProvider =
    StateNotifierProvider<LoadingNotifier, LoadingState>((ref) {
  return LoadingNotifier();
});

/// {@template ForceLogoutState}
/// Force logout (oturum devralma) durumunu temsil eden sınıf
/// {@endtemplate}
class ForceLogoutState {
  final bool isActive;
  final String? message;
  final void Function(bool accepted)? onResult;

  const ForceLogoutState({
    this.isActive = false,
    this.message,
    this.onResult,
  });

  ForceLogoutState copyWith({
    bool? isActive,
    String? message,
    void Function(bool accepted)? onResult,
  }) {
    return ForceLogoutState(
      isActive: isActive ?? this.isActive,
      message: message ?? this.message,
      onResult: onResult ?? this.onResult,
    );
  }
}

/// {@template ForceLogoutNotifier}
/// Force logout durumunu yöneten notifier
/// {@endtemplate}
class ForceLogoutNotifier extends StateNotifier<ForceLogoutState> {
  ForceLogoutNotifier() : super(const ForceLogoutState());

  void show(String message, void Function(bool accepted) onResult) {
    state =
        ForceLogoutState(isActive: true, message: message, onResult: onResult);
  }

  void hide() {
    state = const ForceLogoutState();
  }
}

/// Force logout durumunu sağlayan provider
final forceLogoutProvider =
    StateNotifierProvider<ForceLogoutNotifier, ForceLogoutState>((ref) {
  return ForceLogoutNotifier();
});
