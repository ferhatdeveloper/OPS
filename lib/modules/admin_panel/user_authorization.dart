// Dosya Adı: user_authorization.dart
// Açıklama: Admin paneli için kullanıcı işlemleri ekranı (firma bazında kullanıcı ekle, rol ata, listele, sil)
// Oluşturulma Tarihi: 2024-03-22
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2024-06-10

import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import 'menu_permission_screen.dart';
import 'package:uuid/uuid.dart';
import '../../service/auth_service.dart';

/// {@template UserAuthorization}
/// Kullanıcıları firma bazında yetkilendirme ekranı: kullanıcı ekle, firma seç, rol ata, listele, sil
///
/// Kullanım örneği:
/// ```dart
/// UserAuthorization()
/// ```
/// {@endtemplate}
class UserAuthorization extends StatefulWidget {
  const UserAuthorization({Key? key}) : super(key: key);

  @override
  State<UserAuthorization> createState() => _UserAuthorizationState();
}

class _UserAuthorizationState extends State<UserAuthorization> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedRole;
  final List<String> _roles = ['admin', 'supervisor', 'user'];
  String? _activePermissionUserId;
  String? _activePermissionCompanyId;
  Map<String, Map<String, bool>> _userCompanyVisibility = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = await SupabaseService.getInstance();
      final users = await supabase.query('users', orderBy: 'id');
      final companies = await supabase.query('company', orderBy: 'name');
      final visList = await supabase.query('user_company_visibility');
      final visMap = <String, Map<String, bool>>{};
      for (final row in visList) {
        final uid = row['user_id'].toString();
        final cno = row['company_no']?.toString() ?? '';
        final vis = row['is_visible'] == true;
        visMap.putIfAbsent(uid, () => {})[cno] = vis;
      }
      setState(() {
        _users = users;
        _companies = companies;
        _userCompanyVisibility = visMap;
        _isLoading = false;
      });
      if (companies.isEmpty) {
        debugPrint('Uyarı: company tablosu boş!');
      }
    } catch (e) {
      debugPrint('Kullanıcı veya firma verisi çekilemedi: $e');
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri çekilemedi: $e')),
        );
      });
    }
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;
    final supabase = await SupabaseService.getInstance();
    try {
      // Users tablosuna ekle (şemaya uygun)
      final now = DateTime.now().toUtc().toIso8601String();
      final hashedPassword =
          AuthService.hashPassword(_passwordController.text.trim());
      final userId = const Uuid().v4();
      final newUser = {
        'id': userId,
        'username': _usernameController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'full_name': _usernameController.text, // veya ayrı bir alan eklenebilir
        'role': _selectedRole ?? 'user',
        'is_active': true,
        'is_deleted': false,
        'created_at': now,
        'updated_at': now,
        'password_hash': hashedPassword,
        // Diğer alanlar opsiyonel
      };
      await supabase.insert('users', newUser);
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedRole = null;
      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı başarıyla eklendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: \\${e.toString()}')),
      );
    }
  }

  Future<void> _deleteUser(int index) async {
    final supabase = await SupabaseService.getInstance();
    final userId = _users[index]['id'];
    await supabase.delete('users', userId.toString());
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Kullanıcı İşlemleri'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_activePermissionUserId == null) ...[
                  if (_companies.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Uyarı: Firma tablosu boş! Lütfen önce firma ekleyin.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Kullanıcı Adı',
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Boş bırakılamaz'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'E-posta',
                                ),
                                validator: (v) => null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Şifre',
                                ),
                                obscureText: true,
                                validator: (v) => v == null || v.length < 6
                                    ? 'En az 6 karakter'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<String>(
                                value: _selectedRole,
                                items: _roles
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedRole = v),
                                decoration:
                                    const InputDecoration(labelText: 'Rol'),
                                validator: (v) =>
                                    v == null ? 'Rol seçiniz' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _addUser,
                              child: const Text('Ekle'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: _activePermissionUserId == null
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 600,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['username'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Kullanıcı No: ${user['id']}',
                                                style: const TextStyle(
                                                    color: Colors.blueGrey,
                                                    fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.lock_reset,
                                              color: Colors.orange),
                                          tooltip: 'Şifre Değiştir',
                                          onPressed: () async {
                                            final newPassword =
                                                await showDialog<String>(
                                              context: context,
                                              builder: (context) {
                                                String pwd = '';
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Yeni Şifre Belirle'),
                                                  content: TextField(
                                                    autofocus: true,
                                                    obscureText: true,
                                                    decoration:
                                                        const InputDecoration(
                                                            labelText:
                                                                'Yeni Şifre'),
                                                    onChanged: (v) => pwd = v,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('İptal'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, pwd),
                                                      child:
                                                          const Text('Kaydet'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            if (newPassword != null &&
                                                newPassword.length >= 6) {
                                              final supabase =
                                                  await SupabaseService
                                                      .getInstance();
                                              try {
                                                await supabase
                                                    .updateUserPassword(
                                                        user['email'],
                                                        newPassword);
                                                await supabase.update(
                                                  'users',
                                                  {
                                                    'updated_at': DateTime.now()
                                                        .toUtc()
                                                        .toIso8601String()
                                                  },
                                                  user['id'],
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Şifre başarıyla değiştirildi')),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Şifre değiştirilemedi: $e')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: Icon(
                                            user['is_active'] == true
                                                ? Icons.block
                                                : Icons.lock_open,
                                            color: user['is_active'] == true
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                          tooltip: user['is_active'] == true
                                              ? 'Blokla'
                                              : 'Blok Aç',
                                          onPressed: () async {
                                            final supabase =
                                                await SupabaseService
                                                    .getInstance();
                                            try {
                                              await supabase.update(
                                                'users',
                                                {
                                                  'is_active':
                                                      !(user['is_active'] ==
                                                          true),
                                                  'updated_at': DateTime.now()
                                                      .toUtc()
                                                      .toIso8601String()
                                                },
                                                user['id'],
                                              );
                                              await _fetchData();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(user[
                                                                'is_active'] ==
                                                            true
                                                        ? 'Kullanıcı bloklandı'
                                                        : 'Kullanıcı aktif edildi')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'İşlem başarısız: $e')),
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          tooltip: 'Sil',
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Kullanıcıyı Sil'),
                                                content: const Text(
                                                    'Bu kullanıcıyı silmek istediğinize emin misiniz?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('İptal'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text('Sil'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await _deleteUser(index);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Kullanıcı silindi')),
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.copy,
                                              color: Colors.indigo),
                                          tooltip: 'Yetki Kopyala',
                                          onPressed: () async {
                                            String? selectedUserId;
                                            final selectedCompanyNos = <int>[];
                                            final result = await showDialog<
                                                Map<String, dynamic>>(
                                              context: context,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder: (context, setState) {
                                                    return AlertDialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          18)),
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      content: SizedBox(
                                                        width: 600,
                                                        height: 350,
                                                        child: Row(
                                                          children: [
                                                            // Kullanıcılar (flat, sade)
                                                            Expanded(
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              14),
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade200),
                                                                ),
                                                                child: ListView(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8),
                                                                  children: _users
                                                                      .where((u) => u['id'] != user['id'])
                                                                      .map((u) => InkWell(
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                            onTap: () =>
                                                                                setState(() => selectedUserId = u['id'].toString()),
                                                                            child:
                                                                                Container(
                                                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                                                              decoration: BoxDecoration(
                                                                                color: selectedUserId == u['id'].toString() ? Theme.of(context).colorScheme.primary.withOpacity(0.07) : Colors.transparent,
                                                                                borderRadius: BorderRadius.circular(10),
                                                                              ),
                                                                              child: ListTile(
                                                                                dense: true,
                                                                                leading: CircleAvatar(
                                                                                  backgroundColor: Colors.grey.shade100,
                                                                                  child: Text(
                                                                                    u['username']?[0]?.toUpperCase() ?? '?',
                                                                                    style: TextStyle(
                                                                                      color: Theme.of(context).colorScheme.primary,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                title: Text(u['username'] ?? ''),
                                                                                subtitle: Text(u['email'] ?? ''),
                                                                                trailing: selectedUserId == u['id'].toString() ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                                                                              ),
                                                                            ),
                                                                          ))
                                                                      .toList(),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 18),
                                                            // Firmalar (flat, kart benzeri, modern)
                                                            Expanded(
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              14),
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade200),
                                                                ),
                                                                child: ListView(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8),
                                                                  children:
                                                                      _companies
                                                                          .map(
                                                                              (firma) {
                                                                    final companyNo =
                                                                        int.tryParse(
                                                                            firma['company_no'].toString());
                                                                    if (companyNo ==
                                                                        null)
                                                                      return const SizedBox
                                                                          .shrink();
                                                                    final isSelected =
                                                                        selectedCompanyNos
                                                                            .contains(companyNo);
                                                                    return InkWell(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                      onTap:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          if (isSelected) {
                                                                            selectedCompanyNos.remove(companyNo);
                                                                          } else {
                                                                            selectedCompanyNos.add(companyNo);
                                                                          }
                                                                        });
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        margin: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                4),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: isSelected
                                                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.07)
                                                                              : Colors.transparent,
                                                                          borderRadius:
                                                                              BorderRadius.circular(10),
                                                                        ),
                                                                        child:
                                                                            ListTile(
                                                                          dense:
                                                                              true,
                                                                          leading:
                                                                              CircleAvatar(
                                                                            backgroundColor:
                                                                                Colors.grey.shade100,
                                                                            child:
                                                                                Text(
                                                                              (firma['name']?.toString().isNotEmpty ?? false) ? firma['name'].toString()[0].toUpperCase() : '?',
                                                                              style: TextStyle(
                                                                                color: Theme.of(context).colorScheme.primary,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          title:
                                                                              Text(firma['name'] ?? ''),
                                                                          subtitle:
                                                                              Text('No: ${firma['company_no'] ?? ''}'),
                                                                          trailing: isSelected
                                                                              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                                                                              : null,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        Align(
                                                          alignment: Alignment
                                                              .bottomRight,
                                                          child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8)),
                                                              backgroundColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary,
                                                              foregroundColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onPrimary,
                                                              elevation: 0,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          28,
                                                                      vertical:
                                                                          12),
                                                              textStyle: const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            onPressed: () {
                                                              if (selectedUserId !=
                                                                      null &&
                                                                  selectedCompanyNos
                                                                      .isNotEmpty) {
                                                                Navigator.pop(
                                                                    context, {
                                                                  'targetUserId':
                                                                      selectedUserId,
                                                                  'companyNos':
                                                                      selectedCompanyNos,
                                                                });
                                                              }
                                                            },
                                                            child: const Text(
                                                                'Tamam'),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                            if (result != null) {
                                              final supabase =
                                                  await SupabaseService
                                                      .getInstance();
                                              debugPrint(
                                                  '[YetkiKopyala] Kaynak kullanıcı: \\${user['id']} -> Hedef kullanıcı: \\${result['targetUserId']}');
                                              debugPrint(
                                                  '[YetkiKopyala] Seçili firmalar (company_no): \\${result['companyNos']}');
                                              // company_no ile sorgu
                                              final response = await supabase
                                                  .client
                                                  .from('menu_permissions')
                                                  .select()
                                                  .eq('user_id', user['id'])
                                                  .inFilter('company_no',
                                                      result['companyNos']);
                                              final permList = List<
                                                  Map<String,
                                                      dynamic>>.from(response);
                                              debugPrint(
                                                  '[YetkiKopyala] Kaynak kullanıcının seçili firmalardaki yetki sayısı: \\${permList.length}');
                                              if (permList.isEmpty) {
                                                debugPrint(
                                                    '[YetkiKopyala] Seçili firmalarda yetki yok, kopyalama yapılmadı.');
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Seçili firmalarda yetki yok!')),
                                                );
                                                return;
                                              }
                                              final newPerms =
                                                  permList.map((p) {
                                                final np =
                                                    Map<String, dynamic>.from(
                                                        p);
                                                np['user_id'] =
                                                    result['targetUserId'];
                                                np.remove('id');
                                                np.remove('uuid');
                                                np['created_at'] =
                                                    DateTime.now()
                                                        .toUtc()
                                                        .toIso8601String();
                                                np['updated_at'] =
                                                    DateTime.now()
                                                        .toUtc()
                                                        .toIso8601String();
                                                return np;
                                              }).toList();
                                              debugPrint(
                                                  '[YetkiKopyala] Kopyalanacak yeni yetki kayıtları örnek: \\${newPerms.take(2).toList()}');
                                              try {
                                                await supabase.upsert(
                                                    'menu_permissions',
                                                    newPerms);
                                                debugPrint(
                                                    '[YetkiKopyala] Kopyalama işlemi başarılı. Toplam: \\${newPerms.length} kayıt.');
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Yetkiler başarıyla kopyalandı')),
                                                );
                                              } catch (e) {
                                                debugPrint(
                                                    '[YetkiKopyala][HATA] Upsert sırasında hata oluştu: \\${e.toString()}');
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Yetki kopyalama hatası: \\${e.toString()}')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    children: [
                                      ..._companies.map((firma) =>
                                          _UserCompanyFirmTile(
                                            userId: user['id'],
                                            username: user['username'] ?? '',
                                            firma: firma,
                                            companyNo: firma['company_no']
                                                    ?.toString() ??
                                                '',
                                            initialVisible:
                                                _userCompanyVisibility[
                                                            user['id']]?[
                                                        firma['company_no']
                                                                ?.toString() ??
                                                            ''] ??
                                                    false,
                                            onShowPermission: (companyNo) {
                                              setState(() {
                                                _activePermissionUserId =
                                                    user['id'];
                                                _activePermissionCompanyId =
                                                    companyNo;
                                              });
                                            },
                                          )),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : MenuPermissionScreen(
                          selectedUserId: _activePermissionUserId!,
                          selectedCompanyNo: _activePermissionCompanyId!,
                          onBack: () => setState(() {
                            _activePermissionUserId = null;
                            _activePermissionCompanyId = null;
                          }),
                        ),
                ),
              ],
            ),
    );
  }
}

class _UserMenuPermissionSummary extends StatefulWidget {
  final String userId;
  const _UserMenuPermissionSummary({required this.userId});

  @override
  State<_UserMenuPermissionSummary> createState() =>
      _UserMenuPermissionSummaryState();
}

class _UserMenuPermissionSummaryState
    extends State<_UserMenuPermissionSummary> {
  List<String> _mainMenus = [];
  int _totalMenus = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserMenuPermissions();
  }

  Future<void> _fetchUserMenuPermissions() async {
    setState(() => _loading = true);
    final supabase = await SupabaseService.getInstance();
    final perms = await supabase.query('menu_permissions',
        filter: 'user_id', filterArgs: [widget.userId]);
    final menuIds = perms.map((e) => e['menu_id']).toSet().toList();
    _totalMenus = menuIds.length;
    if (_totalMenus == 0) {
      setState(() {
        _mainMenus = [];
        _loading = false;
      });
      return;
    }
    final menus = await supabase.query('menu');
    final anaMenuler = menus
        .where((m) => menuIds.contains(m['id']) && m['parent_id'] == null)
        .map((m) => m['title'] as String)
        .toList();
    setState(() {
      _mainMenus = anaMenuler;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_totalMenus == 0) {
      return const Text('Yetki yok',
          style: TextStyle(color: Colors.grey, fontSize: 12));
    }
    return Row(
      children: [
        Icon(Icons.security, color: Colors.blue, size: 20),
        const SizedBox(width: 4),
        Tooltip(
          message: _mainMenus.isNotEmpty
              ? 'Ana Menüler: ' +
                  _mainMenus.take(3).join(', ') +
                  (_mainMenus.length > 3
                      ? ' +${_mainMenus.length - 3} daha'
                      : '')
              : 'Toplam $_totalMenus menüde yetki',
          child: Text(
            _mainMenus.isNotEmpty
                ? _mainMenus.take(2).join(', ') +
                    (_mainMenus.length > 2 ? '...' : '')
                : '$_totalMenus menü',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}

class _UserCompanyVisibilityManager {
  static Future<void> setVisibility(
      String userId, String companyNo, bool visible,
      {String? username, String? companyName, String? companyDetail}) async {
    final supabase = await SupabaseService.getInstance();
    try {
      if (visible) {
        await supabase.upsert('user_company_visibility', [
          {
            'user_id': userId,
            'username': username,
            'company_no': companyNo,
            'is_visible': true,
            if (companyName != null) 'company_name': companyName,
            if (companyDetail != null) 'company_detail': companyDetail,
          }
        ]);
      } else {
        await supabase.client
            .from('user_company_visibility')
            .delete()
            .eq('user_id', userId)
            .eq('company_no', companyNo);
      }
    } catch (e) {
      debugPrint('Görünürlük silme/upsert hatası: $e');
      rethrow;
    }
  }
}

class _UserCompanyFirmTile extends StatefulWidget {
  final String userId;
  final String username;
  final Map<String, dynamic> firma;
  final String companyNo;
  final bool initialVisible;
  final void Function(String companyNo)? onShowPermission;
  const _UserCompanyFirmTile({
    required this.userId,
    required this.username,
    required this.firma,
    required this.companyNo,
    required this.initialVisible,
    this.onShowPermission,
  });
  @override
  State<_UserCompanyFirmTile> createState() => _UserCompanyFirmTileState();
}

class _UserCompanyFirmTileState extends State<_UserCompanyFirmTile> {
  late bool _visible;
  bool _loading = false;
  String get companyNo => widget.companyNo;
  String get companyName => widget.firma['name']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _visible = widget.initialVisible;
  }

  Future<void> _toggleVisibility(bool value) async {
    if (companyNo.isEmpty) {
      debugPrint('Hatalı companyNo: boş, upsert yapılmadı.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _UserCompanyVisibilityManager.setVisibility(
        widget.userId,
        companyNo,
        value,
        username: widget.username,
        companyName: widget.firma['name']?.toString(),
        companyDetail: widget.firma['description']?.toString(),
      );
      setState(() {
        _visible = value;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Firma No: $companyNo',
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _loading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: _visible,
                        onChanged: _toggleVisibility,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text('İşlem Yetkileri',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29507A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () => widget.onShowPermission?.call(companyNo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
