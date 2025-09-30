import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voter_app/providers/app_provider.dart';
import 'package:voter_app/screens/add_record_modal.dart';
import 'package:voter_app/screens/edit_record_modal.dart'; 
import 'package:voter_app/services/api_service.dart';

class EventCollectorPage extends StatefulWidget {
  const EventCollectorPage({Key? key}) : super(key: key);

  @override
  _EventCollectorPageState createState() => _EventCollectorPageState();
}

class _EventCollectorPageState extends State<EventCollectorPage> {
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _professionController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _professionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final params = {
      'naam__icontains': _nameController.text,
      'pitar_naam__icontains': _fatherNameController.text,
      'matar_naam__icontains': _motherNameController.text,
      'pesha__icontains': _professionController.text,
      'thikana__icontains': _addressController.text,
    };
    params.removeWhere((key, value) => value.isEmpty);

    if (params.isNotEmpty) {
      appProvider.searchVoterRecords(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akhand Data - Event Data Collector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildEventSelectionCard(provider),
              if (provider.selectedEvent != null) ...[
                const SizedBox(height: 16),
                _buildSearchCard(provider),
                const SizedBox(height: 16),
                _buildConnectedRecordsCard(provider),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventSelectionCard(AppProvider provider) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select an Event',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (provider.eventDataStatus == Status.Fetching &&
                provider.events.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.eventDataStatus == Status.Error)
              Text('Error loading events: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<Event>(
                value: provider.selectedEvent,
                isExpanded: true,
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('-- Select an Event --'),
                items: provider.events.map((Event event) {
                  return DropdownMenuItem<Event>(
                    value: event,
                    child: Text(event.name),
                  );
                }).toList(),
                onChanged: (Event? newValue) {
                  provider.selectEvent(newValue);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(AppProvider provider) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search for Records',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: _fatherNameController,
                decoration: const InputDecoration(
                    labelText: 'Father\'s Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: _motherNameController,
                decoration: const InputDecoration(
                    labelText: 'Mother\'s Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: _professionController,
                decoration: const InputDecoration(
                    labelText: 'Profession', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _performSearch, child: const Text('Search'))),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text('Search Results',
                style: Theme.of(context).textTheme.titleMedium),
            _buildRecordList(provider.searchedRecords, provider),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddRecordPage(),
                      fullscreenDialog: true,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Add New Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedRecordsCard(AppProvider provider) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Currently Connected Records',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildRecordList(provider.connectedRecords, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList(List<Record> records, AppProvider provider) {
    if (provider.eventDataStatus == Status.Fetching && records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (records.isEmpty) {
      return Center(
          child: Text('No records found.',
              style: Theme.of(context).textTheme.bodyMedium));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = records[index];
        final isConnected = provider.connectedRecordIds.contains(record.id);

        // Split the subtitle data into two logical lines for better display
        final String line1 = 'Father: ${record.pitarNaam ?? 'N/A'} | Mother: ${record.matarNaam ?? 'N/A'}';
        final String line2 = 'Age: ${record.age?.toString() ?? 'N/A'} | Batch: ${record.batchName ?? 'N/A'}';

        return Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            isThreeLine: true, // <-- Ensures enough vertical space for the text and icons
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                record.photoLink ?? 'https://placehold.co/100x100/EEE/31343C?text=No+Image',
                width: 60, // Smaller image for list
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 30, // Smaller icon
                    ),
                  );
                },
              ),
            ),
            title: Text(record.naam,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            // Use Column for subtitle to ensure text wraps and fits within the designated space
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line1),
                Text(line2), // Second line of details
                const SizedBox(height: 4), // Small vertical spacing
              ],
            ),
            trailing: Column( // Column for actions on the right side
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, // Align icons vertically
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, color: Colors.indigo), 
                  tooltip: 'View Details',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditRecordModal(record: record),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    isConnected ? Icons.link_off : Icons.link,
                    color: isConnected ? Colors.redAccent : Colors.green,
                  ),
                  tooltip: isConnected ? 'Disconnect from Event' : 'Connect to Event',
                  onPressed: () => provider.toggleRecordConnection(record),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}