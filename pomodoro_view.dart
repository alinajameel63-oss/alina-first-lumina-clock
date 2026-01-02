import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart'; // Added for sound
import '../utils/alarm_provider.dart';

class PomodoroView extends StatefulWidget {
  // NO CONST HERE to prevent main.dart errors
  const PomodoroView({super.key});

  @override
  State<PomodoroView> createState() => _PomodoroViewState();
}

class _PomodoroViewState extends State<PomodoroView> {
  Timer? _timer;
  int _remainingSeconds = 1500; 
  int _initialSeconds = 1500;
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio Player instance

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AlarmProvider>(context, listen: false);
      setState(() {
        _initialSeconds = provider.focusMinutes * 60;
        _remainingSeconds = _initialSeconds;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          // TIME'S UP LOGIC
          _timer?.cancel();
          setState(() => _isRunning = false);
          _triggerFinish(); // Trigger Popup & Sound
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _audioPlayer.stop(); // Stop sound if playing
    setState(() {
      _isRunning = false;
      _remainingSeconds = _initialSeconds; // Snap back to start
    });
  }

  // --- TRIGGER TIME'S UP (Dialog First, Sound Second) ---
  void _triggerFinish() async {
    // 1. Show Dialog IMMEDIATELY
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return NeumorphicAlertDialog(
          title: "TIME'S UP!",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 20),
              Text("Focus session complete.", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            NeumorphicButton(
              onPressed: () {
                _audioPlayer.stop();
                Navigator.of(context).pop();
                _resetTimer(); // Reset UI after closing
              },
              style: const NeumorphicStyle(color: Colors.blueAccent),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    // 2. Play Sound Safely
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/focus.mp3')); // Make sure focus.mp3 exists!
      
      // Fallback if focus.mp3 doesn't exist, try loud.mp3 or catch error
      // Simple Vibration
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  // --- MANUAL INPUT SHEET ---
  void _showDurationInput(BuildContext context) {
    if (_isRunning) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FocusInputSheet(
        initialSeconds: _initialSeconds,
        onSave: (int totalSeconds) {
          Provider.of<AlarmProvider>(context, listen: false).setFocusMinutes((totalSeconds / 60).round());
          setState(() {
            _initialSeconds = totalSeconds;
            _remainingSeconds = _initialSeconds;
          });
        },
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = NeumorphicTheme.defaultTextColor(context);
    double progress = _initialSeconds == 0 ? 0 : 1 - (_remainingSeconds / _initialSeconds);

    return Column(
      children: [
        // --- 1. GLOBAL HEADER SPACING ---
        const SizedBox(height: 60),

        // --- 2. CENTERED TITLE ---
        Text(
          "FOCUS MODE",
          style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: textColor),
        ),

        const SizedBox(height: 50),

        // --- 3. RAISED DIAL (SIZE FIXED to 250) ---
        SizedBox(
          width: 250, // Reduced from 300
          height: 250, // Reduced from 300
          child: Stack(
            alignment: Alignment.center,
            children: [
              Neumorphic(
                style: NeumorphicStyle(
                  depth: 10,
                  intensity: 0.8,
                  boxShape: const NeumorphicBoxShape.circle(),
                  color: NeumorphicTheme.baseColor(context),
                ),
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: CustomPaint(
                    painter: ArcPainter(progress: progress, color: Colors.blueAccent),
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () => _showDurationInput(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: GoogleFonts.lato(fontSize: 45, fontWeight: FontWeight.w900, color: textColor),
                    ),
                    if (!_isRunning)
                      const Text(
                        "Tap to Edit",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 50),

        // --- 4. CONTROLS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset Button
            NeumorphicButton(
              onPressed: _resetTimer,
              style: const NeumorphicStyle(boxShape: NeumorphicBoxShape.circle(), depth: 5),
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.refresh, color: Colors.grey),
            ),
            const SizedBox(width: 30),
            
            // Play/Pause Button
            NeumorphicButton(
              onPressed: _toggleTimer,
              style: NeumorphicStyle(
                boxShape: const NeumorphicBoxShape.circle(),
                depth: 5,
                color: _isRunning ? Colors.orangeAccent.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(30),
              child: Icon(
                _isRunning ? Icons.pause : Icons.play_arrow,
                size: 40,
                color: _isRunning ? Colors.orangeAccent : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- PAINTER ---
class ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  ArcPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 15;
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- INPUT SHEET ---
class FocusInputSheet extends StatefulWidget {
  final int initialSeconds;
  final Function(int) onSave;
  const FocusInputSheet({super.key, required this.initialSeconds, required this.onSave});
  @override
  State<FocusInputSheet> createState() => _FocusInputSheetState();
}

class _FocusInputSheetState extends State<FocusInputSheet> {
  late TextEditingController _h;
  late TextEditingController _m;
  late TextEditingController _s;

  @override
  void initState() {
    super.initState();
    int h = widget.initialSeconds ~/ 3600;
    int m = (widget.initialSeconds % 3600) ~/ 60;
    int s = widget.initialSeconds % 60;
    _h = TextEditingController(text: h.toString().padLeft(2, '0'));
    _m = TextEditingController(text: m.toString().padLeft(2, '0'));
    _s = TextEditingController(text: s.toString().padLeft(2, '0'));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: NeumorphicTheme.baseColor(context), borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("SET DURATION", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_ib(_h, "hr"), const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)), _ib(_m, "min"), const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)), _ib(_s, "sec")]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: NeumorphicButton(
                style: const NeumorphicStyle(color: Colors.blueAccent),
                padding: const EdgeInsets.symmetric(vertical: 15),
                onPressed: () {
                  int total = (int.tryParse(_h.text) ?? 0) * 3600 + (int.tryParse(_m.text) ?? 0) * 60 + (int.tryParse(_s.text) ?? 0);
                  if (total > 0) widget.onSave(total);
                  Navigator.pop(context);
                },
                child: const Center(child: Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ib(TextEditingController c, String l) {
    return Column(children: [
      SizedBox(width: 70, height: 70, child: Neumorphic(style: const NeumorphicStyle(depth: -5), child: Center(child: TextField(controller: c, textAlign: TextAlign.center, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(2)], style: GoogleFonts.lato(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blueAccent), decoration: const InputDecoration(border: InputBorder.none))))),
      const SizedBox(height: 5), Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey))
    ]);
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