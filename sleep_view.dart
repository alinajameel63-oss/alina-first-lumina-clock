import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/alarm_provider.dart';

class SleepView extends StatefulWidget {
  // No const to avoid main.dart conflicts
  const SleepView({super.key});

  @override
  State<SleepView> createState() => _SleepViewState();
}

class _SleepViewState extends State<SleepView> {
  int _selectedOption = -1; // -1: None, 0: Deep Rest, 1: Suggested

  TimeOfDay _parseTime(String timeStr) {
    try {
      DateTime dt = DateFormat("hh:mm a").parse(timeStr);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      return const TimeOfDay(hour: 7, minute: 0); 
    }
  }

  DateTime _calculateBedtime(int cycles, TimeOfDay wakeTime) {
    final now = DateTime.now();
    DateTime wakeDateTime = DateTime(now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);
    if (wakeDateTime.isBefore(now)) wakeDateTime = wakeDateTime.add(const Duration(days: 1));
    return wakeDateTime.subtract(Duration(minutes: 15 + (cycles * 90)));
  }

  void _showTimeInputSheet(BuildContext context, TimeOfDay current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualTimeInputSheet(
        initialTime: current,
        onSave: (TimeOfDay newTime) {
          Provider.of<AlarmProvider>(context, listen: false).setWakeTime(newTime);
          setState(() => _selectedOption = -1);
        },
      ),
    );
  }

  void _setSmartAlarms(BuildContext context, TimeOfDay wakeTime) {
    if (_selectedOption == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a sleep cycle first!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    int cycles = _selectedOption == 0 ? 6 : 5; 
    DateTime bedtime = _calculateBedtime(cycles, wakeTime);
    DateTime windDown = bedtime.subtract(const Duration(minutes: 15));
    TimeOfDay windDownTime = TimeOfDay.fromDateTime(windDown);

    // Alarm 1: Wake Up
    alarmProvider.addDetailedAlarm(
      time: wakeTime,
      label: "Wake Up (${_selectedOption == 0 ? 'Deep Rest' : 'Suggested'})",
      repeat: [true, true, true, true, true, false, false], 
      sound: "Energetic",
      volume: 1.0,
      vibration: true,
    );

    // Alarm 2: Wind Down
    alarmProvider.addDetailedAlarm(
      time: windDownTime,
      label: "Wind Down / Go to Bed",
      repeat: [true, true, true, true, true, false, false],
      sound: "Relaxing",
      volume: 0.6,
      vibration: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Wake Up & Bedtime alarms set!"),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = NeumorphicTheme.defaultTextColor(context);
    final alarmProvider = Provider.of<AlarmProvider>(context);
    TimeOfDay wakeTime = _parseTime(alarmProvider.wakeTimeStr);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // --- 1. GLOBAL HEADER SPACING ---
            const SizedBox(height: 60), 

            // --- 2. CENTERED TITLE ---
            Text(
              "BEDTIME CALCULATOR", 
              style: GoogleFonts.lato(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1, 
                color: textColor
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),

            // --- 3. WIDE INPUT CARD (RESIZED) 📐 ---
            // Changed from 300x300 to 300x150 to save space
            SizedBox(
              width: 300,
              height: 150, 
              child: NeumorphicButton(
                onPressed: () => _showTimeInputSheet(context, wakeTime),
                style: NeumorphicStyle(
                  depth: 5, 
                  boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)), // Slightly tighter radius
                  color: NeumorphicTheme.baseColor(context),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("I need to wake up at", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 5), // Reduced spacing
                    // Large Blue Time
                    Text(
                      alarmProvider.wakeTimeStr, 
                      style: GoogleFonts.lato(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 5), // Reduced spacing
                    const Text("(Tap to edit)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // --- 4. SELECTION CARDS ---
            Row(
              children: [
                Expanded(
                  child: _buildSelectableCard(
                    context, 
                    index: 0, 
                    time: _calculateBedtime(6, wakeTime), 
                    label: "Deep Rest", 
                    subLabel: "9h sleep"
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildSelectableCard(
                    context, 
                    index: 1, 
                    time: _calculateBedtime(5, wakeTime), 
                    label: "Suggested", 
                    subLabel: "7.5h sleep"
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- 5. ACTION BUTTON (Now Visible!) ---
            SizedBox(
              width: double.infinity,
              child: NeumorphicButton(
                onPressed: () => _setSmartAlarms(context, wakeTime),
                style: NeumorphicStyle(
                  depth: 5, 
                  color: Colors.blueAccent.withOpacity(0.1),
                  boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(40))
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.alarm_add, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      "Set Alarms", 
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blueAccent)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableCard(BuildContext context, {required int index, required DateTime time, required String label, required String subLabel}) {
    bool isSelected = _selectedOption == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: isSelected ? 5 : -5, 
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)), 
          color: isSelected ? Colors.blueAccent : NeumorphicTheme.baseColor(context),
          border: isSelected ? const NeumorphicBorder(color: Colors.blueAccent, width: 2) : const NeumorphicBorder.none(),
        ),
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        child: Column(
          children: [
            Text(
              DateFormat('hh:mm').format(time), 
              style: GoogleFonts.lato(
                fontSize: 26, 
                fontWeight: FontWeight.w900, 
                color: isSelected ? Colors.white : Colors.grey
              )
            ),
            Text(
              DateFormat('a').format(time), 
              style: GoogleFonts.lato(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.white70 : Colors.grey
              )
            ),
            const SizedBox(height: 15),
            Text(
              label, 
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.white : Colors.grey[800]
              )
            ),
            Text(
              subLabel, 
              style: TextStyle(
                fontSize: 12, 
                color: isSelected ? Colors.white70 : Colors.grey
              )
            ),
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE MANUAL INPUT SHEET ---
class ManualTimeInputSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onSave;

  const ManualTimeInputSheet({super.key, required this.initialTime, required this.onSave});

  @override
  State<ManualTimeInputSheet> createState() => _ManualTimeInputSheetState();
}

class _ManualTimeInputSheetState extends State<ManualTimeInputSheet> {
  late TextEditingController _hourController;
  late TextEditingController _minController;
  late String _period;

  @override
  void initState() {
    super.initState();
    int h = widget.initialTime.hour > 12 ? widget.initialTime.hour - 12 : (widget.initialTime.hour == 0 ? 12 : widget.initialTime.hour);
    _period = widget.initialTime.hour >= 12 ? "PM" : "AM";
    _hourController = TextEditingController(text: h.toString().padLeft(2, '0'));
    _minController = TextEditingController(text: widget.initialTime.minute.toString().padLeft(2, '0'));
  }

  void _save() {
    int? h = int.tryParse(_hourController.text);
    int? m = int.tryParse(_minController.text);
    if (h == null || m == null) return;

    int finalH = h;
    if (_period == "PM" && h != 12) finalH += 12;
    if (_period == "AM" && h == 12) finalH = 0;

    widget.onSave(TimeOfDay(hour: finalH, minute: m));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = NeumorphicTheme.baseColor(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("SET WAKE TIME", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
            const SizedBox(height: 30),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInputBox(_hourController),
                const Text(" : ", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                _buildInputBox(_minController),
                const SizedBox(width: 20),
                Column(
                  children: [
                    _periodBtn("AM"),
                    const SizedBox(height: 5),
                    _periodBtn("PM"),
                  ],
                )
              ],
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: NeumorphicButton(
                style: const NeumorphicStyle(color: Colors.blueAccent),
                padding: const EdgeInsets.symmetric(vertical: 15),
                onPressed: _save,
                child: const Center(child: Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Neumorphic(
        style: const NeumorphicStyle(depth: -5),
        child: Center(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [LengthLimitingTextInputFormatter(2)],
            style: GoogleFonts.lato(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  Widget _periodBtn(String txt) {
    bool isSelected = _period == txt;
    return GestureDetector(
      onTap: () => setState(() => _period = txt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(txt, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
      ),
    );
  }
}