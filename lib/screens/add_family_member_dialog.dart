import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voter_app/providers/app_provider.dart';
import 'package:voter_app/services/api_service.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  final Record personRecord;
  const AddFamilyMemberDialog({Key? key, required this.personRecord})
      : super(key: key);

  @override
  _AddFamilyMemberDialogState createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends State<AddFamilyMemberDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Family Member'),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Add Existing'),
                Tab(text: 'Add New'),
              ],
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AddExistingMemberTab(personRecord: widget.personRecord),
                  _AddNewMemberTab(personRecord: widget.personRecord),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// --- TAB WIDGET FOR ADDING AN EXISTING MEMBER ---
class _AddExistingMemberTab extends StatefulWidget {
  final Record personRecord;
  const _AddExistingMemberTab({required this.personRecord});

  @override
  __AddExistingMemberTabState createState() => __AddExistingMemberTabState();
}

class __AddExistingMemberTabState extends State<_AddExistingMemberTab> {
  final _searchController = TextEditingController();
  final _relationshipController = TextEditingController();
  Record? _selectedRelative;

  void _performSearch(AppProvider provider) {
    final query = _searchController.text.trim();
    if (query.length > 2) {
      provider.searchVoterRecords({'naam__icontains': query, 'page_size': '5'});
    } else {
      provider.clearSearchResults();
    }
  }

  void _addMember(AppProvider provider) async {
    if (_selectedRelative == null || _relationshipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a person and enter a relationship.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final success = await provider.addFamilyMember(
      widget.personRecord.id,
      _selectedRelative!.id,
      _relationshipController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Family member added!' : 'Failed to add member.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by Name',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => _performSearch(provider),
          ),
          const SizedBox(height: 8),
          if (provider.eventDataStatus == Status.Fetching)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )),
          if (provider.searchedRecords.isNotEmpty)
            SizedBox(
              height: 250, // Increased height for better UI
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.searchedRecords.length,
                itemBuilder: (context, index) {
                  final record = provider.searchedRecords[index];
                  if (record.id == widget.personRecord.id) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          record.photoLink ?? 'https://placehold.co/100x100/EEE/31343C?text=No+Image',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(record.naam,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Father: ${record.pitarNaam ?? 'N/A'}'),
                          Text('Mother: ${record.matarNaam ?? 'N/A'}'),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedRelative = record;
                        });
                        provider.clearSearchResults();
                      },
                    ),
                  );
                },
              ),
            ),
          if (_selectedRelative != null) ...[
            const SizedBox(height: 16),
            Chip(
              label: Text('Selected: ${_selectedRelative!.naam}'),
              onDeleted: () => setState(() => _selectedRelative = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship (e.g., Father, Son)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addMember(provider),
              child: provider.recordMutationStatus == Status.Fetching
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Relationship'),
            ),
          ]
        ],
      ),
    );
  }
}

// --- TAB WIDGET FOR ADDING A NEW MEMBER ---
class _AddNewMemberTab extends StatefulWidget {
  final Record personRecord;
  const _AddNewMemberTab({required this.personRecord});

  @override
  __AddNewMemberTabState createState() => __AddNewMemberTabState();
}

class __AddNewMemberTabState extends State<_AddNewMemberTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _addNewMember(AppProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Build the data map for the new record
    final newRecordData = {
      'naam': _nameController.text.trim(),
      'pitar_naam': _fatherNameController.text.trim(),
      'matar_naam': _motherNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'kromik_no': 'N/A', // Default value
    };
    // Remove empty optional fields
    newRecordData.removeWhere((key, value) => value.isEmpty);


    // First, create the new record
    final newRecord = await provider.addNewRecord(newRecordData);

    if (newRecord != null) {
      // If record creation is successful, add the relationship
      final success = await provider.addFamilyMember(
        widget.personRecord.id,
        newRecord.id,
        _relationshipController.text.trim(),
      );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('New person created and linked!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'New Person\'s Name (Required)'),
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fatherNameController,
              decoration: const InputDecoration(labelText: 'Father\'s Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motherNameController,
              decoration: const InputDecoration(labelText: 'Mother\'s Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _relationshipController,
              decoration: InputDecoration(
                  labelText:
                      'Relationship to ${widget.personRecord.naam} (Required)'),
              validator: (v) => v!.isEmpty ? 'Relationship is required' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _addNewMember(provider),
              child: provider.recordMutationStatus == Status.Fetching
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create and Add Member'),
            )
          ],
        ),
      ),
    );
  }
}
