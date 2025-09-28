import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // --- IMPORTANT ---
  // Use http://10.0.2.2:8000/ for Android Emulator connecting to a localhost server.
  // For a physical device, replace with your computer's network IP address (e.g., http://192.168.1.10:8000/).
  // For production, replace with your live server's URL.
  static const String _baseUrl = 'https://dakhandvoter.akhandapps.com';

  // Function to handle user login
  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/get-token/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        // Save the token securely
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        return token;
      }
    }
    // If login fails, return null
    return null;
  }

  // Helper function to get the auth token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Function to get a list of all available events
  Future<List<Event>> getEvents() async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/events/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      // The backend response is paginated, so we access the 'results'
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List results = data['results'];
      return results.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  // Function to search for voter records based on provided criteria
  Future<Map<String, dynamic>> searchRecords(Map<String, String> params) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    // Build the query string from the params map
    final uri = Uri.parse('$_baseUrl/api/records/').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      List<Record> records = (data['results'] as List)
          .map((recordJson) => Record.fromJson(recordJson))
          .toList();
      return {'records': records, 'next': data['next'], 'previous': data['previous']};
    } else {
      throw Exception('Failed to search records');
    }
  }
  
    // Function to get records for a specific event
  Future<Map<String, dynamic>> getRecordsForEvent(int eventId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/events/$eventId/records/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
       final data = jsonDecode(utf8.decode(response.bodyBytes));
      List<Record> records = (data['results'] as List)
          .map((recordJson) => Record.fromJson(recordJson))
          .toList();
      return {'records': records, 'next': data['next'], 'previous': data['previous']};
    } else {
      throw Exception('Failed to get records for event');
    }
  }


  // Function to connect or disconnect a record from an event
  Future<void> assignEventsToRecord(int recordId, List<int> eventIds) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/records/$recordId/assign-events/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'event_ids': eventIds}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update event connection.');
    }
  }
}

// --- Data Models ---

// A simple data model for an Event
class Event {
  final int id;
  final String name;

  Event({required this.id, required this.name});

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
    );
  }
}

// A simple data model for a Record
class Record {
  final int id;
  final String naam;
  final String? voterNo;
  final String? pitarNaam;
  final String? matarNaam;
  final int? age;
  final String? batchName;
  final List<String> eventNames;

  Record({
    required this.id,
    required this.naam,
    this.voterNo,
    this.pitarNaam,
    this.matarNaam,
    this.age,
    this.batchName,
    required this.eventNames,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'],
      naam: json['naam'] ?? 'N/A',
      voterNo: json['voter_no'],
      pitarNaam: json['pitar_naam'],
      matarNaam: json['matar_naam'],
      age: json['age'],
      batchName: json['batch_name'],
      eventNames: List<String>.from(json['event_names'] ?? []),
    );
  }
}

