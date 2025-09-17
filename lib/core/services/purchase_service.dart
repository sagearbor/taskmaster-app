import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

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
  final PurchaseDetails? purchaseDetails;

  const PurchaseResult({
    required this.status,
    this.error,
    this.purchaseDetails,
  });
}

abstract class PurchaseService {
  Future<void> initialize();
  Future<List<ProductDetails>> getProducts(Set<String> productIds);
  Future<PurchaseResult> buyProduct(ProductDetails product);
  Future<void> restorePurchases();
  Stream<List<PurchaseDetails>> get purchaseStream;
  bool get isAvailable;
  void dispose();
}

class PurchaseServiceImpl implements PurchaseService {
  static const String proVersionId = 'taskmaster_pro';
  static const String taskPackBasicId = 'task_pack_basic';
  static const String taskPackPremiumId = 'task_pack_premium';
  static const String taskPackUltimateId = 'task_pack_ultimate';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final StreamController<List<PurchaseDetails>> _purchaseController = 
      StreamController<List<PurchaseDetails>>.broadcast();

  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  @override
  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (_isAvailable) {
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
      }

      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) => print('Purchase stream error: $error'),
      );
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    _purchaseController.add(purchaseDetailsList);
    
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        print('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase and deliver content
        _verifyAndDeliverProduct(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    // In a real app, you should verify the purchase with your backend
    // For now, we'll just mark it as delivered
    
    switch (purchaseDetails.productID) {
      case proVersionId:
        await _deliverProVersion();
        break;
      case taskPackBasicId:
        await _deliverTaskPack('basic');
        break;
      case taskPackPremiumId:
        await _deliverTaskPack('premium');
        break;
      case taskPackUltimateId:
        await _deliverTaskPack('ultimate');
        break;
    }
  }

  Future<void> _deliverProVersion() async {
    // Enable pro features (remove ads, unlock premium content)
    // This would typically involve updating user preferences or backend state
    print('Delivered Pro Version');
  }

  Future<void> _deliverTaskPack(String packType) async {
    // Unlock task pack content
    print('Delivered Task Pack: $packType');
  }

  @override
  Future<List<ProductDetails>> getProducts(Set<String> productIds) async {
    if (!_isAvailable) return [];

    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    return _products;
  }

  @override
  Future<PurchaseResult> buyProduct(ProductDetails product) async {
    if (!_isAvailable) {
      return const PurchaseResult(
        status: PurchaseStatus.error,
        error: 'In-app purchases not available',
      );
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (success) {
        return const PurchaseResult(status: PurchaseStatus.pending);
      } else {
        return const PurchaseResult(
          status: PurchaseStatus.error,
          error: 'Failed to initiate purchase',
        );
      }
    } catch (e) {
      return PurchaseResult(
        status: PurchaseStatus.error,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    
    await _inAppPurchase.restorePurchases();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  @override
  bool get isAvailable => _isAvailable;

  @override
  void dispose() {
    _subscription.cancel();
    _purchaseController.close();
  }
}

// Mock implementation for testing
class MockPurchaseService implements PurchaseService {
  final StreamController<List<PurchaseDetails>> _purchaseController = 
      StreamController<List<PurchaseDetails>>.broadcast();

  final List<ProductDetails> _mockProducts = [
    MockProductDetails(
      id: PurchaseServiceImpl.proVersionId,
      title: 'Taskmaster Pro',
      description: 'Remove ads and unlock premium features',
      price: '\$4.99',
      rawPrice: 4.99,
      currencyCode: 'USD',
    ),
    MockProductDetails(
      id: PurchaseServiceImpl.taskPackBasicId,
      title: 'Basic Task Pack',
      description: '50 additional tasks',
      price: '\$1.99',
      rawPrice: 1.99,
      currencyCode: 'USD',
    ),
    MockProductDetails(
      id: PurchaseServiceImpl.taskPackPremiumId,
      title: 'Premium Task Pack',
      description: '100 premium tasks with modifiers',
      price: '\$2.99',
      rawPrice: 2.99,
      currencyCode: 'USD',
    ),
    MockProductDetails(
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
    return _mockProducts.where((product) => productIds.contains(product.id)).toList();
  }

  @override
  Future<PurchaseResult> buyProduct(ProductDetails product) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate purchase flow
    
    // Simulate successful purchase
    return const PurchaseResult(status: PurchaseStatus.purchased);
  }

  @override
  Future<void> restorePurchases() async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulate restored purchases
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  @override
  bool get isAvailable => true;

  @override
  void dispose() {
    _purchaseController.close();
  }
}

class MockProductDetails extends ProductDetails {
  MockProductDetails({
    required String id,
    required String title,
    required String description,
    required String price,
    required double rawPrice,
    required String currencyCode,
  }) : super(
          id: id,
          title: title,
          description: description,
          price: price,
          rawPrice: rawPrice,
          currencyCode: currencyCode,
        );
}

// iOS delegate for handling payment queue events
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}