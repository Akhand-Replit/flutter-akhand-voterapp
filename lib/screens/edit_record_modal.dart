import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voter_app/providers/app_provider.dart';
import 'package:voter_app/services/api_service.dart';

class EditRecordModal extends StatefulWidget {
  final Record record;
  const EditRecordModal({Key? key, required this.record}) : super(key: key);

  @override
  _EditRecordModalState createState() => _EditRecordModalState();
}

// Add SingleTickerProviderStateMixin for TabController
class _EditRecordModalState extends State<EditRecordModal> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _facebookController;
  late TextEditingController _occupationDetailsController;
  late TextEditingController _descriptionController;
  late TextEditingController _politicalStatusController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _youtubeController;

  String? _relationshipStatus;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize controllers with existing record data
    _phoneController = TextEditingController(text: widget.record.phoneNumber);
    _whatsappController = TextEditingController(text: widget.record.whatsappNumber);
    _facebookController = TextEditingController(text: widget.record.facebookLink);
    _occupationDetailsController = TextEditingController(text: widget.record.occupationDetails);
    _descriptionController = TextEditingController(text: widget.record.description);
    _politicalStatusController = TextEditingController(text: widget.record.politicalStatus);
    _instagramController = TextEditingController(text: widget.record.instaLink);
    _tiktokController = TextEditingController(text: widget.record.tiktokLink);
    _youtubeController = TextEditingController(text: widget.record.youtubeLink);
    _relationshipStatus = widget.record.relationshipStatus;
  }

  @override
  void dispose() {
    // Dispose all controllers
    _tabController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    _occupationDetailsController.dispose();
    _descriptionController.dispose();
    _politicalStatusController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      final Map<String, dynamic> updatedData = {
        'phone_number': _phoneController.text,
        'whatsapp_number': _whatsappController.text,
        'facebook_link': _facebookController.text,
        'occupation_details': _occupationDetailsController.text,
        'description': _descriptionController.text,
        'political_status': _politicalStatusController.text,
        'relationship_status': _relationshipStatus,
        'insta_link': _instagramController.text,
        'tiktok_link': _tiktokController.text,
        'youtube_link': _youtubeController.text,
      };

      final success = await appProvider.updateVoterRecord(widget.record.id, updatedData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Record updated successfully!'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Update failed: ${appProvider.errorMessage}'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View/Edit: ${widget.record.naam}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
            Tab(icon: Icon(Icons.contact_phone_outlined), text: 'Contact & Social'),
            Tab(icon: Icon(Icons.notes_outlined), text: 'Details'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildContactSocialTab(),
                _buildDetailsTab(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, child){
          return FloatingActionButton.extended(
            onPressed: provider.recordMutationStatus == Status.Fetching
                ? null
                : _updateRecord,
            label: provider.recordMutationStatus == Status.Fetching
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Update'),
            icon: const Icon(Icons.save),
            backgroundColor: Colors.green,
          );
        }
      ),
    );
  }
  
  // --- Tab Widgets ---

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildReadOnlyField("Name", widget.record.naam),
        _buildReadOnlyField("Kromik No", widget.record.kromikNo),
        _buildReadOnlyField("Voter No", widget.record.voterNo),
        _buildReadOnlyField("Father's Name", widget.record.pitarNaam),
        _buildReadOnlyField("Mother's Name", widget.record.matarNaam),
        _buildReadOnlyField("Date of Birth", widget.record.jonmoTarikh),
        _buildReadOnlyField("Gender", widget.record.gender),
        _buildReadOnlyField("Age", widget.record.age?.toString()),
        _buildReadOnlyField("Address", widget.record.thikana),
        _buildReadOnlyField("Profession", widget.record.pesha),
        _buildReadOnlyField("Batch", widget.record.batchName),
      ],
    );
  }
  
  Widget _buildContactSocialTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildEditableTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_outlined),
        _buildEditableTextField(controller: _whatsappController, label: "WhatsApp Number", icon: Icons.message_outlined),
        _buildEditableTextField(controller: _facebookController, label: "Facebook Link", icon: Icons.facebook_outlined),
        _buildEditableTextField(controller: _instagramController, label: "Instagram Link", icon: Icons.photo_camera_outlined),
        _buildEditableTextField(controller: _tiktokController, label: "TikTok Link", icon: Icons.music_note_outlined),
        _buildEditableTextField(controller: _youtubeController, label: "Youtube Link", icon: Icons.video_library_outlined),
      ],
    );
  }
  
  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
         _buildEditableTextField(
            controller: _occupationDetailsController,
            label: "Occupation Details",
            icon: Icons.work_outline,
            maxLines: 3),
        _buildEditableTextField(
            controller: _descriptionController,
            label: "Description",
            icon: Icons.description_outlined,
            maxLines: 3),
        _buildEditableTextField(
            controller: _politicalStatusController,
            label: "Political Status",
            icon: Icons.flag_outlined,
            maxLines: 3),
        _buildRelationshipDropdown(),
      ],
    );
  }


  // --- Reusable Field Widgets ---

  Widget _buildReadOnlyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value != null && value.isNotEmpty ? value : 'N/A', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRelationshipDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _relationshipStatus,
        decoration: const InputDecoration(
          labelText: 'Relationship Status',
          prefixIcon: Icon(Icons.people_outline),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items: ['Regular', 'Friend', 'Enemy', 'Connected']
            .map((label) => DropdownMenuItem(
                  child: Text(label),
                  value: label,
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _relationshipStatus = value;
          });
        },
      ),
    );
  }
}

