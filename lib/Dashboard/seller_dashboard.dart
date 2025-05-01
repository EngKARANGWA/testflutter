// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Product/product_post_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/product_service.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import '../Modals/edit_profile_modal.dart';
import '../Modals/location_picker_modal.dart';
import 'dart:convert';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _myProducts = [];

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Clothing',
    'Books',
    'Home & Garden',
    'Sports',
    'Toys',
    'Other',
  ];

  // Statistics data
  final Map<String, dynamic> _stats = {
    'totalSales': 1250.00,
    'totalProducts': 15,
    'totalViews': 1200,
    'totalInCart': 8,
    'rating': 4.7,
  };

  bool _notificationsEnabled = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    _loadThemePreferences();
    _loadProducts();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _getImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _showNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = prefs.getString('current_user_id') ?? 'default_seller';
    final notifications = await NotificationService.getNotifications(
      sellerId: sellerId,
    );
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (notifications.isEmpty)
                    const Text('No notifications')
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return ListTile(
                            title: Text(notification['message']),
                            subtitle: Text(
                              DateTime.parse(
                                notification['timestamp'],
                              ).toString(),
                            ),
                            trailing:
                                notification['read']
                                    ? null
                                    : IconButton(
                                      icon: const Icon(Icons.check),
                                      onPressed: () async {
                                        await NotificationService.markAsRead(
                                          notification['id'],
                                        );
                                        setState(() {});
                                      },
                                    ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _showSettings() async {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: _isDarkMode,
                      onChanged: _toggleTheme,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await ProductService.getProducts();
    setState(() {
      _myProducts =
          products.where((product) => product['status'] == 'Active').toList();
    });
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Sales', '\$${_stats['totalSales']}'),
                _buildStatItem('Products', _stats['totalProducts'].toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Views', _stats['totalViews'].toString()),
                _buildStatItem('In Cart', _stats['totalInCart'].toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${_stats['rating']} Rating',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildAddProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _productNameController,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items:
                _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _categoryController.text = newValue ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog<(String, double, double)>(
                context: context,
                builder:
                    (context) => LocationPickerModal(
                      onLocationSelected: (address, lat, lng) {
                        Navigator.pop(context, (address, lat, lng));
                      },
                    ),
              );

              if (result != null) {
                setState(() {
                  _addressController.text = result.$1;
                });
              }
            },
            icon: const Icon(Icons.location_on),
            label: const Text('Select Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          if (_addressController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _addressController.text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _getImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Product Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_productNameController.text.isEmpty ||
                  _priceController.text.isEmpty ||
                  _categoryController.text.isEmpty ||
                  _addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Validate price format
              final price = double.tryParse(_priceController.text);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final product = {
                  'name': _productNameController.text,
                  'price': price,
                  'category': _categoryController.text,
                  'description': _descriptionController.text,
                  'address': _addressController.text,
                  'image': _imageFile ?? 'https://via.placeholder.com/150',
                  'status': 'Active',
                  'views': 0,
                  'inCart': 0,
                };

                await ProductService.saveProduct(product);
                await _loadProducts();

                setState(() {
                  _productNameController.clear();
                  _priceController.clear();
                  _categoryController.clear();
                  _descriptionController.clear();
                  _addressController.clear();
                  _imageFile = null;
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding product: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Post Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child:
                      product['isLocalImage'] == true
                          ? Image.memory(
                            base64Decode(product['image'] ?? ''),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : Image.network(
                            product['image']?.toString() ??
                                'https://via.placeholder.com/150',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${(product['price'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, size: 16),
                        const SizedBox(width: 4),
                        Text('${product['views'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name']?.toString() ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              _productNameController.text =
                                  product['name']?.toString() ?? '';
                              _priceController.text =
                                  (product['price'] ?? 0.0).toString();
                              _categoryController.text =
                                  product['category']?.toString() ?? '';
                              _descriptionController.text =
                                  product['description']?.toString() ?? '';
                              _addressController.text =
                                  product['address']?.toString() ?? '';
                              setState(() => _currentIndex = 2);
                              break;
                            case 'delete':
                              await ProductService.deleteProduct(
                                product['id']?.toString() ?? '',
                              );
                              await _loadProducts();
                              break;
                            case 'deactivate':
                              product['status'] = 'Inactive';
                              await ProductService.updateProduct(product);
                              await _loadProducts();
                              break;
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Product'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Product'),
                              ),
                              const PopupMenuItem(
                                value: 'deactivate',
                                child: Text('Deactivate'),
                              ),
                            ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Tooltip(
                          message:
                              product['address']?.toString() ?? 'No address',
                          child: Text(
                            product['address']?.toString() ?? 'No address',
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${product['inCart'] ?? 0} in cart',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product['category']?.toString() ?? 'Uncategorized',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        product['status']?.toString() ?? 'Unknown',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: PaymentService.getPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending payments'));
        }

        final payments = snapshot.data!;
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID: ${payment['id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                payment['status'] == 'Approved'
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            payment['status'],
                            style: TextStyle(
                              color:
                                  payment['status'] == 'Approved'
                                      ? Colors.green
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: \$${(payment['amount'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Payment Method: ${payment['paymentMethod']}'),
                    const SizedBox(height: 8),
                    Text('Payment Timing: ${payment['paymentTiming']}'),
                    const SizedBox(height: 16),
                    if (payment['status'] == 'Pending')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await PaymentService.updatePaymentStatus(
                                  payment['id'],
                                  'Approved',
                                );
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: const Text('Approve Payment'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await PaymentService.updatePaymentStatus(
                                  payment['id'],
                                  'Rejected',
                                );
                                setState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No user data found'));
        }

        final user = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.person,
                        'Name',
                        user['name'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.business,
                        'Business Name',
                        user['businessName'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        user['email'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        user['phone'] ?? 'Not set',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.location_on,
                        'Business Address',
                        user['businessAddress'] ?? 'Not set',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.account_circle,
                        'User Type',
                        'Seller',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Member Since',
                        DateTime.parse(
                          user['createdAt'] ?? DateTime.now().toIso8601String(),
                        ).toString().split(' ')[0],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => EditProfileModal(user: user),
                  );
                  if (result == true) {
                    setState(() {}); // Refresh profile data
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // My Products Tab
          ListView(
            children: [
              _buildStatsCard(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_myProducts[index]);
                },
              ),
            ],
          ),
          // Add Product Tab
          _buildAddProductForm(),
          // Payments Tab
          _buildPaymentsTab(),
          // Profile Tab
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.blue,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'My Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ProductPostModal(),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
