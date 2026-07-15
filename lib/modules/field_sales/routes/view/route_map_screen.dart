import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../model/route_model.dart';
import '../engine/route_optimizer.dart';

class RouteMapScreen extends StatefulWidget {
  final List<RouteCustomerModel> customers;
  const RouteMapScreen({Key? key, required this.customers}) : super(key: key);

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  late List<RouteCustomerModel> _optimizedCustomers;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _optimizedCustomers = RouteOptimizer.optimize(widget.customers);
  }

  @override
  Widget build(BuildContext context) {
    // Initial center point (first customer or defaults)
    final LatLng center = _optimizedCustomers.isNotEmpty
        ? LatLng(_optimizedCustomers.first.latitude ?? 0.0, _optimizedCustomers.first.longitude ?? 0.0)
        : const LatLng(36.2, 44.0); // Default Erbil/Iraq region coords

    final List<Marker> markers = _optimizedCustomers.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value;
      return Marker(
        point: LatLng(c.latitude ?? 0.0, c.longitude ?? 0.0),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: index == 0 ? Colors.green : Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      );
    }).toList();

    final polyline = Polyline(
      points: _optimizedCustomers
          .where((c) => c.latitude != null && c.longitude != null)
          .map((c) => LatLng(c.latitude!, c.longitude!))
          .toList(),
      color: Colors.blue.withOpacity(0.7),
      strokeWidth: 4,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Optimizasyonu & Harita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => _mapController.move(center, 13),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.exfin.ops',
          ),
          PolylineLayer<Object>(polylines: [polyline]),
          MarkerLayer(markers: markers),
        ],
      ),
      bottomSheet: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Toplam ${_optimizedCustomers.length} durak optimize edildi. Yeşil nokta başlangıç noktasını gösterir.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
