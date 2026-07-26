// Dosya Adı: logo_collection_check_cl_map_test.dart
// Açıklama: Çek tahsilat → Logo CL/CSCARD alan adları map birim testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';

void main() {
  group('LogoPayloadMapper collection check CL', () {
    test('çek alanları Logo CSCARD / Objects alias yazar', () {
      final due = DateTime(2026, 9, 15);
      final payload = LogoPayloadMapper.collectionFromLocal(
        customerCode: 'C120',
        amount: 1500.5,
        paymentType: 'check',
        bankName: 'Ziraat',
        branchName: 'Kadıköy',
        checkNumber: 'CHK-7788',
        dueDate: due,
        endorsement: 'Ciro A.Ş.',
        originalDebtor: 'Asıl Borçlu Ltd',
        workplace: 'İstanbul',
        accountNumber: 'TR120001',
        documentNo: 'EVR-01',
      );

      expect(payload['payment_type'], 'check');
      expect(payload['ARP_CODE'], 'C120');
      expect(payload['AMOUNT'], 1500.5);
      // KDV yok
      expect(payload.containsKey('vat_rate'), isFalse);
      expect(payload.containsKey('vat_amount'), isFalse);

      // Çek türü DOC=1 (senet=2)
      expect(payload['DOC'], 1);

      // Banka — snake + CSCARD BANKNAME + Objects BANK_TITLE
      expect(payload['bank_name'], 'Ziraat');
      expect(payload['BANKNAME'], 'Ziraat');
      expect(payload['BANK_TITLE'], 'Ziraat');

      // Şube — snake + BNBRANCHNO
      expect(payload['branch_name'], 'Kadıköy');
      expect(payload['BNBRANCHNO'], 'Kadıköy');

      // Çek no — snake + SERINO / SERIAL_NR / NEWSERINO
      expect(payload['check_number'], 'CHK-7788');
      expect(payload['SERINO'], 'CHK-7788');
      expect(payload['SERIAL_NR'], 'CHK-7788');
      expect(payload['NEWSERINO'], 'CHK-7788');

      // Vade — snake + DUEDATE / DUE_DATE (tarih)
      expect(payload['due_date'], isNotNull);
      expect(payload['DUEDATE'], '2026-09-15');
      expect(payload['DUE_DATE'], '2026-09-15');

      // Asıl borçlu → OWING (CSCARD Borçlu)
      expect(payload['original_debtor'], 'Asıl Borçlu Ltd');
      expect(payload['OWING'], 'Asıl Borçlu Ltd');

      // Ciro (snake; Logo’da ayrı hareket — alias taşınır)
      expect(payload['endorsement'], 'Ciro A.Ş.');

      // Hesap no → BNACCOUNTNO
      expect(payload['account_number'], 'TR120001');
      expect(payload['BNACCOUNTNO'], 'TR120001');

      // İşyeri / ödeme yeri → CITY (CSCARD)
      expect(payload['workplace'], 'İstanbul');
      expect(payload['CITY'], 'İstanbul');
    });

    test('senet payment_type → DOC=2; nakit CL alan yazmaz', () {
      final note = LogoPayloadMapper.collectionFromLocal(
        customerCode: 'C1',
        amount: 10,
        paymentType: 'note',
        checkNumber: 'SN-1',
        dueDate: DateTime(2026, 10, 1),
      );
      expect(note['DOC'], 2);
      expect(note['SERINO'], 'SN-1');
      expect(note['DUE_DATE'], '2026-10-01');

      final cash = LogoPayloadMapper.collectionFromLocal(
        customerCode: 'C1',
        amount: 10,
        paymentType: 'cash',
      );
      expect(cash.containsKey('DOC'), isFalse);
      expect(cash.containsKey('SERINO'), isFalse);
      expect(cash.containsKey('BANKNAME'), isFalse);
      expect(cash.containsKey('DUE_DATE'), isFalse);
    });

    test('boş çek alanları Logo CL anahtarı üretmez', () {
      final payload = LogoPayloadMapper.collectionFromLocal(
        customerCode: 'C1',
        amount: 1,
        paymentType: 'check',
        bankName: '  ',
        checkNumber: '',
        branchName: null,
      );
      expect(payload['DOC'], 1);
      expect(payload.containsKey('bank_name'), isFalse);
      expect(payload.containsKey('BANKNAME'), isFalse);
      expect(payload.containsKey('check_number'), isFalse);
      expect(payload.containsKey('SERINO'), isFalse);
    });
  });
}
