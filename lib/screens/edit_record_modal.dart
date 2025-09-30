import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:voter_app/providers/app_provider.dart';
import 'package:voter_app/services/api_service.dart';
import 'add_family_member_dialog.dart';

class EditRecordModal extends StatefulWidget {
  final Record record;
  const EditRecordModal({Key? key, required this.record}) : super(key: key);

  @override
  _EditRecordModalState createState() => _EditRecordModalState();
}

class _EditRecordModalState extends State<EditRecordModal>
    with SingleTickerProviderStateMixin {
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
  late TextEditingController _photoLinkController; // <-- ADDED

  String? _relationshipStatus;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker(); // <-- ADDED

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // <-- CHANGED to 5

    // Initialize text controllers
    _initializeControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false)
          .fetchFamilyMembers(widget.record.id);
    });
  }

  void _initializeControllers() {
    _phoneController = TextEditingController(text: widget.record.phoneNumber);
    _whatsappController =
        TextEditingController(text: widget.record.whatsappNumber);
    _facebookController = TextEditingController(text: widget.record.facebookLink);
    _occupationDetailsController =
        TextEditingController(text: widget.record.occupationDetails);
    _descriptionController =
        TextEditingController(text: widget.record.description);
    _politicalStatusController =
        TextEditingController(text: widget.record.politicalStatus);
    _instagramController = TextEditingController(text: widget.record.instaLink);
    _tiktokController = TextEditingController(text: widget.record.tiktokLink);
    _youtubeController = TextEditingController(text: widget.record.youtubeLink);
    _photoLinkController =
        TextEditingController(text: widget.record.photoLink); // <-- ADDED
    _relationshipStatus = widget.record.relationshipStatus;
  }

  @override
  void dispose() {
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
    _photoLinkController.dispose(); // <-- ADDED
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
        'photo_link': _photoLinkController.text, // <-- ADDED
      };

      final success =
          await appProvider.updateVoterRecord(widget.record.id, updatedData);

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
                content: Text('Update failed: ${appProvider.errorMessage}'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAddFamilyMemberDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddFamilyMemberDialog(personRecord: widget.record);
      },
    );
  }

  // --- NEW: Method to handle image picking and uploading ---
  Future<void> _pickImage(ImageSource source) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress image slightly
        maxWidth: 800, // Resize image
      );

      if (pickedFile != null) {
        final imageUrl = await appProvider.uploadAndUpdatePhotoLink(pickedFile);

        if (mounted && imageUrl != null) {
          setState(() {
            _photoLinkController.text = imageUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Image uploaded! Click Update to save the new link.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${appProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View/Edit: ${widget.record.naam}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
            Tab(icon: Icon(Icons.contact_phone_outlined), text: 'Contact & Soc'),
            Tab(icon: Icon(Icons.image_outlined), text: 'Photo'), // <-- ADDED
            Tab(icon: Icon(Icons.notes_outlined), text: 'Details'),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Family'),
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
                _buildPhotoTab(), // <-- ADDED
                _buildDetailsTab(),
                _buildFamilyTab(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(builder: (context, provider, child) {
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
      }),
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
        _buildEditableTextField(
            controller: _phoneController,
            label: "Phone Number",
            icon: Icons.phone_outlined),
        _buildEditableTextField(
            controller: _whatsappController,
            label: "WhatsApp Number",
            icon: Icons.message_outlined),
        _buildEditableTextField(
            controller: _facebookController,
            label: "Facebook Link",
            icon: Icons.facebook_outlined),
        _buildEditableTextField(
            controller: _instagramController,
            label: "Instagram Link",
            icon: Icons.photo_camera_outlined),
        _buildEditableTextField(
            controller: _tiktokController,
            label: "TikTok Link",
            icon: Icons.music_note_outlined),
        _buildEditableTextField(
            controller: _youtubeController,
            label: "Youtube Link",
            icon: Icons.video_library_outlined),
      ],
    );
  }
  
  // --- NEW: Photo Tab UI ---
  Widget _buildPhotoTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Current Profile Picture", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    _photoLinkController.text.isNotEmpty
                        ? _photoLinkController.text
                        : 'https://placehold.co/150x150/EFEFEF/AAAAAA?text=No+Image',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 80, color: Colors.grey);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: provider.recordMutationStatus == Status.Uploading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: provider.recordMutationStatus == Status.Uploading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.recordMutationStatus == Status.Uploading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text("Uploading image, please wait..."),
                    ],
                  ),
                ),
              if (provider.recordMutationStatus == Status.Error && provider.errorMessage.contains("upload"))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Upload failed: ${provider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              _buildEditableTextField(
                controller: _photoLinkController,
                label: "Photo URL",
                icon: Icons.link,
              ),
            ],
          ),
        );
      },
    );
  }
  // -------------------------

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

  Widget _buildFamilyTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.familyStatus == Status.Fetching) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.familyStatus == Status.Error) {
          return Center(child: Text('Error: ${provider.errorMessage}'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _showAddFamilyMemberDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Family Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connected Family Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: provider.familyMembers.isEmpty
                    ? const Center(child: Text('No family members added yet.'))
                    : ListView.builder(
                        itemCount: provider.familyMembers.length,
                        itemBuilder: (context, index) {
                          final member = provider.familyMembers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(member.relative.naam),
                              subtitle: Text(
                                  'Relationship: ${member.relationshipType}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Deletion'),
                                      content: Text(
                                          'Are you sure you want to remove ${member.relative.naam}?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Remove')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await provider.removeFamilyMember(
                                        member.id, widget.record.id);
                                  }
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
      },
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
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value != null && value.isNotEmpty ? value : 'N/A',
              style: Theme.of(context).textTheme.titleMedium),
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
