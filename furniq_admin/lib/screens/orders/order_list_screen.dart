import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String _searchQuery = '';
  OrderStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().streamOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1810),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header Actions
          Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID or Customer Name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              const SizedBox(width: 16),
              
              // Status Filter
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<OrderStatus?>(
                      isExpanded: true,
                      value: _statusFilter,
                      hint: const Text('All Statuses'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        ...OrderStatus.values.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())),
                        ),
                      ],
                      onChanged: (value) => setState(() => _statusFilter = value),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table
          Expanded(
            child: Container(
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
              child: Consumer<OrderProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
                  }

                  // Filter logic
                  var filteredOrders = provider.orders;
                  if (_searchQuery.isNotEmpty) {
                    filteredOrders = filteredOrders.where((o) =>
                        o.id.toLowerCase().contains(_searchQuery) ||
                        o.shippingAddress.fullName.toLowerCase().contains(_searchQuery)).toList();
                  }
                  if (_statusFilter != null) {
                    filteredOrders = filteredOrders.where((o) => o.status == _statusFilter).toList();
                  }

                  if (filteredOrders.isEmpty) {
                    return const Center(child: Text('No orders found', style: TextStyle(fontSize: 16, color: Colors.grey)));
                  }

                  return DataTable2(
                    columnSpacing: 16,
                    horizontalMargin: 24,
                    minWidth: 800,
                    columns: const [
                      DataColumn2(label: Text('ORDER ID'), size: ColumnSize.M),
                      DataColumn2(label: Text('CUSTOMER'), size: ColumnSize.L),
                      DataColumn2(label: Text('DATE'), size: ColumnSize.M),
                      DataColumn2(label: Text('TOTAL'), size: ColumnSize.S, numeric: true),
                      DataColumn2(label: Text('STATUS'), size: ColumnSize.M),
                      DataColumn2(label: Text('DETAILS'), size: ColumnSize.S),
                    ],
                    rows: filteredOrders.map((order) {
                      return DataRow(
                        cells: [
                          DataCell(Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(order.shippingAddress.fullName)),
                          DataCell(Text(DateFormat('MMM d, yyyy').format(order.createdAt))),
                          DataCell(Text('Rs. ${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(
                            DropdownButtonHideUnderline(
                              child: DropdownButton<OrderStatus>(
                                value: order.status,
                                isDense: true,
                                focusColor: Colors.transparent,
                                dropdownColor: Colors.white,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                items: OrderStatus.values.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: _buildStatusBadge(s),
                                  );
                                }).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null && newStatus != order.status) {
                                    context.read<OrderProvider>().updateOrderStatus(order.id, newStatus);
                                  }
                                },
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF6B4423)),
                                  tooltip: 'View Details',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => OrderDetailScreen(order: order),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case OrderStatus.pending:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      case OrderStatus.processing:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case OrderStatus.shipped:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case OrderStatus.delivered:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
