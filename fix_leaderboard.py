import re

with open('lib/modules/manager/reports/view/leaderboard_screen.dart', 'r') as f:
    text = f.read()

# 1. Update _buildPodium signature
text = text.replace(
    'Widget _buildPodium() {',
    'Widget _buildPodium(BuildContext context) {\n    final isDarkMode = Theme.of(context).brightness == Brightness.dark;'
)

# 2. Update _buildPodium Container decoration
text = text.replace(
    '      decoration: BoxDecoration(\n        color: Colors.white,\n        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),\n        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],\n      ),',
    '      decoration: BoxDecoration(\n        color: Theme.of(context).cardColor,\n        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),\n        boxShadow: [BoxShadow(color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],\n      ),'
)

# 3. Update _buildPodiumBar calls in _buildPodium
text = text.replace('_buildPodiumBar(_leaderboard[1]', '_buildPodiumBar(context, _leaderboard[1]')
text = text.replace('_buildPodiumBar(_leaderboard[0]', '_buildPodiumBar(context, _leaderboard[0]')
text = text.replace('_buildPodiumBar(_leaderboard[2]', '_buildPodiumBar(context, _leaderboard[2]')

# 4. Update _buildPodiumBar signature and content
text = text.replace(
    'Widget _buildPodiumBar(Map<String, dynamic> rep, int rank, double height, Color medalColor) {',
    'Widget _buildPodiumBar(BuildContext context, Map<String, dynamic> rep, int rank, double height, Color medalColor) {\n    final isDarkMode = Theme.of(context).brightness == Brightness.dark;'
)
text = text.replace('border: Border.all(color: Colors.white, width: 2)', 'border: Border.all(color: isDarkMode ? Colors.transparent : Colors.white, width: 2)')
text = text.replace(
    "Text('${rep['name'].split(' ')[0]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))",
    "Text('${rep['name'].split(' ')[0]}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87))"
)
# Replaced literal '\$rank' text colors
text = text.replace("Text('\\$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))", "Text('\\$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))")

# 5. Update _buildListRow signature
text = text.replace(
    'Widget _buildListRow(Map<String, dynamic> rep, int rank) {',
    'Widget _buildListRow(BuildContext context, Map<String, dynamic> rep, int rank) {'
)

# 6. Replace _buildListRow internals
list_row_old = """    final double progress = (actual / target).clamp(0.0, 1.0);
    final bool isOverachieving = actual >= target;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),"""

list_row_new = """    final double progress = (actual / target).clamp(0.0, 1.0);
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
      ),"""
text = text.replace(list_row_old, list_row_new)

text = text.replace("Text('\\$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade400))", "Text('\\$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400))")
text = text.replace("Text(rep['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)))", "Text(rep['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))")
text = text.replace("Text(\"${rep['points']} Puan\", style: TextStyle(color: Colors.grey.shade500, fontSize: 12))", "Text(\"${rep['points']} Puan\", style: TextStyle(color: subtitleColor, fontSize: 12))")
text = text.replace("backgroundColor: Colors.grey.shade200", "backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey.shade200")
text = text.replace("color: isOverachieving ? Colors.green : Colors.grey.shade600", "color: isOverachieving ? Colors.green : subtitleColor")

with open('lib/modules/manager/reports/view/leaderboard_screen.dart', 'w') as f:
    f.write(text)

print("Leaderboard fixed.")
