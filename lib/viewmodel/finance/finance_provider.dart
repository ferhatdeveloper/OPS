import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinanceState {
  final bool isLoading;
  final String error;
  final List<dynamic> invoices;
  final List<dynamic> payments;
  final List<dynamic> cashTransactions;
  final Map<String, dynamic> cashBalances;

  const FinanceState({
    this.isLoading = false,
    this.error = '',
    this.invoices = const [],
    this.payments = const [],
    this.cashTransactions = const [],
    this.cashBalances = const {},
  });

  FinanceState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? invoices,
    List<dynamic>? payments,
    List<dynamic>? cashTransactions,
    Map<String, dynamic>? cashBalances,
  }) {
    return FinanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      invoices: invoices ?? this.invoices,
      payments: payments ?? this.payments,
      cashTransactions: cashTransactions ?? this.cashTransactions,
      cashBalances: cashBalances ?? this.cashBalances,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier() : super(const FinanceState()) {
    // Initialize with loading mock data
    fetchFinanceData();
  }

  Future<void> fetchFinanceData() async {
    state = state.copyWith(isLoading: true);

    try {
      // In a real app, make API requests here
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      final mockInvoices = [
        {
          'id': 1,
          'number': 'FTR-2025-0001',
          'amount': 12500,
          'customer': 'ABC Ltd.',
          'date': '15.05.2025',
        },
        {
          'id': 2,
          'number': 'FTR-2025-0002',
          'amount': 7800,
          'customer': 'XYZ A.Ş.',
          'date': '16.05.2025',
        },
        {
          'id': 3,
          'number': 'FTR-2025-0003',
          'amount': 25300,
          'customer': 'DEF Sanayi',
          'date': '17.05.2025',
        },
      ];
      final mockPayments = [
        {
          'id': 1,
          'reference': 'ODM-2025-0001',
          'amount': 5000,
          'vendor': 'GHI Tedarik',
          'date': '14.05.2025',
          'type': 'Nakit Ödeme',
          'description': 'Hammadde alımı için ödeme',
        },
        {
          'id': 2,
          'reference': 'ODM-2025-0002',
          'amount': 8700,
          'vendor': 'JKL Tic.',
          'date': '15.05.2025',
          'type': 'Havale',
          'description': 'Hizmet alımı ödemesi',
        },
      ];
      final mockCashBalances = {
        'anaKasa': 45600,
        'dolarKasa': 12800,
        'euroKasa': 18500,
        'perakendeKasa': 9800,
        'yurtdisiKasa': 7500,
      };

      final mockCashTransactions = [
        {
          'id': 1,
          'type': 'Tahsilat',
          'amount': 1250.00,
          'date': '22.05.2025',
          'cashAccount': 'Ana Kasa',
          'description': 'Fatura tahsilatı - ABC Ltd.',
          'reference': 'KSA-2025-0001',
        },
        {
          'id': 2,
          'type': 'Ödeme',
          'amount': 750.00,
          'date': '21.05.2025',
          'cashAccount': 'Ana Kasa',
          'description': 'Kira ödemesi',
          'reference': 'KSA-2025-0002',
        },
        {
          'id': 3,
          'type': 'Tahsilat',
          'amount': 3200.00,
          'date': '20.05.2025',
          'cashAccount': 'Ana Kasa',
          'description': 'Fatura tahsilatı - XYZ A.Ş.',
          'reference': 'KSA-2025-0003',
        },
        {
          'id': 4,
          'type': 'Ödeme',
          'amount': 980.00,
          'date': '19.05.2025',
          'cashAccount': 'Ana Kasa',
          'description': 'Ofis malzemeleri',
          'reference': 'KSA-2025-0004',
        },
        {
          'id': 5,
          'type': 'Tahsilat',
          'amount': 1785.00,
          'date': '18.05.2025',
          'cashAccount': 'Ana Kasa',
          'description': 'Fatura tahsilatı - DEF Sanayi',
          'reference': 'KSA-2025-0005',
        },
      ];

      state = state.copyWith(
        isLoading: false,
        invoices: mockInvoices,
        payments: mockPayments,
        cashTransactions: mockCashTransactions,
        cashBalances: mockCashBalances,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Veri yüklenirken hata oluştu: $e',
      );
    }
  }

  // Diğer finans işlemleri için metodlar burada olacak
  Future<void> createInvoice(Map<String, dynamic> invoiceData) async {
    // Invoice oluşturma işlemi
  }

  Future<void> recordPayment(Map<String, dynamic> paymentData) async {
    // Ödeme kaydetme işlemi
  }

  Future<void> transferFunds(
    String fromAccount,
    String toAccount,
    double amount,
  ) async {
    // Fonları transfer etme işlemi
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((
  ref,
) {
  return FinanceNotifier();
});
