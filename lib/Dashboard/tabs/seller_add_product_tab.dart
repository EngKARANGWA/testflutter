import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/product_service.dart';
import '../../Modals/location_picker_modal.dart';

class SellerAddProductTab extends StatefulWidget {
  const SellerAddProductTab({super.key});

  @override
  State<SellerAddProductTab> createState() => _SellerAddProductTabState();
}

class _SellerAddProductTabState extends State<SellerAddProductTab> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

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

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
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
            items: _categories.map((String category) {
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
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // ElevatedButton.icon(
          //   onPressed: () async {
          //     final result = await showDialog<(String, double, double)>(
          //       context: context,
          //       builder: (context) => LocationPickerModal(
          //         onLocationSelected: (address, lat, lng) {
          //           Navigator.pop(context, (address, lat, lng));
          //         },
          //       ),
          //     );

          //     if (result != null) {
          //       setState(() {
          //         _addressController.text = result.$1;
          //       });
          //     }
          //   },
          //   icon: const Icon(Icons.location_on),
          //   label: const Text('Select Location'),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Colors.deepPurple,
          //     minimumSize: const Size(double.infinity, 48),
          //   ),
          // ),
          // if (_addressController.text.isNotEmpty) ...[
          //   const SizedBox(height: 8),
          //   Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color: Colors.grey[200],
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: Text(
          //       _addressController.text,
          //       style: const TextStyle(fontSize: 14),
          //     ),
          //   ),
          // ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _getImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _imageFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add product image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          // ElevatedButton.icon(
          //   onPressed: _getImage,
          //   icon: const Icon(
          //     Icons.add_photo_alternate,
          //     color: Colors.white,
          //   ),
          //   label: const Text(
          //     'Add Product Image',
          //     style: TextStyle(color: Colors.white),
          //   ),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Colors.deepPurple,
          //     padding: const EdgeInsets.symmetric(vertical: 16),
          //   ),
          // ),
          // if (_imageFile != null)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 16),
          //     child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
          //   ),
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
            child: const Text(
              'Post Product',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
