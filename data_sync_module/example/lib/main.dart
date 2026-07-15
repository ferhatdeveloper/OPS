// Dosya Adı: main.dart
// Açıklama: Data Sync Module örnek kullanım uygulaması
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-03-21

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:data_sync_module/data_sync_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlat
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // SQLite veritabanını oluştur
  final database = await openDatabase(
    path.join(await getDatabasesPath(), 'example_database.db'),
    version: 1,
  );

  // SyncManager'ı başlat
  final syncManager = SyncManager();
  await syncManager.initialize(
    database: database,
    supabase: Supabase.instance.client,
    config: SyncConfig.developmentConfig,
  );

  runApp(MyApp(syncManager: syncManager, database: database));
}

class MyApp extends StatelessWidget {
  final SyncManager syncManager;
  final Database database;

  const MyApp({
    Key? key,
    required this.syncManager,
    required this.database,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Sync Module Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomePage(syncManager: syncManager, database: database),
    );
  }
}

class HomePage extends StatefulWidget {
  final SyncManager syncManager;
  final Database database;

  const HomePage({
    Key? key,
    required this.syncManager,
    required this.database,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSyncing = false;
  String _syncStatus = 'Hazır';
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _setupSyncListener();
    _loadUsers();
  }

  void _setupSyncListener() {
    widget.syncManager.syncStatus.listen((isSyncing) {
      setState(() {
        _isSyncing = isSyncing;
        _syncStatus = isSyncing ? 'Senkronize ediliyor...' : 'Hazır';
      });
    });
  }

  Future<void> _loadUsers() async {
    final results = await widget.database.query('users');
    setState(() {
      _users = results.map((row) => User.fromDatabaseMap(row)).toList();
    });
  }

  Future<void> _createTable() async {
    try {
      await widget.syncManager.createAndSyncTable('users', [
        'name TEXT NOT NULL',
        'email TEXT NOT NULL UNIQUE',
        'phone TEXT',
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tablo oluşturuldu ve senkronize edildi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _addUser() async {
    final user = User(
      name: 'Test Kullanıcı ${_users.length + 1}',
      email: 'test${_users.length + 1}@example.com',
      phone: '+90 555 123 ${_users.length + 1}',
    );

    try {
      await widget.database.insert('users', user.toDatabaseMap());

      // Senkronizasyon için onayla
      final approvedUser = user.markAsApproved();
      await widget.database.update(
        'users',
        approvedUser.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );

      await _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı eklendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _syncNow() async {
    try {
      final result = await widget.syncManager.syncNow();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Senkronizasyon tamamlandı: ${result.inserted} eklendi, '
            '${result.updated} güncellendi, ${result.conflicts} çakışma',
          ),
        ),
      );

      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Senkronizasyon hatası: $e')),
      );
    }
  }

  Future<void> _showSyncStatus() async {
    try {
      final status = await widget.syncManager.getSyncStatus();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Senkronizasyon Durumu'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: status.entries.map((entry) {
                final tableName = entry.key;
                final tableStatus = entry.value as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tablo: $tableName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                          'Son Senkronizasyon: ${tableStatus['lastSync'] ?? 'Hiç'}'),
                      Text('Bekleyen Kayıt: ${tableStatus['pendingCount']}'),
                      Text(
                          'Çevrimiçi: ${tableStatus['isOnline'] ? 'Evet' : 'Hayır'}'),
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum alınırken hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sync Module Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durum kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSyncing ? Icons.sync : Icons.check_circle,
                          color: _isSyncing ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Durum: $_syncStatus',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Toplam Kullanıcı: ${_users.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createTable,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Tablo Oluştur'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Kullanıcı Ekle'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _syncNow,
                    icon: const Icon(Icons.sync),
                    label: const Text('Senkronize Et'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSyncStatus,
                    icon: const Icon(Icons.info),
                    label: const Text('Durum'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Kullanıcı listesi
            const Text(
              'Kullanıcılar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _users.isEmpty
                  ? const Center(
                      child: Text('Henüz kullanıcı yok'),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          child: ListTile(
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                if (user.phone != null) Text(user.phone!),
                                Text(
                                  'Durum: ${user.approvalStatus.displayName}',
                                  style: TextStyle(
                                    color: user.approvalStatus.isReadyForSync
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              user.isSynced
                                  ? Icons.cloud_done
                                  : Icons.cloud_upload,
                              color:
                                  user.isSynced ? Colors.green : Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Örnek User modeli
class User extends SyncModel {
  final String name;
  final String email;
  final String? phone;

  User({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.isSynced,
    super.isDeleted,
    super.approvalStatus,
    required this.name,
    required this.email,
    this.phone,
  });

  @override
  String get tableName => 'users';

  @override
  List<String> get schemaColumns => [
        'name TEXT NOT NULL',
        'email TEXT NOT NULL UNIQUE',
        'phone TEXT',
      ];

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  @override
  User copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
    ApprovalStatus? approvalStatus,
    String? name,
    String? email,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  factory User.fromDatabaseMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
      isDeleted: map['is_deleted'] == 1,
      approvalStatus: ApprovalStatus.fromValue(map['approval_status']),
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
    );
  }
}
