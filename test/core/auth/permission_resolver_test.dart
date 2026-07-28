// Dosya Adı: permission_resolver_test.dart
// Açıklama: PermissionResolver birleştirme / allowsView birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/auth/menu_permission_flags.dart';
import 'package:exfin_ops/core/auth/permission_resolver.dart';

void main() {
  group('PermissionResolver.mergeSources', () {
    test('OR birleştirir — farklı uuid’ler korunur', () {
      final a = {
        'fs_order': MenuPermissionFlags.viewOnly,
      };
      final b = {
        'fs_stock': const MenuPermissionFlags(
          canView: true,
          canAdd: true,
          canEdit: false,
          canDelete: false,
        ),
      };
      final merged = PermissionResolver.mergeSources([a, b]);
      expect(merged.keys, containsAll(['fs_order', 'fs_stock']));
      expect(merged['fs_order']!.canView, isTrue);
      expect(merged['fs_stock']!.canAdd, isTrue);
    });

    test('aynı uuid — bayraklar OR', () {
      final direct = {
        'fs_customers': const MenuPermissionFlags(
          canView: true,
          canAdd: false,
          canEdit: false,
          canDelete: false,
        ),
      };
      final group = {
        'fs_customers': const MenuPermissionFlags(
          canView: false,
          canAdd: true,
          canEdit: true,
          canDelete: false,
        ),
      };
      final merged = PermissionResolver.mergeSources([direct, group]);
      expect(
        merged['fs_customers'],
        const MenuPermissionFlags(
          canView: true,
          canAdd: true,
          canEdit: true,
          canDelete: false,
        ),
      );
    });
  });

  group('PermissionResolver.allowsView', () {
    test('legacy — yetki yoksa true', () {
      expect(
        PermissionResolver.allowsView(
          effective: {},
          menuUuid: 'fs_order',
          hasAnyPermissionData: false,
        ),
        isTrue,
      );
    });

    test('yetki varken eksik uuid → false', () {
      expect(
        PermissionResolver.allowsView(
          effective: {
            'fs_stock': MenuPermissionFlags.viewOnly,
          },
          menuUuid: 'fs_order',
          hasAnyPermissionData: true,
        ),
        isFalse,
      );
    });

    test('can_view true → true', () {
      expect(
        PermissionResolver.allowsView(
          effective: {
            'fs_order': MenuPermissionFlags.full,
          },
          menuUuid: 'fs_order',
          hasAnyPermissionData: true,
        ),
        isTrue,
      );
    });
  });

  group('PermissionResolver.fromRows', () {
    test('SQLite 0/1 satırlarını parse eder', () {
      final map = PermissionResolver.fromRows([
        {
          'menu_uuid': 'fs_visit',
          'can_view': 1,
          'can_add': 0,
          'can_edit': 1,
          'can_delete': 0,
        },
      ]);
      expect(map['fs_visit']!.canView, isTrue);
      expect(map['fs_visit']!.canAdd, isFalse);
      expect(map['fs_visit']!.canEdit, isTrue);
    });
  });
}
