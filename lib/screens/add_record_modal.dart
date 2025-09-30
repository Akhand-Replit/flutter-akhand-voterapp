import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({Key? key}) : super(key: key);

  @override
  _AddRecordPageState createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _kromikNoController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _professionController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  Batch? _selectedBatch;

  // New state variables for image handling
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchBatchesForAdd();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kromikNoController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _professionController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  /// Handles picking an image from the gallery or camera.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles the save logic including image upload.
  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      String? photoUrl;

      // 1. Upload image if one is selected
      if (_imageFile != null) {
        photoUrl = await appProvider.uploadImage(_imageFile!);
        if (photoUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image upload failed: ${appProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
          return; // Stop if upload fails
        }
      }

      // 2. Build the data map for the new record
      final recordData = {
        'naam': _nameController.text,
        'kromik_no': _kromikNoController.text,
        'pitar_naam': _fatherNameController.text,
        'matar_naam': _motherNameController.text,
        'thikana': _addressController.text,
        'batch': _selectedBatch!.id.toString(),
      };

      // Add optional fields if they are not empty
      if (_professionController.text.isNotEmpty)
        recordData['pesha'] = _professionController.text;
      if (_dobController.text.isNotEmpty)
        recordData['jonmo_tarikh'] = _dobController.text;
      if (_descriptionController.text.isNotEmpty)
        recordData['description'] = _descriptionController.text;
      if (_phoneController.text.isNotEmpty)
        recordData['phone_number'] = _phoneController.text;
      if (_whatsappController.text.isNotEmpty)
        recordData['whatsapp_number'] = _whatsappController.text;
      if (photoUrl != null) recordData['photo_link'] = photoUrl;

      // 3. Add the new record
      final newRecord = await appProvider.addNewRecord(recordData);

      if (mounted) {
        if (newRecord != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to add record: ${appProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Record'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildImagePicker(provider), // New image picker UI
                  const SizedBox(height: 24),
                  _buildTextField(
                      controller: _nameController,
                      labelText: "Name",
                      isRequired: true),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _kromikNoController,
                      labelText: "Kromik No (Serial)",
                      isRequired: true),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _fatherNameController,
                      labelText: "Father's Name",
                      isRequired: true),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _motherNameController,
                      labelText: "Mother's Name",
                      isRequired: true),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _addressController,
                      labelText: "Address",
                      isRequired: true),
                  const SizedBox(height: 16),
                  _buildBatchDropdown(provider),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _professionController,
                      labelText: "Profession"),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _dobController,
                      labelText: "Date of Birth (e.g., 10/05/1990)"),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _phoneController,
                      labelText: "Phone Number",
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _whatsappController,
                      labelText: "WhatsApp Number",
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _descriptionController,
                      labelText: "Description",
                      maxLines: 3),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: provider.recordMutationStatus == Status.Fetching ||
                            provider.recordMutationStatus == Status.Uploading
                        ? null
                        : _saveRecord,
                    child: provider.recordMutationStatus == Status.Fetching
                        ? const Text('Saving Record...')
                        : provider.recordMutationStatus == Status.Uploading
                            ? const Text('Uploading Image...')
                            : const Text('Save Record'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the UI for picking and previewing an image.
  Widget _buildImagePicker(AppProvider provider) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: _imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: kIsWeb
                      ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                      : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                )
              : const Center(
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        if (provider.recordMutationStatus == Status.Uploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text("Uploading, please wait..."),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: provider.recordMutationStatus == Status.Uploading
                  ? null
                  : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Camera'),
            ),
            ElevatedButton.icon(
              onPressed: provider.recordMutationStatus == Status.Uploading
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' (Required)' : ''),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter the $labelText';
        }
        return null;
      },
    );
  }

  Widget _buildBatchDropdown(AppProvider provider) {
    if (provider.batchListStatus == Status.Fetching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.batchListStatus == Status.Error) {
      return Text("Error loading batches: ${provider.errorMessage}",
          style: const TextStyle(color: Colors.red));
    }
    return DropdownButtonFormField<Batch>(
      value: _selectedBatch,
      decoration: const InputDecoration(
        labelText: 'Select a Batch (Required)',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      isExpanded: true,
      hint: const Text('Select a Batch'),
      items: provider.batchesForAdd.map((Batch batch) {
        return DropdownMenuItem<Batch>(
          value: batch,
          child: Text(batch.name),
        );
      }).toList(),
      onChanged: (Batch? newValue) {
        setState(() {
          _selectedBatch = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a batch';
        }
        return null;
      },
    );
  }
}

