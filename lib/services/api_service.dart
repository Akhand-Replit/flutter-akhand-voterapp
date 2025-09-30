import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'https://dakhandvoter.akhandapps.com';

  // --- ADD THIS SECTION ---
  // TODO: Replace with your own ImgBB API key from https://api.imgbb.com/
  static const String _imgbbApiKey = 'ec519cb1c1643a46e16f22fe58a256cb';
  static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';
  // -------------------------

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        return token;
      }
    }
    return null;
  }

  // --- ADD THIS NEW METHOD for ImgBB Upload ---
  Future<String?> uploadImageToImgBB(XFile image) async {
    var uri = Uri.parse(_imgbbUploadUrl);
    var request = http.MultipartRequest('POST', uri)
      ..fields['key'] = _imgbbApiKey;

    final fileBytes = await image.readAsBytes();

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      fileBytes,
      filename: image.name,
      contentType: MediaType('image', image.name.split('.').last),
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        throw Exception(
            'Failed to upload image. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
  // ------------------------------------------

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

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
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List results = data['results'];
      return results.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future<List<Batch>> getBatches() async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/batches/'),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List results = data['results'];
      return results.map((e) => Batch.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load batches');
    }
  }

  Future<Record> addRecord(Map<String, String> recordData) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/records/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(recordData),
    );

    if (response.statusCode == 201) { // 201 Created
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Record.fromJson(data);
    } else {
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final errors = (errorData as Map<String, dynamic>).entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('\n');
        throw Exception('Failed to add record: $errors');
      } catch (e) {
         throw Exception('Failed to add record. Status code: ${response.statusCode}');
      }
    }
  }

  Future<Map<String, dynamic>> searchRecords(Map<String, String> params) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

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

  Future<Record> updateRecord(int recordId, Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.patch(
      Uri.parse('$_baseUrl/api/records/$recordId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Record.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update record. Status: ${response.statusCode}');
    }
  }

  // --- NEW: Family Relationship Methods ---

  Future<List<FamilyRelationship>> getFamilyMembers(int personId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/family-relationships/?person_id=$personId'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List results = data['results'];
      return results.map((e) => FamilyRelationship.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load family members');
    }
  }

  Future<void> addFamilyMember(int personId, int relativeId, String relationshipType) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/family-relationships/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'person': personId,
        'relative': relativeId,
        'relationship_type': relationshipType,
      }),
    );

    if (response.statusCode != 201) { // 201 Created
      throw Exception('Failed to add family member.');
    }
  }

  Future<void> removeFamilyMember(int relationshipId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/family-relationships/$relationshipId/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode != 204) { // 204 No Content
      throw Exception('Failed to remove family member.');
    }
  }
}

// --- Data Models ---

class Batch {
  final int id;
  final String name;
  Batch({required this.id, required this.name});
  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(id: json['id'], name: json['name']);
  }
}

class Event {
  final int id;
  final String name;
  Event({required this.id, required this.name});
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(id: json['id'], name: json['name']);
  }
}

class Record {
  final int id;
  final String naam;
  final String? kromikNo;
  final String? voterNo;
  final String? pitarNaam;
  final String? matarNaam;
  final String? pesha;
  final String? occupationDetails;
  final String? jonmoTarikh;
  final String? thikana;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? facebookLink;
  final String? tiktokLink;
  final String? youtubeLink;
  final String? instaLink;
  final String? photoLink;
  final String? description;
  final String? politicalStatus;
  final String? relationshipStatus;
  final String? gender;
  final int? age;
  final String? batchName;
  final List<String> eventNames;

  Record({
    required this.id,
    required this.naam,
    this.kromikNo,
    this.voterNo,
    this.pitarNaam,
    this.matarNaam,
    this.pesha,
    this.occupationDetails,
    this.jonmoTarikh,
    this.thikana,
    this.phoneNumber,
    this.whatsappNumber,
    this.facebookLink,
    this.tiktokLink,
    this.youtubeLink,
    this.instaLink,
    this.photoLink,
    this.description,
    this.politicalStatus,
    this.relationshipStatus,
    this.gender,
    this.age,
    this.batchName,
    required this.eventNames,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'],
      naam: json['naam'] ?? 'N/A',
      kromikNo: json['kromik_no'],
      voterNo: json['voter_no'],
      pitarNaam: json['pitar_naam'],
      matarNaam: json['matar_naam'],
      pesha: json['pesha'],
      occupationDetails: json['occupation_details'],
      jonmoTarikh: json['jonmo_tarikh'],
      thikana: json['thikana'],
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      facebookLink: json['facebook_link'],
      tiktokLink: json['tiktok_link'],
      youtubeLink: json['youtube_link'],
      instaLink: json['insta_link'],
      photoLink: json['photo_link'],
      description: json['description'],
      politicalStatus: json['political_status'],
      relationshipStatus: json['relationship_status'],
      gender: json['gender'],
      age: json['age'],
      batchName: json['batch_name'],
      eventNames: List<String>.from(json['event_names'] ?? []),
    );
  }
}

// --- NEW: Models for Family Relationships ---

class SimpleRecord {
  final int id;
  final String naam;
  final String? voterNo;

  SimpleRecord({required this.id, required this.naam, this.voterNo});

  factory SimpleRecord.fromJson(Map<String, dynamic> json) {
    return SimpleRecord(
      id: json['id'],
      naam: json['naam'] ?? 'N/A',
      voterNo: json['voter_no'],
    );
  }
}

class FamilyRelationship {
  final int id;
  final SimpleRecord relative;
  final String relationshipType;

  FamilyRelationship({
    required this.id,
    required this.relative,
    required this.relationshipType,
  });

  factory FamilyRelationship.fromJson(Map<String, dynamic> json) {
    return FamilyRelationship(
      id: json['id'],
      relative: SimpleRecord.fromJson(json['relative']),
      relationshipType: json['relationship_type'],
    );
  }
}
