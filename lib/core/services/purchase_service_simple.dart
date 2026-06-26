import 'dart:async';

/// Package-free in-app-purchase layer used in development / demo mode.
///
/// The production integration (StoreKit / Play Billing via the
/// `in_app_purchase` package) was intentionally deferred to keep the app
/// dependency-light and buildable on web. These types mirror the shape the
/// store UI needs so it can run a realistic mock purchase flow without any
/// platform plugins. Swap [PurchaseServiceImpl] for a real implementation
/// once store products are configured.
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

/// Lightweight, plugin-free stand-in for the `in_app_purchase` package's
/// `ProductDetails`. Holds just the fields the store UI renders.
class ProductDetails {
  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;

  const ProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
  });
}

abstract class PurchaseService {
  Future<void> initialize();
  Future<List<ProductDetails>> getProducts(Set<String> productIds);
  Future<PurchaseResult> buyProduct(ProductDetails product);
  Future<void> restorePurchases();
  bool get isAvailable;
  void dispose();
}

/// Mock implementation: returns a fixed catalog and always "succeeds".
class MockPurchaseService implements PurchaseService {
  static const List<ProductDetails> _catalog = [
    ProductDetails(
      id: PurchaseServiceImpl.proVersionId,
      title: 'TaskCaster Pro',
      description: 'Remove ads and unlock premium features',
      price: '\$4.99',
      rawPrice: 4.99,
      currencyCode: 'USD',
    ),
    ProductDetails(
      id: PurchaseServiceImpl.taskPackBasicId,
      title: 'Basic Task Pack',
      description: '50 additional tasks',
      price: '\$1.99',
      rawPrice: 1.99,
      currencyCode: 'USD',
    ),
    ProductDetails(
      id: PurchaseServiceImpl.taskPackPremiumId,
      title: 'Premium Task Pack',
      description: '100 premium tasks with modifiers',
      price: '\$2.99',
      rawPrice: 2.99,
      currencyCode: 'USD',
    ),
    ProductDetails(
      id: PurchaseServiceImpl.taskPackUltimateId,
      title: 'Ultimate Task Pack',
      description: '200 premium tasks + AR tasks',
      price: '\$4.99',
      rawPrice: 4.99,
      currencyCode: 'USD',
    ),
  ];

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<ProductDetails>> getProducts(Set<String> productIds) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _catalog.where((p) => productIds.contains(p.id)).toList();
  }

  @override
  Future<PurchaseResult> buyProduct(ProductDetails product) async {
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

/// Placeholder for the real implementation. Reuses the mock behaviour until
/// `in_app_purchase` is wired up and store products are configured.
class PurchaseServiceImpl extends MockPurchaseService {
  static const String proVersionId = 'taskcaster_pro';
  static const String taskPackBasicId = 'task_pack_basic';
  static const String taskPackPremiumId = 'task_pack_premium';
  static const String taskPackUltimateId = 'task_pack_ultimate';
}
