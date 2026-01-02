import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';

class StopwatchView extends StatefulWidget {
  // Keeping const here is good practice, main.dart handles the rest
  const StopwatchView({super.key});

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

class _StopwatchViewState extends State<StopwatchView> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = "00:00:00";
  final List<String> _laps = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
    } else {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        setState(() {
          _formattedTime = _formatTime(_stopwatch.elapsedMilliseconds);
        });
      });
    }
    setState(() {});
  }

  void _reset() {
    _stopwatch.reset();
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _formattedTime = "00:00:00";
      _laps.clear();
    });
  }

  void _lap() {
    if (_stopwatch.isRunning) {
      setState(() {
        // Insert at top (index 0) so newest lap is first
        _laps.insert(0, _formattedTime);
      });
    }
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String minStr = (minutes % 60).toString().padLeft(2, '0');
    String secStr = (seconds % 60).toString().padLeft(2, '0');
    String hunStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$minStr:$secStr:$hunStr";
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = NeumorphicTheme.defaultTextColor(context);

    return Column(
      children: [
        // --- 1. GLOBAL HEADER SPACING ---
        const SizedBox(height: 60),

        // --- 2. CENTERED TITLE ---
        Text(
          "STOPWATCH",
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: textColor
          ),
        ),

        const SizedBox(height: 40),

        // --- 3. WIDE RECTANGULAR DISPLAY (New Aspect Ratio) ---
        Neumorphic(
          style: NeumorphicStyle(
            depth: 5, // Pop out
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
            color: NeumorphicTheme.baseColor(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SizedBox(
            height: 150, // Reduced height to save space
            width: 300,  // Wide width
            child: Center(
              child: Text(
                _formattedTime,
                style: GoogleFonts.lato(
                  fontSize: 55, // Large readable font
                  fontWeight: FontWeight.w900,
                  color: textColor
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 50),

        // --- 4. CONTROLS (3 Circles) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left: Lap (Small)
            NeumorphicButton(
              onPressed: _lap,
              style: const NeumorphicStyle(boxShape: NeumorphicBoxShape.circle(), depth: 5),
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.flag, color: Colors.orangeAccent, size: 22),
            ),
            
            const SizedBox(width: 30),
            
            // Center: Play/Pause (BIG)
            NeumorphicButton(
              onPressed: _startStop,
              style: NeumorphicStyle(
                boxShape: const NeumorphicBoxShape.circle(),
                depth: 5,
                color: _stopwatch.isRunning ? Colors.redAccent.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(35), // Big Padding
              child: Icon(
                _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                color: _stopwatch.isRunning ? Colors.redAccent : Colors.green,
                size: 40,
              ),
            ),

            const SizedBox(width: 30),
            
            // Right: Reset (Small)
            NeumorphicButton(
              onPressed: _reset,
              style: const NeumorphicStyle(boxShape: NeumorphicBoxShape.circle(), depth: 5),
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.refresh, color: Colors.red, size: 22),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // --- 5. OPEN AIR LAP LIST (No Box) ---
        // Subtle Divider to separate controls from history
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Divider(color: Colors.grey.withOpacity(0.3), thickness: 1),
        ),
        
        const SizedBox(height: 10),

        Expanded(
          child: _laps.isEmpty
              ? Center(
                  child: Text(
                    "No laps recorded",
                    style: GoogleFonts.lato(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _laps.length,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  itemBuilder: (context, index) {
                    // Calculate actual lap number (reversed list)
                    int lapNumber = _laps.length - index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Lap $lapNumber",
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey
                            ),
                          ),
                          Text(
                            _laps[index],
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}