import 'dart:async';

enum PurchaseStatus {
  pending,
  purchased,
  error,
  canceled,
  restored,
}

class PurchaseResult {
  final PurchaseStatus status;
  final String? error;

  const PurchaseResult({
    required this.status,
    this.error,
  });
}

abstract class PurchaseService {
  Future<void> initialize();
  Future<PurchaseResult> buyProduct(String productId);
  Future<void> restorePurchases();
  bool get isAvailable;
  void dispose();
}

// Mock implementation for testing
class MockPurchaseService implements PurchaseService {
  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<PurchaseResult> buyProduct(String productId) async {
    await Future.delayed(const Duration(seconds: 2));
    return const PurchaseResult(status: PurchaseStatus.purchased);
  }

  @override
  Future<void> restorePurchases() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  bool get isAvailable => true;

  @override
  void dispose() {}
}

// Placeholder for real implementation
class PurchaseServiceImpl extends MockPurchaseService {
  // Will be implemented when in_app_purchase is added
}