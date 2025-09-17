import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/widgets/ad_banner_widget.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final PurchaseService _purchaseService = sl<PurchaseService>();
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  String? _error;

  final Set<String> _productIds = {
    PurchaseServiceImpl.proVersionId,
    PurchaseServiceImpl.taskPackBasicId,
    PurchaseServiceImpl.taskPackPremiumId,
    PurchaseServiceImpl.taskPackUltimateId,
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _purchaseService.getProducts(_productIds);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _buyProduct(ProductDetails product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _purchaseService.buyProduct(product);
      
      if (result.status == PurchaseStatus.purchased) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased ${product.title}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _purchaseService.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore purchases: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskmaster Store'),
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load store',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadProducts();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Pro Version Section
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: _buildProVersionCard(),
                    ),

                    // Task Packs Section
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Text(
                            'Task Packs',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._getTaskPackProducts().map((product) => 
                            _buildTaskPackCard(product)).toList(),
                          const SizedBox(height: 16),
                          
                          // Ad Banner
                          const AdBannerWidget(
                            showCloseButton: true,
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProVersionCard() {
    final proProduct = _products.firstWhere(
      (product) => product.id == PurchaseServiceImpl.proVersionId,
      orElse: () => throw StateError('Pro product not found'),
    );

    return Card(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple[400]!, Colors.purple[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow[300],
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Taskmaster Pro',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    proProduct.price,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.yellow[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Features list
              _buildFeatureItem('🚫 Remove all advertisements', Colors.white),
              _buildFeatureItem('🎯 Unlimited task modifiers', Colors.white),
              _buildFeatureItem('🗺️ Geo-located tasks', Colors.white),
              _buildFeatureItem('🤫 Secret mission modes', Colors.white),
              _buildFeatureItem('👥 Advanced team features', Colors.white),
              _buildFeatureItem('📱 Priority customer support', Colors.white),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _buyProduct(proProduct),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[300],
                    foregroundColor: Colors.purple[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Upgrade to Pro',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTaskPackCard(ProductDetails product) {
    String description;
    String emoji;
    Color accentColor;
    
    switch (product.id) {
      case PurchaseServiceImpl.taskPackBasicId:
        description = '50 additional creative tasks';
        emoji = '📝';
        accentColor = Colors.blue;
        break;
      case PurchaseServiceImpl.taskPackPremiumId:
        description = '100 premium tasks with modifiers';
        emoji = '🎯';
        accentColor = Colors.orange;
        break;
      case PurchaseServiceImpl.taskPackUltimateId:
        description = '200 premium tasks + AR challenges';
        emoji = '🚀';
        accentColor = Colors.green;
        break;
      default:
        description = product.description;
        emoji = '📦';
        accentColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  product.price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _buyProduct(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Buy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ProductDetails> _getTaskPackProducts() {
    return _products.where((product) => 
      product.id != PurchaseServiceImpl.proVersionId).toList();
  }
}