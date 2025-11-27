import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/challenge.dart';

class StorageService {
  static const String _userKey = 'zenflow_user';
  static const String _stateKey = 'zenflow_state';
  static const String _historyKey = 'zenflow_history';
  static const String _waterKey = 'zenflow_water';
  static const String _waterDateKey = 'zenflow_water_date';
  
  // User operations
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toJsonString());
  }
  
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString == null) return null;
    return User.fromJsonString(userString);
  }
  
  Future<void> removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
  
  // State operations (for home page flow state)
  Future<void> saveState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state));
  }
  
  Future<Map<String, dynamic>?> getState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_stateKey);
    if (stateString == null) return null;
    return jsonDecode(stateString) as Map<String, dynamic>;
  }
  
  // Challenge history operations
  Future<void> saveHistory(List<ChallengeHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }
  
  Future<List<ChallengeHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey);
    if (historyString == null) return [];
    
    final List<dynamic> historyJson = jsonDecode(historyString) as List;
    return historyJson
        .map((json) => ChallengeHistoryItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  // Water intake operations
  Future<void> saveWaterIntake(int count, String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterKey, count);
    await prefs.setString(_waterDateKey, date);
  }
  
  Future<({int count, String date})> getWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_waterKey) ?? 0;
    final date = prefs.getString(_waterDateKey) ?? '';
    return (count: count, date: date);
  }
}
