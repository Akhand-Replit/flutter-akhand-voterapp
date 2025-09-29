import 'package:flutter/material.dart';
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
  final _kromikNoController = TextEditingController(); // ADDED
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _professionController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  Batch? _selectedBatch;

  @override
  void initState() {
    super.initState();
    // Fetch batches when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchBatchesForAdd();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kromikNoController.dispose(); // ADDED
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

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Build the data map, only including optional fields if they are not empty.
      final recordData = {
        'naam': _nameController.text,
        'kromik_no': _kromikNoController.text, // ADDED
        'pitar_naam': _fatherNameController.text,
        'matar_naam': _motherNameController.text,
        'thikana': _addressController.text,
        'batch': _selectedBatch!.id.toString(),
      };

      if (_professionController.text.isNotEmpty) {
        recordData['pesha'] = _professionController.text;
      }
      if (_dobController.text.isNotEmpty) {
        recordData['jonmo_tarikh'] = _dobController.text;
      }
      if (_descriptionController.text.isNotEmpty) {
        recordData['description'] = _descriptionController.text;
      }
      if (_phoneController.text.isNotEmpty) {
        recordData['phone_number'] = _phoneController.text;
      }
      if (_whatsappController.text.isNotEmpty) {
        recordData['whatsapp_number'] = _whatsappController.text;
      }

      final success = await appProvider.addNewRecord(recordData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Close the modal on success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add record: ${appProvider.errorMessage}'),
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
                  _buildTextField(
                      controller: _nameController,
                      labelText: "Name",
                      isRequired: true),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: _kromikNoController, // ADDED
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
                    onPressed: provider.addDataStatus == Status.Fetching
                        ? null
                        : _saveRecord,
                    child: provider.addDataStatus == Status.Fetching
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
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

