// Dosya Adı: order_customer_empty_list_test.dart
// Açıklama: Cari seçim boş liste domain engeli — TDD RED (UI yok)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/customers/model/customer_model.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_provider.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_provider.dart';

void main() {
  group('Cari seçim boş liste (domain, UI yok)', () {
    test(
      'boş customers listesinde emptySelectionL10nKey no_customer_cards döner',
      () {
        // TDD RED: CustomerState henüz emptySelectionL10nKey taşımıyor.
        // Beklenen sözleşme (implementasyon sonrası yeşile döner):
        //   CustomerState(customers: []).emptySelectionL10nKey
        //     == 'field_sales.no_customer_cards'
        final state = CustomerState(customers: const [], isLoading: false);

        final dynamic dynamicState = state;
        String? key;
        try {
          key = dynamicState.emptySelectionL10nKey as String?;
        } on NoSuchMethodError {
          key = null;
        }

        expect(
          key,
          equals('field_sales.no_customer_cards'),
          reason:
              'Boş cari listesi domain seviyesinde L10n key taşımalı '
              '(CustomerState.emptySelectionL10nKey). UI kullanılmaz.',
        );
      },
    );

    test(
      'yalnızca boş id satırları seçilebilir cari üretmez ve sipariş engellenir',
      () {
        // Geçersiz/boş id'li satırlar seçim listesine girmemeli.
        final rows = <CustomerModel>[
          CustomerModel.fromMap({'id': '', 'name': 'Hayalet'}),
          CustomerModel.fromMap({'id': '   ', 'name': 'Boş Id'}),
        ];
        final selectable = rows
            .where((c) => OrderNotifier.isValidCustomerId(c.id))
            .toList();

        expect(selectable, isEmpty);

        // TDD RED: boş seçilebilir listede sipariş girişine izin yok bayrağı
        final state = CustomerState(customers: selectable);
        final dynamic dynamicState = state;
        bool? canSelect;
        try {
          canSelect = dynamicState.hasSelectableCustomers as bool?;
        } on NoSuchMethodError {
          canSelect = null;
        }

        expect(
          canSelect,
          isFalse,
          reason:
              'CustomerState.hasSelectableCustomers boş listede false olmalı',
        );
      },
    );

    test(
      'boş listeden seçim denemesi geçerli customerId üretmez',
      () {
        final customers = <CustomerModel>[];
        final selectedId =
            customers.isEmpty ? null : customers.first.id;

        expect(OrderNotifier.isValidCustomerId(selectedId), isFalse);
      },
    );
  });
}
