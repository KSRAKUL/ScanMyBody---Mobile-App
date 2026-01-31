import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserPreferences {
  static final UserPreferences _instance = UserPreferences._internal();
  factory UserPreferences() => _instance;
  UserPreferences._internal();

  String _userName = 'Patient';
  
  String get userName => _userName;
  
  Future<void> loadUserName() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/user_name.txt');
      if (await file.exists()) {
        _userName = await file.readAsString();
      }
    } catch (_) {}
  }
  
  Future<void> setUserName(String name) async {
    _userName = name;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/user_name.txt');
      await file.writeAsString(name);
    } catch (_) {}
  }
}

