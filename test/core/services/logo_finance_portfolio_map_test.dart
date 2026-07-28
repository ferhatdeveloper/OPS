// Dosya Adı: logo_finance_portfolio_map_test.dart
// Açıklama: Banka / çek / senet portföy Logo payload stub map testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/core/services/logo_payload_mapper.dart';

void main() {
  test('bankCardFromLocal CODE ve sync_stub yazar', () {
    final payload = LogoPayloadMapper.bankCardFromLocal({
      'id': 'b1',
      'code': '102 01 01',
      'name': 'Merkez TL',
      'balance_tl': 1000,
    });
    expect(payload['entity_type'], LogoPayloadMapper.bankCardEntityType);
    expect(payload['CODE'], '102 01 01');
    expect(payload['sync_stub'], isTrue);
  });

  test('checkPortfolioFromLocal çek DOC=1', () {
    final payload = LogoPayloadMapper.checkPortfolioFromLocal(
      {
        'id': 'ch1',
        'amount': 500,
        'check_number': 'CK-1',
        'bank_name': 'Ziraat',
        'customer_id': 'C001',
      },
      customerCode: 'C001',
    );
    expect(payload['entity_type'], LogoPayloadMapper.checkPortfolioEntityType);
    expect(payload['DOC'], LogoPayloadMapper.collectionDocCheck);
    expect(payload['SERINO'], 'CK-1');
    expect(payload['sync_stub'], isTrue);
  });

  test('promissoryPortfolioFromLocal senet DOC=2', () {
    final payload = LogoPayloadMapper.promissoryPortfolioFromLocal(
      {
        'id': 'sn1',
        'amount': 200,
        'note_number': 'SN-9',
        'customer_id': 'C002',
      },
      customerCode: 'C002',
    );
    expect(
      payload['entity_type'],
      LogoPayloadMapper.promissoryPortfolioEntityType,
    );
    expect(payload['DOC'], LogoPayloadMapper.collectionDocNote);
    expect(payload['sync_stub'], isTrue);
  });
}
