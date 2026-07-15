import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodel/map_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  Future<void> _launchNavigation(LatLng destination) async {
    final url = 'google.navigation:q=${destination.latitude},${destination.longitude}';
    final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      await launchUrl(Uri.parse(fallbackUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    return Scaffold(
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
        title: const Text('Müşteri Haritası', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => ref.read(mapProvider.notifier).loadCustomerMarkers(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.currentLocation ?? const LatLng(41.0082, 28.9784),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.exfinops.app',
              ),
              // Route Polylines
              if (mapState.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.routePoints,
                      color: const Color(0xFF00A8E8).withOpacity(0.5),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Current Location Marker
                  if (mapState.currentLocation != null)
                    Marker(
                      point: mapState.currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.navigation, color: Colors.blue.shade800, size: 24),
                        ),
                      ),
                    ),
                  
                  // Customer Markers
                  ...mapState.customerMarkers.map((customer) => Marker(
                    point: customer.position,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showCustomerDetails(context, customer),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on, 
                            color: customer.isVisited ? Colors.green : Colors.red, 
                            size: 36
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              customer.name, 
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),
          if (mapState.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'center_map',
            onPressed: () {
              if (mapState.currentLocation != null) {
                _mapController.move(mapState.currentLocation!, 15);
              }
            },
            backgroundColor: const Color(0xFF00A8E8),
            mini: true,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'refresh_markers',
            onPressed: () => ref.read(mapProvider.notifier).loadCustomerMarkers(),
            backgroundColor: const Color(0xFF375A7F),
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, CustomerMarker customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.check_circle, color: customer.isVisited ? Colors.green : Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text('Müşteri Kodu: ${customer.id}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _launchNavigation(customer.position);
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigasyon Başlat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF375A7F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to sales screen if needed
                      Navigator.pushNamed(context, '/field-sales/visit-details', arguments: customer.id);
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('İşlem Yap'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
