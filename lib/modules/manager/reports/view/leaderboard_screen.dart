import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // Dummy gamification data
  final List<Map<String, dynamic>> _leaderboard = [
    {
      'id': '3', 
      'name': 'Mehmet Kaya', 
      'region': 'İç Anadolu', 
      'points': 8450, 
      'revenueTarget': 200000.0, 
      'revenueActual': 185000.0,
      'avatarColor': Colors.purple
    },
    {
      'id': '1', 
      'name': 'Ahmet Yılmaz', 
      'region': 'Marmara', 
      'points': 7200, 
      'revenueTarget': 150000.0, 
      'revenueActual': 160000.0, // Overachiever
      'avatarColor': Colors.blue
    },
    {
      'id': '4', 
      'name': 'Fatma Şahin', 
      'region': 'Akdeniz', 
      'points': 6100, 
      'revenueTarget': 120000.0, 
      'revenueActual': 90000.0,
      'avatarColor': Colors.orange
    },
    {
      'id': '2', 
      'name': 'Ayşe Demir', 
      'region': 'Ege', 
      'points': 4500, 
      'revenueTarget': 140000.0, 
      'revenueActual': 65000.0,
      'avatarColor': Colors.teal
    },
  ];

  @override
  void initState() {
    super.initState();
    // Sort by points descending
    _leaderboard.sort((a, b) => b['points'].compareTo(a['points']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(AppLocalization.of(context).translate('target.target_ranking'), style: const TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocalization.of(context).translate('target.share_ranking'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalization.of(context).translate('target.ranking_shared'))));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPodium(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
              itemBuilder: (context, index) {
                final rep = _leaderboard[index + 3];
                final rank = index + 4;
                return _buildListRow(context, rep, rank);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context) {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_leaderboard.length > 1) _buildPodiumBar(context, _leaderboard[1], 2, 120, Colors.grey.shade300),
          const SizedBox(width: 12),
          if (_leaderboard.isNotEmpty) _buildPodiumBar(context, _leaderboard[0], 1, 150, const Color(0xFFFFD700)), // Gold
          const SizedBox(width: 12),
          if (_leaderboard.length > 2) _buildPodiumBar(context, _leaderboard[2], 3, 100, const Color(0xFFCD7F32)), // Bronze
        ],
      ),
    );
  }

  Widget _buildPodiumBar(BuildContext context, Map<String, dynamic> rep, int rank, double height, Color medalColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 32 : 28,
              backgroundColor: rep['avatarColor'].withOpacity(0.2),
              child: Text(
                rep['name'].substring(0, 1),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: rank == 1 ? 24 : 20, color: rep['avatarColor']),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: medalColor, shape: BoxShape.circle, border: Border.all(color: isDarkMode ? Colors.transparent : Colors.white, width: 2)),
              child: Text('\$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(rep['name'].split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text("\${rep['points']} P", style: const TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [medalColor.withOpacity(0.5), medalColor.withOpacity(0.1)],
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('\$rank.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: medalColor.withOpacity(0.8))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(BuildContext context, Map<String, dynamic> rep, int rank) {
    final double target = rep['revenueTarget'];
    final double actual = rep['revenueActual'];
    final double progress = (actual / target).clamp(0.0, 1.0);
    final bool isOverachieving = actual >= target;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('\$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400)),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: rep['avatarColor'].withOpacity(0.1),
            child: Text(rep['name'].substring(0, 1), style: TextStyle(fontWeight: FontWeight.bold, color: rep['avatarColor'])),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rep['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                Text("\${rep['points']} ${AppLocalization.of(context).translate('target.points')}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(isOverachieving ? Colors.green : const Color(0xFF00A8E8)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('\${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isOverachieving ? Colors.green : subtitleColor))
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
