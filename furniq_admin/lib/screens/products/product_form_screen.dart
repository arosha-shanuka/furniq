import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/storage_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _materialController;
  late TextEditingController _descriptionController;
  late TextEditingController _materialCareController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _depthController;
  late TextEditingController _skuController;
  late TextEditingController _stockQuantityController;

  String? _selectedCategoryId;
  String _stockStatus = 'inStock';
  bool _isFeatured = false;
  bool _isSaving = false;

  // File upload state
  Uint8List? _mainImageBytes;
  String? _mainImageName;
  Uint8List? _arModelBytes;
  String? _arModelName;
  String? _existingMainImageUrl;
  String? _existingArModelUrl;
  
  List<ProductColor> _availableColors = [];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController =
        TextEditingController(text: p?.price.toStringAsFixed(0) ?? '');
    _materialController = TextEditingController(text: p?.material ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _materialCareController =
        TextEditingController(text: p?.materialAndCareText ?? '');
    _widthController =
        TextEditingController(text: p?.dimensions.widthCm.toStringAsFixed(0) ?? '');
    _heightController =
        TextEditingController(text: p?.dimensions.heightCm.toStringAsFixed(0) ?? '');
    _depthController =
        TextEditingController(text: p?.dimensions.depthCm.toStringAsFixed(0) ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _stockQuantityController =
        TextEditingController(text: p?.stockQuantity.toString() ?? '10');
    _selectedCategoryId = p?.categoryId;
    _stockStatus = p?.stockStatus.name ?? 'inStock';
    _isFeatured = p?.isFeatured ?? false;
    _existingMainImageUrl = p?.mainImageUrl;
    _existingArModelUrl = p?.arModelUrl;
    _availableColors = List<ProductColor>.from(p?.availableColors ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _materialController.dispose();
    _descriptionController.dispose();
    _materialCareController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _skuController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _mainImageBytes = result.files.single.bytes!;
        _mainImageName = result.files.single.name;
      });
    }
  }

  Future<void> _pickArModel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['glb', 'gltf'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _arModelBytes = result.files.single.bytes!;
        _arModelName = result.files.single.name;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Capture provider before any await
    final productProvider = context.read<ProductProvider>();

    try {
      bool success;

      if (isEditing) {
        // ── EDIT: upload files to existing product folder, then update doc ──
        final productId = widget.product!.id;

        String mainImageUrl = _existingMainImageUrl ?? '';
        if (_mainImageBytes != null && _mainImageName != null) {
          final url = await _storageService.uploadProductImage(
              productId, _mainImageBytes!, _mainImageName!);
          if (url != null) mainImageUrl = url;
        }

        String arModelUrl = _existingArModelUrl ?? '';
        if (_arModelBytes != null && _arModelName != null) {
          final url = await _storageService.uploadArModel(
              productId, _arModelBytes!, _arModelName!);
          if (url != null) arModelUrl = url;
        }

        final data = _buildData(mainImageUrl, arModelUrl);
        success = await productProvider.updateProduct(productId, data);
      } else {
        // ── ADD: create Firestore doc first to get real ID, then upload ──
        final baseData = _buildData('', '');
        final newId = await productProvider.addProduct(baseData);
        if (newId == null) {
          success = false;
        } else {
          // Upload images to the real product folder
          String mainImageUrl = '';
          if (_mainImageBytes != null && _mainImageName != null) {
            final url = await _storageService.uploadProductImage(
                newId, _mainImageBytes!, _mainImageName!);
            if (url != null) mainImageUrl = url;
          }

          String arModelUrl = '';
          if (_arModelBytes != null && _arModelName != null) {
            final url = await _storageService.uploadArModel(
                newId, _arModelBytes!, _arModelName!);
            if (url != null) arModelUrl = url;
          }

          // Patch the doc with the actual URLs
          if (mainImageUrl.isNotEmpty || arModelUrl.isNotEmpty) {
            await productProvider.updateProduct(newId, {
              'mainImageUrl': mainImageUrl,
              'arModelUrl': arModelUrl,
            });
          }
          success = true;
        }
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Product updated' : 'Product added'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, dynamic> _buildData(String mainImageUrl, String arModelUrl) {
    // Helper to safely parse numbers that might contain commas or other chars
    double parseDouble(String text) {
      final cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanText) ?? 0.0;
    }

    int parseInt(String text) {
      final cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleanText) ?? 0;
    }

    return {
      'name': _nameController.text.trim(),
      'categoryId': _selectedCategoryId,
      'price': parseDouble(_priceController.text),
      'material': _materialController.text.trim(),
      'description': _descriptionController.text.trim(),
      'materialAndCareText': _materialCareController.text.trim(),
      'stockStatus': _stockStatus,
      'stockQuantity': parseInt(_stockQuantityController.text),
      'sku': _skuController.text.trim(),
      'isFeatured': _isFeatured,
      'mainImageUrl': mainImageUrl,
      'additionalImageUrls': widget.product?.additionalImageUrls ?? [],
      'arModelUrl': arModelUrl,
      'availableColors': _availableColors.map((c) => c.toMap()).toList(),
      'dimensions': {
        'widthCm': parseDouble(_widthController.text),
        'heightCm': parseDouble(_heightController.text),
        'depthCm': parseDouble(_depthController.text),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1810),
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic info card
                  _buildCard(
                    title: 'Basic Information',
                    children: [
                      _buildTextField(_nameController, 'Product Name',
                          required: true),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Consumer<CategoryProvider>(
                              builder: (context, provider, _) {
                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedCategoryId,
                                  decoration: _inputDecoration('Category'),
                                  items: provider.categories.map((c) {
                                    return DropdownMenuItem<String>(
                                        value: c.id, child: Text(c.name));
                                  }).toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedCategoryId = v),
                                  validator: (v) =>
                                      v == null ? 'Select a category' : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(_priceController, 'Price (LKR)',
                                required: true, isNumber: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_materialController, 'Material',
                          required: true),
                      const SizedBox(height: 16),
                      _buildTextField(_descriptionController, 'Description',
                          maxLines: 3, required: true),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _materialCareController, 'Material & Care',
                          maxLines: 2),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dimensions card
                  _buildCard(
                    title: 'Dimensions (cm)',
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField(
                                  _widthController, 'Width',
                                  isNumber: true, required: true)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextField(
                                  _heightController, 'Height',
                                  isNumber: true, required: true)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextField(
                                  _depthController, 'Depth',
                                  isNumber: true, required: true)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Status card
                  _buildCard(
                    title: 'Status',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _stockStatus,
                              decoration: _inputDecoration('Stock Status'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'inStock', child: Text('In Stock')),
                                DropdownMenuItem(
                                    value: 'lowStock',
                                    child: Text('Low Stock')),
                                DropdownMenuItem(
                                    value: 'outOfStock',
                                    child: Text('Out of Stock')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _stockStatus = v ?? 'inStock'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(_stockQuantityController, 'Stock Quantity',
                                isNumber: true, required: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(_skuController, 'SKU (Optional)',
                                required: false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                              Checkbox(
                                value: _isFeatured,
                                activeColor: const Color(0xFF6B4423),
                                onChanged: (v) =>
                                    setState(() => _isFeatured = v ?? false),
                              ),
                              const Text('Featured Product',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Media card
                  _buildCard(
                    title: 'Media',
                    children: [
                      // Main image
                      Row(
                        children: [
                          // Preview
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: _mainImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(_mainImageBytes!,
                                        fit: BoxFit.cover),
                                  )
                                : _existingMainImageUrl != null &&
                                        _existingMainImageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Image.network(
                                            _existingMainImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.image,
                                                    size: 40,
                                                    color: Colors.grey)),
                                      )
                                    : const Icon(Icons.image,
                                        size: 40, color: Colors.grey),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Main Product Image',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                _mainImageName ?? 'No file selected',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _pickMainImage,
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Choose Image'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B4423),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // AR Model
                      Row(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.view_in_ar,
                                  size: 40,
                                  color: _arModelBytes != null ||
                                          (_existingArModelUrl != null &&
                                              _existingArModelUrl!.isNotEmpty)
                                      ? const Color(0xFF6B4423)
                                      : Colors.grey,
                                ),
                                if (_arModelBytes != null || 
                                    (_existingArModelUrl != null && _existingArModelUrl!.isNotEmpty))
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(Icons.check_circle,
                                        color: Colors.green, size: 18),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('3D Model (.glb)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                _arModelName ?? 'No file selected',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _pickArModel,
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Choose Model'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B4423),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Available Colors card
                  _buildCard(
                    title: 'Available Colors',
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._availableColors.map((color) => _buildColorCircle(color)),
                          if (_availableColors.length < 6)
                            InkWell(
                              onTap: _showColorPicker,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[400]!, width: 2),
                                  color: Colors.grey[100],
                                ),
                                child: const Icon(Icons.add, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4423),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              isEditing ? 'Update Product' : 'Add Product',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D1810),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false, int maxLines = 1, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(label),
      validator: required
          ? (v) => v == null || v.isEmpty ? '$label is required' : null
          : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildColorCircle(ProductColor productColor) {
    // Parse hex
    Color color = Colors.black;
    try {
      String hex = productColor.hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      color = Color(int.parse(hex, radix: 16));
    } catch (e) {
      // fallback
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _availableColors.remove(productColor);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 50,
          child: Text(
            productColor.name,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showColorPicker() {
    Color pickerColor = const Color(0xff443a49);
    final colorNameController = TextEditingController();
    final hexController = TextEditingController(text: pickerColor.value.toRadixString(16).substring(2, 8).toUpperCase());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Color'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: colorNameController,
                      decoration: _inputDecoration('Color Name (e.g. Walnut Brown)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: hexController,
                      maxLength: 6,
                      decoration: _inputDecoration('Hex Code (e.g. 443A49)').copyWith(
                        prefixText: '#',
                      ),
                      onChanged: (value) {
                        if (value.length == 6) {
                          try {
                            final newColor = Color(int.parse('FF$value', radix: 16));
                            setStateDialog(() {
                              pickerColor = newColor;
                            });
                          } catch (_) {}
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ColorPicker(
                      pickerColor: pickerColor,
                      onColorChanged: (Color color) {
                        setStateDialog(() {
                          pickerColor = color;
                          hexController.text = color.value.toRadixString(16).substring(2, 8).toUpperCase();
                        });
                      },
                      enableAlpha: false,
                      displayThumbColor: true,
                      showLabel: false,
                      paletteType: PaletteType.hsvWithHue,
                      pickerAreaBorderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Add Color'),
                  onPressed: () {
                    final name = colorNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a color name')),
                      );
                      return;
                    }
                    
                    setState(() {
                      String hex = '#${pickerColor.value.toRadixString(16).substring(2, 8).toUpperCase()}';
                      // Check if color hex already exists
                      if (!_availableColors.any((c) => c.hex == hex)) {
                        _availableColors.add(ProductColor(hex: hex, name: name));
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
}
