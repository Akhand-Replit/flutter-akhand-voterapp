import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Enum to represent the current status of data fetching
enum Status { Uninitialized, Authenticating, Authenticated, Unauthenticated, Fetching, Fetched, Error, Uploading }

class AppProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Authentication State
  Status _authStatus = Status.Uninitialized;
  String? _token;

  // Data State for the Event Collector Page
  Status _eventDataStatus = Status.Uninitialized;
  List<Event> _events = [];
  Event? _selectedEvent;
  List<Record> _searchedRecords = [];
  List<Record> _connectedRecords = [];
  Set<int> _connectedRecordIds = {};
  String _errorMessage = '';

  // State for Add/Edit Record
  Status _batchListStatus = Status.Uninitialized;
  Status _recordMutationStatus = Status.Uninitialized; // For both add and update
  List<Batch> _batchesForAdd = [];

  // State for Family Management
  Status _familyStatus = Status.Uninitialized;
  List<FamilyRelationship> _familyMembers = [];

  // Getters
  Status get authStatus => _authStatus;
  Status get eventDataStatus => _eventDataStatus;
  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  List<Record> get searchedRecords => _searchedRecords;
  List<Record> get connectedRecords => _connectedRecords;
  Set<int> get connectedRecordIds => _connectedRecordIds;
  String get errorMessage => _errorMessage;
  Status get batchListStatus => _batchListStatus;
  Status get recordMutationStatus => _recordMutationStatus;
  List<Batch> get batchesForAdd => _batchesForAdd;
  Status get familyStatus => _familyStatus;
  List<FamilyRelationship> get familyMembers => _familyMembers;

  AppProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    if (_token != null) {
      _authStatus = Status.Authenticated;
    } else {
      _authStatus = Status.Unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _authStatus = Status.Authenticating;
    notifyListeners();
    try {
      final token = await _apiService.login(username, password);
      if (token != null) {
        _token = token;
        _authStatus = Status.Authenticated;
        notifyListeners();
        return true;
      } else {
        _authStatus = Status.Unauthenticated;
        _errorMessage = 'Login Failed. Please check your credentials.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authStatus = Status.Unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    _token = null;
    _authStatus = Status.Unauthenticated;
    _resetState();
    notifyListeners();
  }
  
  void _resetState() {
      _eventDataStatus = Status.Uninitialized;
      _events = [];
      _selectedEvent = null;
      _searchedRecords = [];
      _connectedRecords = [];
      _connectedRecordIds = {};
      _errorMessage = '';
      _batchListStatus = Status.Uninitialized;
      _recordMutationStatus = Status.Uninitialized;
      _batchesForAdd = [];
      _familyStatus = Status.Uninitialized;
      _familyMembers = [];
  }

  Future<void> fetchEvents() async {
    _eventDataStatus = Status.Fetching;
    notifyListeners();
    try {
      _events = await _apiService.getEvents();
      _eventDataStatus = Status.Fetched;
    } catch (e) {
      _eventDataStatus = Status.Error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void selectEvent(Event? event) {
    _selectedEvent = event;
    _searchedRecords = [];
    if (event != null) {
      fetchConnectedRecords(event.id);
    } else {
      _connectedRecords = [];
      _connectedRecordIds = {};
    }
    notifyListeners();
  }

  Future<void> fetchConnectedRecords(int eventId) async {
    _eventDataStatus = Status.Fetching;
    notifyListeners();
    try {
      final data = await _apiService.getRecordsForEvent(eventId);
      _connectedRecords = data['records'];
      _connectedRecordIds = _connectedRecords.map((r) => r.id).toSet();
      _eventDataStatus = Status.Fetched;
    } catch (e) {
      _eventDataStatus = Status.Error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> searchVoterRecords(Map<String, String> params) async {
    _eventDataStatus = Status.Fetching;
    _searchedRecords = [];
    notifyListeners();
    try {
      final data = await _apiService.searchRecords(params);
      _searchedRecords = data['records'];
      _eventDataStatus = Status.Fetched;
    } catch (e) {
      _eventDataStatus = Status.Error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void clearSearchResults() {
    _searchedRecords = [];
    notifyListeners();
  }

  Future<void> toggleRecordConnection(Record record) async {
    if (_selectedEvent == null) return;

    final isConnected = _connectedRecordIds.contains(record.id);
    
    final recordDetailsData = await _apiService.searchRecords({'id': record.id.toString()});
    final fullRecord = recordDetailsData['records'].first;

    final allEvents = await _apiService.getEvents();
    
    List<int> currentEventIds = List<int>.from(fullRecord.eventNames.map((name) {
        final event = allEvents.firstWhere((e) => e.name == name, orElse: () => Event(id: -1, name: ''));
        return event.id;
    }).where((id) => id != -1));

    if (isConnected) {
      currentEventIds.remove(_selectedEvent!.id);
    } else {
      if (!currentEventIds.contains(_selectedEvent!.id)) {
        currentEventIds.add(_selectedEvent!.id);
      }
    }

    try {
      await _apiService.assignEventsToRecord(record.id, currentEventIds);
      await fetchConnectedRecords(_selectedEvent!.id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchBatchesForAdd() async {
    _batchListStatus = Status.Fetching;
    notifyListeners();
    try {
      _batchesForAdd = await _apiService.getBatches();
      _batchListStatus = Status.Fetched;
    } catch (e) {
      _batchListStatus = Status.Error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<Record?> addNewRecord(Map<String, String> recordData) async {
    _recordMutationStatus = Status.Fetching;
    notifyListeners();
    try {
      final newRecord = await _apiService.addRecord(recordData);
      _recordMutationStatus = Status.Fetched;
      notifyListeners();
      if (_searchedRecords.isNotEmpty) {
        _searchedRecords = [];
      }
      return newRecord;
    } catch (e) {
      _recordMutationStatus = Status.Error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateVoterRecord(int recordId, Map<String, dynamic> data) async {
    _recordMutationStatus = Status.Fetching;
    notifyListeners();
    try {
      await _apiService.updateRecord(recordId, data);
      _recordMutationStatus = Status.Fetched;
      if (_selectedEvent != null) {
        fetchConnectedRecords(_selectedEvent!.id);
      }
      _searchedRecords = [];
      notifyListeners();
      return true;
    } catch (e) {
      _recordMutationStatus = Status.Error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Handles the entire image upload flow and returns the URL.
  Future<String?> uploadImage(XFile image) async {
    _recordMutationStatus = Status.Uploading;
    _errorMessage = '';
    notifyListeners();

    try {
      final imageUrl = await _apiService.uploadImageToImgBB(image);
      if (imageUrl == null) {
        throw Exception('Failed to get image URL from upload service.');
      }
      
      _recordMutationStatus = Status.Fetched;
      notifyListeners();
      return imageUrl;

    } catch (e) {
      _recordMutationStatus = Status.Error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchFamilyMembers(int personId) async {
    _familyStatus = Status.Fetching;
    notifyListeners();
    try {
      _familyMembers = await _apiService.getFamilyMembers(personId);
      _familyStatus = Status.Fetched;
    } catch (e) {
      _familyStatus = Status.Error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> addFamilyMember(int personId, int relativeId, String relationshipType) async {
    _recordMutationStatus = Status.Fetching;
    notifyListeners();
    try {
      await _apiService.addFamilyMember(personId, relativeId, relationshipType);
      await fetchFamilyMembers(personId); // Refresh the list
      _recordMutationStatus = Status.Fetched;
      notifyListeners();
      return true;
    } catch (e) {
      _recordMutationStatus = Status.Error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFamilyMember(int relationshipId, int personId) async {
    try {
      await _apiService.removeFamilyMember(relationshipId);
      await fetchFamilyMembers(personId); // Refresh the list
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
