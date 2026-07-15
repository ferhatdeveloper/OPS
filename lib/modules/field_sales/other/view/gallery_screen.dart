import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Dummy data representing visit photos mapped to customers
  final List<Map<String, dynamic>> _photos = [
    {
      'id': '1',
      'customerName': 'Ayyıldız Market',
      'type': 'Raf Dizilimi (Shelf)',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'imageUrl': 'https://via.placeholder.com/400x300.png?text=Raf+Fotografi'
    },
    {
      'id': '2',
      'customerName': 'Ayyıldız Market',
      'type': 'Rakip Analizi',
      'date': DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      'imageUrl': 'https://via.placeholder.com/400x300.png?text=Rakip+Urun'
    },
    {
      'id': '3',
      'customerName': 'Demirtaş Bakkaliyesi',
      'type': 'Mağaza İçi',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'imageUrl': 'https://via.placeholder.com/400x300.png?text=Magaza+Giris'
    },
    {
      'id': '4',
      'customerName': 'Özlem Hipermarket',
      'type': 'Kampanya (Promosyon)',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'imageUrl': 'https://via.placeholder.com/400x300.png?text=Kampanya+Standi'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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
        title: const Text('Resimler Galerisi', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Yeni Fotoğraf Çek',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamera başlatılıyor...')));
            },
          ),
        ],
      ),
      body: _photos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Henüz fotoğraf bulunmuyor.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Taller cards to fit text
              ),
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      _showImagePreview(context, photo);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                              ),
                              // Image.network(photo['imageUrl'], fit: BoxFit.cover), // Uncomment when using real images
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    DateFormat('dd MMM').format(photo['date'] as DateTime),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo['customerName'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photo['type'],
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showImagePreview(BuildContext context, Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.image, size: 80, color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(photo['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text("\${photo['type']} - \${DateFormat('dd.MM.yyyy HH:mm').format(photo['date'])}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Sil', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fotoğraf silindi', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text('Paylaş', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A8E8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paylaşım başlatılıyor...')));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -12,
              right: -12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
