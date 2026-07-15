class KPIModel {
  final double salesTarget;
  final double currentSales;
  final int plannedVisits;
  final int completedVisits;
  final int totalOrders;
  final double totalCollections;

  KPIModel({
    required this.salesTarget,
    required this.currentSales,
    required this.plannedVisits,
    required this.completedVisits,
    required this.totalOrders,
    required this.totalCollections,
  });

  double get salesAchievement => salesTarget > 0 ? (currentSales / salesTarget) * 100 : 0;
  double get visitSuccessRate => plannedVisits > 0 ? (completedVisits / plannedVisits) * 100 : 0;
  double get averageOrderValue => totalOrders > 0 ? currentSales / totalOrders : 0;
}
