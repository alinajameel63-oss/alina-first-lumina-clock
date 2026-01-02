import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/home_view.dart'; // We will create this next
import 'screens/pomodoro_view.dart';
import 'screens/sleep_view.dart';
import 'screens/stopwatch_view.dart';
import 'utils/theme_provider.dart';
import 'utils/alarm_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return NeumorphicApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumina Clock',
      themeMode: themeProvider.themeMode,
      theme: const NeumorphicThemeData(
        baseColor: Color(0xFFE0E5EC),
        lightSource: LightSource.topLeft,
        depth: 10,
        defaultTextColor: Color(0xFF3E3E3E),
      ),
      darkTheme: const NeumorphicThemeData(
        baseColor: Color(0xFF2E2E2E),
        lightSource: LightSource.topLeft,
        depth: 6,
        defaultTextColor: Color(0xFFFFFFFF),
        // --- FIX: DARK MODE SHADOWS ---
        // Dark grey light-shadow prevents the "White Neon" look
        shadowLightColor: Color(0xFF404040), 
        shadowDarkColor: Color(0xFF151515),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- 4 TABS (No Scrolling Needed) ---
  final List<Widget> _pages = [
    HomeView(),      // Clock + Alarm Dashboard
    PomodoroView(),
    StopwatchView(),
    SleepView(),
  ];

  // --- GLOBAL SETTINGS PANEL ---
  void _showSettingsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        Color textColor = NeumorphicTheme.defaultTextColor(context);
        Color baseColor = NeumorphicTheme.baseColor(context);

        return Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text("SETTINGS", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 30),
              
              // Dark Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Dark Mode", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  NeumorphicSwitch(
                    value: themeProvider.isDarkMode,
                    height: 30,
                    style: const NeumorphicSwitchStyle(activeTrackColor: Colors.blueAccent),
                    onChanged: (val) => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              Divider(color: Colors.grey.withOpacity(0.3)),
              const SizedBox(height: 20),
              
              // Credits
              Text("Lumina Clock", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
              const SizedBox(height: 5),
              Text("Developed by Alina", style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              Text("Semester Project 2025", style: GoogleFonts.lato(fontSize: 14, color: Colors.grey)),
              Text("Version 2.0.0", style: GoogleFonts.lato(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = NeumorphicTheme.defaultTextColor(context);

    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      resizeToAvoidBottomInset: false, // Prevents keyboard squishing
      
      body: SafeArea(
        child: Stack(
          children: [
            // The Main Content (Pages)
            Positioned.fill(
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),

            // --- GLOBAL SETTINGS BUTTON (Top Right) ---
            Positioned(
              top: 10,
              right: 20,
              child: NeumorphicButton(
                onPressed: () => _showSettingsPanel(context), 
                style: const NeumorphicStyle(
                  boxShape: NeumorphicBoxShape.circle(),
                  depth: 5,
                  intensity: 0.8,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.settings, 
                  color: textColor.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Neumorphic(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        style: NeumorphicStyle(
          depth: 10,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(40)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(0, Icons.access_time_filled), // Home
            _buildNavButton(1, Icons.hourglass_bottom),   // Pomodoro
            _buildNavButton(2, Icons.timer),              // Stopwatch
            _buildNavButton(3, Icons.bedtime),            // Sleep
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return NeumorphicButton(
      onPressed: () => setState(() => _selectedIndex = index),
      style: NeumorphicStyle(
        depth: isSelected ? -4 : 4,
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        shape: NeumorphicShape.convex,
        boxShape: const NeumorphicBoxShape.circle(),
      ),
      padding: const EdgeInsets.all(16),
      child: Icon(
        icon,
        color: isSelected ? Colors.blueAccent : Colors.grey,
        size: 26,
      ),
    );
  }
}