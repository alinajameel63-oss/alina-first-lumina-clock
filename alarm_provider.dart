import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  List<Map<String, dynamic>> _alarms = [];
  int _focusMinutes = 25;
  String _wakeTimeStr = "07:00 AM"; // For Sleep View
  bool _isLoaded = false;

  List<Map<String, dynamic>> get alarms => _alarms;
  int get focusMinutes => _focusMinutes;
  String get wakeTimeStr => _wakeTimeStr;
  bool get isLoaded => _isLoaded;

  AlarmProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();

    // 1. Load Alarms (With Crash Prevention)
    String? alarmsJson = _prefs.getString('alarms');
    
    if (alarmsJson != null) {
      try {
        List<dynamic> decoded = jsonDecode(alarmsJson);
        _alarms = decoded.map((e) {
          // STRICTLY CAST MAPS
          final Map<String, dynamic> alarmMap = Map<String, dynamic>.from(e);
          
          // STRICTLY CAST REPEAT LIST (Prevents Red Screen)
          if (alarmMap['repeat'] != null) {
            alarmMap['repeat'] = (alarmMap['repeat'] as List).map((i) => i as bool).toList();
          } else {
            // Default if missing
            alarmMap['repeat'] = [false, false, false, false, false, false, false];
          }
          return alarmMap;
        }).toList();
      } catch (e) {
        debugPrint("Error loading alarms: $e");
        _alarms = []; // Reset if data is corrupt
      }
    } else {
      // Default Startup Alarm
      _alarms = [];
    }

    // 2. Load Misc Settings
    _focusMinutes = _prefs.getInt('focus_minutes') ?? 25;
    _wakeTimeStr = _prefs.getString('wake_time') ?? "07:00 AM";

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveAlarms() async {
    String jsonString = jsonEncode(_alarms);
    await _prefs.setString('alarms', jsonString);
    notifyListeners();
  }

  // --- ALARM ACTIONS ---

  void addDetailedAlarm({
    required TimeOfDay time,
    required String label,
    required List<bool> repeat,
    required String sound,
    required double volume,
    required bool vibration,
    int? editIndex
  }) {
    // Note: We format manually to ensure consistency
    String period = time.hour >= 12 ? "PM" : "AM";
    int hour12 = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    String minuteStr = time.minute.toString().padLeft(2, '0');
    String timeStr = "${hour12.toString().padLeft(2, '0')}:$minuteStr $period";

    Map<String, dynamic> newAlarm = {
      "time": timeStr,
      "label": label.isEmpty ? "Alarm" : label,
      "isActive": true,
      "repeat": repeat,
      "sound": sound,
      "volume": volume,
      "vibration": vibration,
    };

    if (editIndex != null) {
      _alarms[editIndex] = newAlarm;
    } else {
      _alarms.add(newAlarm);
    }
    _saveAlarms();
  }

  void toggleAlarm(int index, bool value) {
    _alarms[index]['isActive'] = value;
    _saveAlarms();
  }

  void deleteAlarm(int index) {
    _alarms.removeAt(index);
    _saveAlarms();
  }

  // --- FOCUS MODE & SLEEP ---

  void setFocusMinutes(int minutes) {
    _focusMinutes = minutes;
    _prefs.setInt('focus_minutes', minutes);
    notifyListeners();
  }

  void setWakeTime(TimeOfDay time) {
    String period = time.hour >= 12 ? "PM" : "AM";
    int hour12 = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    String minuteStr = time.minute.toString().padLeft(2, '0');
    _wakeTimeStr = "${hour12.toString().padLeft(2, '0')}:$minuteStr $period";
    
    _prefs.setString('wake_time', _wakeTimeStr);
    notifyListeners();
  }
}