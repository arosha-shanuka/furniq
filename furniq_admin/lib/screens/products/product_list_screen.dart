import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1810),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your product catalog',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openProductForm(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4423),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Product table
          Expanded(
            child: Consumer2<ProductProvider, CategoryProvider>(
              builder: (context, productProvider, categoryProvider, _) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = productProvider.products;
                if (_searchQuery.isNotEmpty) {
                  products = products
                      .where((p) =>
                          p.name.toLowerCase().contains(_searchQuery) ||
                          p.material.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No products yet'
                              : 'No products match your search',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                dataRowMinHeight: 76,
                                dataRowMaxHeight: 76,
                                headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFFF5F0EB)),
                                columnSpacing: 24,
                                horizontalMargin: 20,
                                columns: const [
                                  DataColumn(label: Text('Image')),
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Price')),
                                  DataColumn(label: Text('Stock')),
                                  DataColumn(label: Text('Featured')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: products.map((product) {
                                  final category = categoryProvider.categories
                                      .where((c) => c.id == product.categoryId)
                                      .firstOrNull;
                                  return DataRow(cells: [
                                    DataCell(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: product.mainImageUrl.isNotEmpty
                                              ? Image.network(
                                                  product.mainImageUrl,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.image,
                                                        size: 24,
                                                        color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image,
                                                      size: 24,
                                                      color: Colors.grey),
                                                ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                      product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    )),
                                    DataCell(Text(
                                        category?.name ?? product.categoryId)),
                                    DataCell(Text(
                                      'LKR ${product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    )),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: product.stockStatus.name ==
                                                  'inStock'
                                              ? Colors.green[50]
                                              : product.stockStatus.name ==
                                                      'lowStock'
                                                  ? Colors.orange[50]
                                                  : Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${product.stockQuantity} - ${product.stockStatusText}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: product.stockStatus.name ==
                                                    'inStock'
                                                ? Colors.green[700]
                                                : product.stockStatus.name ==
                                                        'lowStock'
                                                    ? Colors.orange[700]
                                                    : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Icon(
                                        product.isFeatured
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: product.isFeatured
                                            ? Colors.amber
                                            : Colors.grey[400],
                                      ),
                                    ),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20),
                                          color: const Color(0xFF6B4423),
                                          tooltip: 'Edit',
                                          onPressed: () => _openProductForm(
                                              context,
                                              product: product),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20),
                                          color: Colors.red[400],
                                          tooltip: 'Delete',
                                          onPressed: () => _confirmDelete(
                                              context,
                                              product.id,
                                              product.name),
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openProductForm(BuildContext context, {dynamic product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductProvider>().deleteProduct(id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$name" deleted'),
                  backgroundColor: Colors.red[700],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
