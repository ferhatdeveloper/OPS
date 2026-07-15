import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../service/gamification_service.dart';

class GamificationState {
  final int level;
  final int points;
  final int pointsToNextLevel;
  final double nextLevelProgress;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;

  GamificationState({
    required this.level,
    required this.points,
    required this.pointsToNextLevel,
    required this.nextLevelProgress,
    required this.leaderboard,
    this.isLoading = false,
  });

  GamificationState copyWith({
    int? level,
    int? points,
    int? pointsToNextLevel,
    double? nextLevelProgress,
    List<LeaderboardEntry>? leaderboard,
    bool? isLoading,
  }) {
    return GamificationState(
      level: level ?? this.level,
      points: points ?? this.points,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
      nextLevelProgress: nextLevelProgress ?? this.nextLevelProgress,
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LeaderboardEntry {
  final String name;
  final int points;
  final int rank;
  final String? avatar;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.name,
    required this.points,
    required this.rank,
    this.avatar,
    this.isCurrentUser = false,
  });
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier()
      : super(GamificationState(
          level: 1,
          points: 0,
          pointsToNextLevel: 1000,
          nextLevelProgress: 0.0,
          leaderboard: [],
          isLoading: true,
        )) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true);
    final service = GamificationService();
    final stats = await service.getPlayerStats('current_user'); // ID will be dynamic later

    // Mock leaderboard data for now until we have a real backend service for others
    final mockLeaderboard = [
      LeaderboardEntry(name: 'Ahmet Y.', points: 12500, rank: 1),
      LeaderboardEntry(name: 'Selin K.', points: 11200, rank: 2),
      LeaderboardEntry(name: 'Mehmet A.', points: 10800, rank: 3),
      LeaderboardEntry(name: 'Siz', points: stats['points'], rank: 4, isCurrentUser: true),
      LeaderboardEntry(name: 'Canan B.', points: 9500, rank: 5),
    ];

    state = state.copyWith(
      level: stats['level'],
      points: stats['points'],
      pointsToNextLevel: 1000, // Fixed for now
      nextLevelProgress: (stats['points'] % 1000) / 1000,
      leaderboard: mockLeaderboard,
      isLoading: false,
    );
  }

  Future<void> addPoints(int points, String reason) async {
    final service = GamificationService();
    await service.addPoints('current_user', points, reason);
    await loadStats();
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
