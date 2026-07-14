import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/money_models.dart';
import '../data/repositories/money_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../services/fx_rates_service.dart';

const _uuid = Uuid();

// ── Bank Accounts ──
final bankAccountsProvider =
    AsyncNotifierProvider<BankAccountsNotifier, List<BankAccount>>(
  BankAccountsNotifier.new,
);

class BankAccountsNotifier extends AsyncNotifier<List<BankAccount>> {
  @override
  Future<List<BankAccount>> build() =>
      MoneyRepository.instance.getBankAccounts();

  Future<void> upsert(BankAccount acc) async {
    await MoneyRepository.instance.upsertBankAccount(acc);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteBankAccount(id);
    state = AsyncData(state.value!.where((b) => b.id != id).toList());
  }

  Future<void> addNew({AccountType accountType = AccountType.savings}) async {
    final acc = BankAccount(
      id: _uuid.v4(),
      name: accountType == AccountType.digitalWallet ? 'New Wallet' : 'New Account',
      accountType: accountType,
      order: (state.value?.length ?? 0),
    );
    await upsert(acc);
  }
}

// ── Credit Cards ──
final creditCardsProvider =
    AsyncNotifierProvider<CreditCardsNotifier, List<CreditCard>>(
  CreditCardsNotifier.new,
);

class CreditCardsNotifier extends AsyncNotifier<List<CreditCard>> {
  @override
  Future<List<CreditCard>> build() => MoneyRepository.instance.getCreditCards();

  Future<void> upsert(CreditCard card) async {
    await MoneyRepository.instance.upsertCreditCard(card);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteCreditCard(id);
    state = AsyncData(state.value!.where((c) => c.id != id).toList());
  }

  Future<void> addNew() async {
    final card = CreditCard(
      id: _uuid.v4(),
      name: 'New Card',
      order: (state.value?.length ?? 0),
    );
    await upsert(card);
  }
}

// ── Installment Plans ──
final installmentPlansProvider =
    AsyncNotifierProvider<InstallmentPlansNotifier, List<InstallmentPlan>>(
  InstallmentPlansNotifier.new,
);

class InstallmentPlansNotifier extends AsyncNotifier<List<InstallmentPlan>> {
  @override
  Future<List<InstallmentPlan>> build() =>
      MoneyRepository.instance.getInstallmentPlans();

  Future<void> upsert(InstallmentPlan plan) async {
    await MoneyRepository.instance.upsertInstallmentPlan(plan);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteInstallmentPlan(id);
    state = AsyncData(state.value!.where((p) => p.id != id).toList());
  }

  Future<void> markPaid(String id, int paidMonths) async {
    await MoneyRepository.instance.markInstallmentPaid(id, paidMonths);
    state = AsyncData(
      state.value!
          .map((p) => p.id == id ? p.copyWith(paidMonths: paidMonths) : p)
          .toList(),
    );
  }
}

// ── Debts ──
final debtsProvider =
    AsyncNotifierProvider<DebtsNotifier, List<ExternalDebt>>(
  DebtsNotifier.new,
);

class DebtsNotifier extends AsyncNotifier<List<ExternalDebt>> {
  @override
  Future<List<ExternalDebt>> build() => MoneyRepository.instance.getDebts();

  Future<void> upsert(ExternalDebt debt) async {
    await MoneyRepository.instance.upsertDebt(debt);
    final existing = state.value?.indexWhere((d) => d.id == debt.id) ?? -1;
    if (existing >= 0) {
      final updated = [...state.value!];
      updated[existing] = debt;
      state = AsyncData(updated);
    } else {
      state = AsyncData([...state.value!, debt]);
    }
  }

  Future<void> add(ExternalDebt debt) => upsert(debt);

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteDebt(id);
    state = AsyncData(state.value!.where((d) => d.id != id).toList());
  }
}

// ── Investments ──
final investmentsProvider =
    AsyncNotifierProvider<InvestmentsNotifier, List<Investment>>(
  InvestmentsNotifier.new,
);

class InvestmentsNotifier extends AsyncNotifier<List<Investment>> {
  @override
  Future<List<Investment>> build() =>
      MoneyRepository.instance.getInvestments();

  Future<void> add(Investment inv) async {
    await MoneyRepository.instance.upsertInvestment(inv);
    final existing = state.value?.indexWhere((i) => i.id == inv.id) ?? -1;
    if (existing >= 0) {
      final updated = [...state.value!];
      updated[existing] = inv;
      state = AsyncData(updated);
    } else {
      state = AsyncData([...state.value!, inv]);
    }
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteInvestment(id);
    state = AsyncData(state.value!.where((i) => i.id != id).toList());
  }
}

// ── Transactions ──
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() =>
      MoneyRepository.instance.getTransactions();

  Future<void> add(Transaction tx) async {
    await MoneyRepository.instance.addTransaction(tx);
    state = AsyncData([tx, ...state.value!]);
  }

  Future<void> delete(String id) async {
    await MoneyRepository.instance.deleteTransaction(id);
    state = AsyncData(state.value!.where((t) => t.id != id).toList());
  }
}

// ── Cash on Hand ──
class CashOnHandNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() => MoneyRepository.instance.getCashOnHand();

  Future<void> set(double amount) async {
    await MoneyRepository.instance.setCashOnHand(amount);
    state = AsyncData(amount);
  }
}

final cashOnHandProvider =
    AsyncNotifierProvider<CashOnHandNotifier, double>(CashOnHandNotifier.new);

// ── Stock Price (Alpha Vantage) ──
final stockPriceProvider =
    FutureProvider.family<double?, String>((ref, ticker) async {
  if (ticker.isEmpty) return null;
  try {
    final prefs = await SharedPreferences.getInstance();
    final apiKey =
        prefs.getString(AppConstants.prefAlphaVantageApiKey) ?? '';
    if (apiKey.isEmpty) return null;
    final res = await http
        .get(Uri.parse(
          'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$ticker&apikey=$apiKey',
        ))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final quote = json['Global Quote'] as Map<String, dynamic>?;
      final priceStr = quote?['05. price'] as String?;
      return priceStr != null ? double.tryParse(priceStr) : null;
    }
  } catch (_) {}
  return null;
});

// ── Finance Summary (computed, FX-aware) ──
final financeSummaryProvider = Provider((ref) {
  final base = ref.watch(currencyNotifierProvider).value ?? 'EGP';
  final rates = ref.watch(fxRatesProvider).value ??
      {'USD': 1.0, 'EGP': 50.0, 'EUR': 0.92, 'GBP': 0.79, 'SAR': 3.75, 'AED': 3.67};

  // Convert any amount to the user's base currency
  double toBase(double amount, String currency) =>
      convertCurrency(amount, from: currency, to: base, rates: rates);

  final banks = ref.watch(bankAccountsProvider).value ?? [];
  final debts = ref.watch(debtsProvider).value ?? [];
  final txs = ref.watch(transactionsProvider).value ?? [];
  final cards = ref.watch(creditCardsProvider).value ?? [];
  final installments = ref.watch(installmentPlansProvider).value ?? [];

  // Legacy CC totals from bank_accounts (converted to base)
  final totalCC = banks.fold(0.0, (s, b) => s + toBase(b.creditCardBalance, b.currency));
  final totalLimit = banks.fold(0.0, (s, b) => s + toBase(b.creditCardLimit, b.currency));

  // New: from dedicated credit_cards table (converted to base)
  final totalCCFromCards = cards.fold(0.0, (s, c) => s + toBase(c.balance, c.currency));
  final totalCardLimit = cards.fold(0.0, (s, c) => s + toBase(c.limit, c.currency));
  final ccMinPayments = cards.fold(0.0, (s, c) => s + toBase(c.minPaymentAmount, c.currency));
  final totalInstallments = installments
      .where((p) => !p.isCompleted)
      .fold(0.0, (s, p) => s + toBase(p.monthlyPayment, p.currency));

  final totalSavings = banks.fold(0.0, (s, b) => s + toBase(b.savingsBalance, b.currency));
  final totalCurrent = banks.fold(0.0, (s, b) => s + toBase(b.currentBalance, b.currency));
  // ExternalDebt has no currency field — assumed to be in base currency
  final totalExtDebt = debts.fold(0.0, (s, d) => s + d.amount);

  final unifiedCC = totalCC + totalCCFromCards;
  final unifiedLimit = totalLimit + totalCardLimit;
  final totalDebt = unifiedCC + totalExtDebt;
  final remainingLimit = unifiedLimit - unifiedCC;

  final now = DateTime.now();
  final todaySpend = txs
      .where((t) =>
          !t.isIncome &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day)
      .fold(0.0, (s, t) => s + toBase(t.amount, t.currency));

  return FinanceSummary(
    totalCC: unifiedCC,
    totalLimit: unifiedLimit,
    remainingLimit: remainingLimit,
    totalSavings: totalSavings,
    totalCurrent: totalCurrent,
    totalExtDebt: totalExtDebt,
    totalDebt: totalDebt,
    todaySpend: todaySpend,
    totalCCFromCards: totalCCFromCards,
    totalInstallments: totalInstallments,
    totalMonthlyObligation: ccMinPayments + totalInstallments,
  );
});
