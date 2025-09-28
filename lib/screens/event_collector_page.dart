import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voter_app/providers/app_provider.dart';
import 'package:voter_app/services/api_service.dart'; // We need the Record and Event models

class EventCollectorPage extends StatefulWidget {
  const EventCollectorPage({Key? key}) : super(key: key);

  @override
  _EventCollectorPageState createState() => _EventCollectorPageState();
}

class _EventCollectorPageState extends State<EventCollectorPage> {
  // Controllers for the search form
  final _nameController = TextEditingController();
  final _voterNoController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch the list of events as soon as the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _voterNoController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  void _performSearch() {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final params = {
        'naam__icontains': _nameController.text,
        'voter_no': _voterNoController.text,
        'pitar_naam__icontains': _fatherNameController.text,
        'phone_number__icontains': _phoneController.text,
        'thikana__icontains': _addressController.text,
      };
      // Remove empty params before sending
      params.removeWhere((key, value) => value.isEmpty);
      
      if (params.isNotEmpty) {
        appProvider.searchVoterRecords(params);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Data Collector'),
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
              // Event Selection Card
              _buildEventSelectionCard(provider),
              
              // Show Search and Connected lists only if an event is selected
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
            Text('Select an Event', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (provider.eventDataStatus == Status.Fetching && provider.events.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.eventDataStatus == Status.Error)
              Text('Error loading events: ${provider.errorMessage}', style: const TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<Event>(
                value: provider.selectedEvent,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
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
            Text('Search for Records', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _voterNoController, decoration: const InputDecoration(labelText: 'Voter No', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _fatherNameController, decoration: const InputDecoration(labelText: 'Father\'s Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _performSearch, child: const Text('Search'))),
             const SizedBox(height: 16),
            const Divider(),
             const SizedBox(height: 16),
             Text('Search Results', style: Theme.of(context).textTheme.titleMedium),
            _buildRecordList(provider.searchedRecords, provider, 'search'),
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
            Text('Currently Connected Records', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildRecordList(provider.connectedRecords, provider, 'connected'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordList(List<Record> records, AppProvider provider, String listType) {
    if (provider.eventDataStatus == Status.Fetching && listType != 'search') {
      return const Center(child: CircularProgressIndicator());
    }
    if (records.isEmpty) {
      return Center(child: Text('No records found.', style: Theme.of(context).textTheme.bodyMedium));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isConnected = provider.connectedRecordIds.contains(record.id);
        return ListTile(
          title: Text(record.naam),
          subtitle: Text('Voter No: ${record.voterNo ?? 'N/A'}'),
          trailing: ElevatedButton(
            onPressed: () => provider.toggleRecordConnection(record),
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.redAccent : Colors.green,
            ),
            child: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),
        );
      },
    );
  }
}
