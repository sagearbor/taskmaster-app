import 'package:flutter/material.dart';
import '../../../../core/widgets/ad_banner_widget_simple.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskmaster Store'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pro Version Card
          Card(
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
                        const Text(
                          'Taskmaster Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• Remove all advertisements\n'
                      '• Unlimited task modifiers\n'
                      '• Geo-located tasks\n'
                      '• Secret mission modes\n'
                      '• Advanced team features',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Purchases coming soon!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[300],
                        foregroundColor: Colors.purple[800],
                      ),
                      child: const Text('Upgrade to Pro - \$4.99'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Task Packs
          const Text(
            'Task Packs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          _buildTaskPackCard(
            context,
            'Basic Task Pack',
            '50 additional creative tasks',
            '\$1.99',
            Colors.blue,
          ),
          
          _buildTaskPackCard(
            context,
            'Premium Task Pack',
            '100 premium tasks with modifiers',
            '\$2.99',
            Colors.orange,
          ),
          
          _buildTaskPackCard(
            context,
            'Ultimate Task Pack',
            '200 premium tasks + AR challenges',
            '\$4.99',
            Colors.green,
          ),
          
          const SizedBox(height: 20),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildTaskPackCard(
    BuildContext context,
    String title,
    String description,
    String price,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.task, color: color),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title - Coming soon!')),
            );
          },
          child: Text(price),
        ),
      ),
    );
  }
}