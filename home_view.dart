import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/alarm_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Timer? _timer;
  String _timeString = "";
  String _dayName = "";   // e.g. WEDNESDAY
  String _dateFull = "";  // e.g. 24 DECEMBER
  bool _isAnalog = false; // Toggle state
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // To prevent multiple triggers in the same minute
  String _lastTriggeredTime = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Check time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
      _checkAlarms();
    });
  }

  void _updateTime() {
    if (!mounted) return;
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = DateFormat('hh:mm').format(now);
      _dayName = DateFormat('EEEE').format(now).toUpperCase();
      _dateFull = DateFormat('d MMMM').format(now).toUpperCase();
    });
  }

  // --- THE ALARM ENGINE 🔔 ---
  void _checkAlarms() {
    final now = DateTime.now();
    // Strict comparison format
    final String currentTime = DateFormat('hh:mm a').format(now);
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);

    if (_lastTriggeredTime == currentTime) return;

    for (var i = 0; i < alarmProvider.alarms.length; i++) {
      final alarm = alarmProvider.alarms[i];
      
      // Strict String Match (e.g. "02:08 PM" == "02:08 PM")
      if (alarm['isActive'] == true && alarm['time'] == currentTime) {
        _lastTriggeredTime = currentTime;
        
        // Turn off toggle (Simple logic, can be expanded for repeating)
        alarmProvider.toggleAlarm(i, false);
        
        _triggerAlarm(alarm['label'], alarm['sound'], alarm['vibration']);
        break; 
      }
    }
  }

  void _triggerAlarm(String label, String soundMode, bool vibrate) async {
    String soundFile = "loud.mp3"; 
    if (soundMode == "Relaxing") soundFile = "relaxing.mp3";
    if (soundMode == "Energetic") soundFile = "energetic.mp3";
    if (soundMode == "Focus") soundFile = "focus.mp3";

    try {
      await _audioPlayer.setVolume(1.0); 
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); 
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));

      if (vibrate) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(seconds: 1), () => HapticFeedback.heavyImpact());
        Future.delayed(const Duration(seconds: 2), () => HapticFeedback.heavyImpact());
      }
    } catch (e) {
      debugPrint("Audio Error: $e");
    }

    if (!mounted) return;

    // FORCE DIALOG
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return NeumorphicAlertDialog(
          title: "ALARM",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alarm, size: 60, color: Colors.redAccent),
              const SizedBox(height: 20),
              Text(label, style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            NeumorphicButton(
              onPressed: () {
                _audioPlayer.stop(); 
                Navigator.of(context).pop();
              },
              style: const NeumorphicStyle(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const Text("STOP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showAddAlarmSheet(BuildContext context, {int? editIndex, Map<String, dynamic>? existingAlarm}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlarmSheet(editIndex: editIndex, existingAlarm: existingAlarm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alarmProvider = Provider.of<AlarmProvider>(context);
    Color textColor = NeumorphicTheme.defaultTextColor(context);

    return Column(
      children: [
        const SizedBox(height: 15),
        
        // --- 1. HEADER ROW (Lumina Clock Title) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: [
              Text(
                "Lumina Clock",
                style: GoogleFonts.lato(
                  fontSize: 22, 
                  fontWeight: FontWeight.w900, 
                  color: textColor.withOpacity(0.8),
                  letterSpacing: 1
                ),
              ),
              // Spacer allows Gear Icon (from Main.dart) to sit on the right
            ],
          ),
        ),

        const SizedBox(height: 40), // Breathing room for the Gear Icon
        
        // --- 2. MORPHING CLOCK SECTION ---
        Center(
          child: _isAnalog 
            ? _buildAnalogView(context) 
            : _buildDigitalView(context, textColor),
        ),

        const SizedBox(height: 30),

        // --- 3. ALARM HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MY ALARMS", style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              NeumorphicButton(
                onPressed: () => _showAddAlarmSheet(context),
                style: const NeumorphicStyle(boxShape: NeumorphicBoxShape.circle(), depth: 5, color: Colors.blueAccent),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // --- 4. ALARM LIST ---
        Expanded(
          child: alarmProvider.alarms.isEmpty
              ? Center(child: Text("No Alarms Set", style: GoogleFonts.lato(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: alarmProvider.alarms.length,
                  itemBuilder: (context, index) {
                    return _buildAlarmItem(context, index, alarmProvider.alarms[index], textColor, alarmProvider);
                  },
                ),
        ),
      ],
    );
  }

  // --- MODE A: DIGITAL VIEW (Square Card) ---
  Widget _buildDigitalView(BuildContext context, Color textColor) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Square Card
          Neumorphic(
            style: NeumorphicStyle(
              depth: 5, // Pop out
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(30)),
              color: NeumorphicTheme.baseColor(context),
            ),
            child: Container(
              width: 300,
              height: 300,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Time
                  Text(
                    _timeString,
                    style: GoogleFonts.lato(fontSize: 70, fontWeight: FontWeight.w900, color: textColor),
                  ),
                  const SizedBox(height: 20),
                  // Date (Two Lines)
                  Text(
                    _dayName,
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blueAccent),
                  ),
                  Text(
                    _dateFull,
                    style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          ),
          
          // Toggle Button (Inside Top-Left)
          Positioned(
            top: 20,
            left: 20,
            child: _buildToggleButton(false),
          ),
        ],
      ),
    );
  }

  // --- MODE B: ANALOG VIEW (Engraved, No Card) ---
  Widget _buildAnalogView(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Engraved Clock Body
          Neumorphic(
            style: NeumorphicStyle(
              depth: -10, // Engraved / Deep Dish
              intensity: 0.8,
              boxShape: const NeumorphicBoxShape.circle(),
              color: NeumorphicTheme.baseColor(context),
            ),
            child: SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: AnalogClockPainter(
                  datetime: DateTime.now(),
                  color: Colors.grey, // Hands color
                  accentColor: Colors.blueAccent, // Second hand
                ),
              ),
            ),
          ),
          
          // Toggle Button (Floating Top-Left relative to the 300x300 area)
          Positioned(
            top: 0,
            left: 0,
            child: _buildToggleButton(true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(bool isCurrentlyAnalog) {
    return NeumorphicButton(
      onPressed: () => setState(() => _isAnalog = !_isAnalog),
      style: const NeumorphicStyle(boxShape: NeumorphicBoxShape.circle(), depth: 3),
      padding: const EdgeInsets.all(12),
      child: Icon(
        isCurrentlyAnalog ? Icons.access_time_filled : Icons.access_time, 
        size: 20, 
        color: Colors.grey
      ),
    );
  }

  Widget _buildAlarmItem(BuildContext context, int index, Map<String, dynamic> alarm, Color textColor, AlarmProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onLongPress: () => _deleteDialog(context, provider, index),
        child: Neumorphic(
          style: NeumorphicStyle(depth: 4, boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20))),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm['time'],
                    style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.w900, color: alarm['isActive'] ? Colors.blueAccent : Colors.grey),
                  ),
                  Text(
                    alarm['label'],
                    style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                    onPressed: () => _showAddAlarmSheet(context, editIndex: index, existingAlarm: alarm),
                  ),
                  NeumorphicSwitch(
                    value: alarm['isActive'],
                    height: 28,
                    style: const NeumorphicSwitchStyle(activeTrackColor: Colors.blueAccent),
                    onChanged: (val) => provider.toggleAlarm(index, val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteDialog(BuildContext context, AlarmProvider provider, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeumorphicTheme.baseColor(context),
        title: const Text("Delete Alarm?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              provider.deleteAlarm(index);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- REAL ANALOG CLOCK PAINTER 🎨 ---
class AnalogClockPainter extends CustomPainter {
  final DateTime datetime;
  final Color color;
  final Color accentColor;

  AnalogClockPainter({required this.datetime, required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // 1. Tick Marks (12 Hours)
    final tickPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      double angle = (i * 30) * pi / 180;
      double outerRadius = radius - 10;
      double innerRadius = radius - 20;
      
      // Make 12, 3, 6, 9 distinct
      if (i % 3 == 0) {
        tickPaint.strokeWidth = 4;
        innerRadius = radius - 25;
      } else {
        tickPaint.strokeWidth = 2;
      }

      double x1 = center.dx + outerRadius * cos(angle);
      double y1 = center.dy + outerRadius * sin(angle);
      double x2 = center.dx + innerRadius * cos(angle);
      double y2 = center.dy + innerRadius * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // 2. Hour Hand
    final hourHandLen = radius * 0.5;
    final hourHandX = center.dx + hourHandLen * cos((datetime.hour * 30 + datetime.minute * 0.5) * pi / 180 - pi / 2);
    final hourHandY = center.dy + hourHandLen * sin((datetime.hour * 30 + datetime.minute * 0.5) * pi / 180 - pi / 2);
    canvas.drawLine(center, Offset(hourHandX, hourHandY), Paint()..color = color..strokeWidth = 6..strokeCap = StrokeCap.round);

    // 3. Minute Hand
    final minHandLen = radius * 0.7;
    final minHandX = center.dx + minHandLen * cos((datetime.minute * 6) * pi / 180 - pi / 2);
    final minHandY = center.dy + minHandLen * sin((datetime.minute * 6) * pi / 180 - pi / 2);
    canvas.drawLine(center, Offset(minHandX, minHandY), Paint()..color = color..strokeWidth = 4..strokeCap = StrokeCap.round);

    // 4. Second Hand (Electric Blue)
    final secHandLen = radius * 0.8;
    final secHandX = center.dx + secHandLen * cos((datetime.second * 6) * pi / 180 - pi / 2);
    final secHandY = center.dy + secHandLen * sin((datetime.second * 6) * pi / 180 - pi / 2);
    canvas.drawLine(center, Offset(secHandX, secHandY), Paint()..color = accentColor..strokeWidth = 2..strokeCap = StrokeCap.round);

    // Center Dot
    canvas.drawCircle(center, 5, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// --- ADD ALARM SHEET (MANUAL TYPE) ---
class AddAlarmSheet extends StatefulWidget {
  final int? editIndex;
  final Map<String, dynamic>? existingAlarm;
  const AddAlarmSheet({super.key, this.editIndex, this.existingAlarm});

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  String _period = "AM";
  List<bool> _repeat = [false, false, false, false, false, false, false];
  String _sound = "Relaxing";
  bool _vibration = true;
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    if (widget.existingAlarm != null) {
      final alarm = widget.existingAlarm!;
      _labelController.text = alarm['label'];
      _repeat = List<bool>.from(alarm['repeat']);
      _sound = alarm['sound'];
      _vibration = alarm['vibration'];
      _volume = alarm['volume'];
      
      String time = alarm['time']; 
      _period = time.contains("PM") ? "PM" : "AM";
      List<String> parts = time.split(" ")[0].split(":");
      _hourController.text = parts[0];
      _minController.text = parts[1];
    } else {
      final now = DateTime.now();
      int h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      _period = now.hour >= 12 ? "PM" : "AM";
      _hourController.text = h.toString().padLeft(2, '0');
      _minController.text = now.minute.toString().padLeft(2, '0');
    }
  }

  void _save() {
    int? h = int.tryParse(_hourController.text);
    int? m = int.tryParse(_minController.text);
    if (h == null || m == null) return;

    int finalH = h;
    if (_period == "PM" && h != 12) finalH += 12;
    if (_period == "AM" && h == 12) finalH = 0;

    Provider.of<AlarmProvider>(context, listen: false).addDetailedAlarm(
      time: TimeOfDay(hour: finalH, minute: m),
      label: _labelController.text.isEmpty ? "Alarm" : _labelController.text,
      repeat: _repeat,
      sound: _sound,
      volume: _volume,
      vibration: _vibration,
      editIndex: widget.editIndex,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = NeumorphicTheme.baseColor(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 600, 
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, color: Colors.grey)),
              const SizedBox(height: 20),
              Center(child: Text(widget.editIndex != null ? "EDIT ALARM" : "NEW ALARM", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInputBox(_hourController),
                  const Text(" : ", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  _buildInputBox(_minController),
                  const SizedBox(width: 15),
                  Column(
                    children: [
                      _periodBtn("AM"),
                      const SizedBox(height: 5),
                      _periodBtn("PM"),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),

              Neumorphic(
                style: const NeumorphicStyle(depth: -3),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(controller: _labelController, decoration: const InputDecoration(border: InputBorder.none, hintText: "Label")),
              ),
              const SizedBox(height: 20),

              Text("Repeat", style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
                  return GestureDetector(
                    onTap: () => setState(() => _repeat[i] = !_repeat[i]),
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: _repeat[i] ? -3 : 3,
                        boxShape: const NeumorphicBoxShape.circle(),
                        color: _repeat[i] ? Colors.blueAccent : null,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Text(days[i], style: TextStyle(color: _repeat[i] ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Sound", style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 5),
                        Neumorphic(
                          style: const NeumorphicStyle(depth: -3),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sound,
                              isExpanded: true,
                              dropdownColor: baseColor,
                              items: ["Relaxing", "Energetic", "Focus", "Loud"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) => setState(() => _sound = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      Text("Vibrate", style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 5),
                      NeumorphicSwitch(
                        value: _vibration,
                        height: 30,
                        onChanged: (val) => setState(() => _vibration = val),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),

              Text("Volume", style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.grey)),
              Slider(
                value: _volume,
                activeColor: Colors.blueAccent,
                onChanged: (val) => setState(() => _volume = val),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: _save,
                  style: const NeumorphicStyle(color: Colors.blueAccent),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Center(child: Text("SAVE ALARM", style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Neumorphic(
        style: const NeumorphicStyle(depth: -5),
        child: Center(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [LengthLimitingTextInputFormatter(2)],
            style: GoogleFonts.lato(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(txt, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
      ),
    );
  }
}

class NeumorphicAlertDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  const NeumorphicAlertDialog({super.key, required this.title, required this.content, required this.actions});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NeumorphicTheme.baseColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: TextStyle(color: NeumorphicTheme.defaultTextColor(context))),
      content: content,
      actions: actions,
    );
  }
}