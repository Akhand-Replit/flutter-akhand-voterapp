import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Enum to represent the current status of data fetching
enum Status { Uninitialized, Authenticating, Authenticated, Unauthenticated, Fetching, Fetched, Error }

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

  // --- NEW: State for Add Record Page ---
  Status _batchListStatus = Status.Uninitialized;
  Status _addDataStatus = Status.Uninitialized;
  List<Batch> _batchesForAdd = [];


  // Getters to access the state from the UI
  Status get authStatus => _authStatus;
  Status get eventDataStatus => _eventDataStatus;
  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  List<Record> get searchedRecords => _searchedRecords;
  List<Record> get connectedRecords => _connectedRecords;
  Set<int> get connectedRecordIds => _connectedRecordIds;
  String get errorMessage => _errorMessage;

  // --- NEW: Getters for Add Record Page ---
  Status get batchListStatus => _batchListStatus;
  Status get addDataStatus => _addDataStatus;
  List<Batch> get batchesForAdd => _batchesForAdd;

  AppProvider() {
    _checkLoginStatus();
  }

  // --- Authentication Methods ---

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
      // --- NEW: Reset add record state ---
      _batchListStatus = Status.Uninitialized;
      _addDataStatus = Status.Uninitialized;
      _batchesForAdd = [];
  }

  // --- Event Collector Methods ---

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
    _searchedRecords = []; // Clear previous search results
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

  Future<void> toggleRecordConnection(Record record) async {
    if (_selectedEvent == null) return;

    final isConnected = _connectedRecordIds.contains(record.id);
    
    // First, get the record's current list of events to preserve other connections
    final recordDetailsData = await _apiService.searchRecords({'id': record.id.toString()});
    final fullRecord = recordDetailsData['records'].first;

    final allEvents = await _apiService.getEvents();
    
    List<int> currentEventIds = List<int>.from(fullRecord.eventNames.map((name) {
        final event = allEvents.firstWhere((e) => e.name == name, orElse: () => Event(id: -1, name: ''));
        return event.id;
    }).where((id) => id != -1));

    if (isConnected) {
      // Disconnect
      currentEventIds.remove(_selectedEvent!.id);
    } else {
      // Connect
      if (!currentEventIds.contains(_selectedEvent!.id)) {
        currentEventIds.add(_selectedEvent!.id);
      }
    }

    try {
      await _apiService.assignEventsToRecord(record.id, currentEventIds);
      // Refresh the connected records list to show the change
      await fetchConnectedRecords(_selectedEvent!.id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // --- NEW: Add Record Methods ---

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

  Future<bool> addNewRecord(Map<String, String> recordData) async {
    _addDataStatus = Status.Fetching;
    notifyListeners();
    try {
      await _apiService.addRecord(recordData);
      _addDataStatus = Status.Fetched;
      notifyListeners();
      return true;
    } catch (e) {
      _addDataStatus = Status.Error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
