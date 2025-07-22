import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../models/product.dart';
import '../../services/api_service.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({Key? key}) : super(key: key);

  @override
  _ProductManagementState createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<String> categories = ['Batteries', 'Storage', 'Chargers', 'EV Motors', 'EV Controllers', 'Tires & Wheels'];
  String? _selectedCategory;
  String sortBy = 'name';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final loadedProducts = await _apiService.getProducts();
      setState(() {
        products = loadedProducts;
        _filterAndSortProducts();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addProduct(Product product) async {
    try {
      final newProduct = await _apiService.addProduct(product);
      setState(() {
        products.add(newProduct);
        _filterAndSortProducts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProduct(Product product) async {
    try {
      final updatedProduct = await _apiService.updateProduct(product);
      setState(() {
        final index = products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          products[index] = updatedProduct;
          _filterAndSortProducts();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      setState(() {
        products.removeWhere((p) => p.id == productId);
        _filterAndSortProducts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: ${e.toString()}')),
      );
    }
  }

  void _filterAndSortProducts() {
    setState(() {
      filteredProducts = List<Product>.from(products);
      
      if (_selectedCategory != null) {
        filteredProducts = filteredProducts
            .where((product) => product.category == _selectedCategory)
            .toList();
      }

      switch (sortBy) {
        case 'name':
          filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price':
          filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'stock':
          filteredProducts.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
          break;
      }
    });
  }

  void _filterProducts(String query) {
    setState(() {
      filteredProducts = products.where((product) {
        final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch = product.description.toLowerCase().contains(query.toLowerCase());
        final categoryMatch = _selectedCategory == null || product.category == _selectedCategory;
        
        return (nameMatch || descriptionMatch) && categoryMatch;
      }).toList();
      
      _filterAndSortProducts();
    });
  }

  void _sortProducts() {
    setState(() {
      switch (sortBy) {
        case 'name':
          filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price':
          filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'stock':
          filteredProducts.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
          break;
      }
    });
  }

  void _showDeleteConfirmation(String? id) {
    if (id == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(id);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        // For demonstration, we'll use the data URL approach for web
        // In a production app, you would upload this to a cloud storage service
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64Image';
      }
      return null;
    } catch (e) {
      _showErrorDialog('Error picking image: ${e.toString()}');
      return null;
    }
  }

  Future<void> _addNewProduct() async {
    await _showProductForm();
  }

  Future<void> _editProduct(Product product) async {
    await _showProductForm(product: product);
  }

  Future<void> _showProductForm({Product? product}) async {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.price.toString() : '',
    );
    final stockController = TextEditingController(
      text: product != null ? product.stockQuantity.toString() : '',
    );
    
    String? selectedCategory = product?.category ?? categories.first;
    String? imageUrl = product?.imageUrl;
    File? imageFile;
    
    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (\$)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    try {
                      final price = double.parse(value);
                      if (price <= 0) {
                        return 'Price must be greater than zero';
                      }
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter stock quantity';
                    }
                    try {
                      final stock = int.parse(value);
                      if (stock < 0) {
                        return 'Stock cannot be negative';
                      }
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Product Image:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final pickedImageUrl = await _pickImage();
                          if (pickedImageUrl != null) {
                            setState(() {
                              imageUrl = pickedImageUrl;
                            });
                          }
                        },
                        child: const Text('Select Image'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (imageUrl != null)
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(isEditing ? 'Update' : 'Add'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (imageUrl == null) {
                  _showErrorDialog('Please select an image for the product');
                  return;
                }
                
                Navigator.of(ctx).pop();
                
                // Show loading indicator
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  final newProduct = Product(
                    id: isEditing ? product.id : DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    price: double.parse(priceController.text.trim()),
                    imageUrl: imageUrl ?? '',
                    category: selectedCategory ?? categories.first,
                    stockQuantity: int.parse(stockController.text.trim()),
                  );
                  
                  if (isEditing) {
                    await _updateProduct(newProduct);
                  } else {
                    await _addProduct(newProduct);
                  }
                } catch (e) {
                  setState(() {
                    _isLoading = false;
                  });
                  _showErrorDialog('Error: $e');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewProduct,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onChanged: (value) {
                            _filterProducts(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                          value: _selectedCategory,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _filterProducts('');
                            });
                          },
                          hint: const Text('Select Category'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                          value: sortBy,
                          items: const [
                            DropdownMenuItem(value: 'name', child: Text('Name')),
                            DropdownMenuItem(value: 'price', child: Text('Price')),
                            DropdownMenuItem(value: 'stock', child: Text('Stock')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                sortBy = value;
                                _sortProducts();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              products.isEmpty
                                  ? 'No products added yet. Add your first product!'
                                  : 'No products match your search criteria.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (ctx, index) {
                              final product = filteredProducts[index];
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10),
                                          ),
                                          child: product.imageUrl.startsWith('http')
                                              ? Image.network(
                                                  product.imageUrl,
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: 120,
                                                      width: double.infinity,
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons.image_not_supported, size: 50),
                                                    );
                                                  },
                                                )
                                              : Image.memory(
                                                  Uint8List.fromList(base64Decode(product.imageUrl.substring(23)).cast<int>()),
                                                  height: 120,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: 120,
                                                      width: double.infinity,
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons.image_not_supported, size: 50),
                                                    );
                                                  },
                                                ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '\$${product.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product.description,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.category, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                product.category,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Stock: ${product.stockQuantity}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: product.stockQuantity > 10
                                                      ? Colors.green
                                                      : product.stockQuantity > 0
                                                          ? Colors.orange
                                                          : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _editProduct(product),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                          onPressed: () => _showDeleteConfirmation(product.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}