import re

file_path = r'C:\Users\Yahya\Downloads\darab\apps\mobile\lib\features\navigation\navigation_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import
if "route_simulator.dart" not in content:
    content = content.replace(
        "import '../../core/utils/chevron_generator.dart';",
        "import '../../core/utils/chevron_generator.dart';\nimport '../../core/utils/route_simulator.dart';"
    )

# 2. Add simulator state variable
if "RouteSimulator? _simulator;" not in content:
    content = content.replace(
        "Line? _routeLineHighlight;",
        "Line? _routeLineHighlight;\n  RouteSimulator? _simulator;"
    )

# 3. Handle dispose
if "_simulator?.stop();" not in content:
    content = content.replace(
        "super.dispose();",
        "_simulator?.stop();\n    super.dispose();"
    )

# 4. Add _startSimulation method right after _startDrive
simulation_method = """

  void _startSimulation() {
    _isFollowingUserNotifier.value = true;
    setState(() {
      _isRouteSelecting = false;
    });
    
    final appState = Provider.of<AppState>(context, listen: false);
    final routes = _routesData?['routes'] as List? ?? [];
    if (routes.isNotEmpty) {
      final selected = routes[_selectedRouteIndex.clamp(0, routes.length - 1)];
      appState.selectRoutePreview(selected, widget.destinationName, widget.destLat, widget.destLng);
    }
    
    appState.startNavigation();
    
    _simulator?.stop();
    _simulator = RouteSimulator(
      routePoints: _routePoints,
      speedKmh: 65.0, // Simulate 65 km/h
      onUpdate: (loc, bearing, speed) {
        if (!mounted) return;
        // Mock the user's location via AppState
        appState.userLocationNotifier.value = loc;
        appState.userHeadingNotifier.value = bearing;
        appState.userSpeedNotifier.value = speed;
      },
      onFinish: () {
        if (mounted) _finishTrip();
      },
    );
    
    _simulator!.start();
  }
"""

if "_startSimulation" not in content:
    content = content.replace(
        "  Future<void> _finishTrip() async {",
        simulation_method + "\n  Future<void> _finishTrip() async {"
    )

# 5. Add stop simulator in _finishTrip
if "_simulator?.stop();" not in content: # It's in dispose, so this logic is slightly different
    content = content.replace(
        "appState.stopNavigation();",
        "_simulator?.stop();\n    appState.stopNavigation();"
    )

# 6. Add Simulation Button to UI
ui_replacement = """
                                        if (_isRouteSelecting) ...[
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: DarbColors.primaryYellow,
                                              foregroundColor: DarbColors.textInversePrimary,
                                              elevation: 0,
                                              minimumSize: const Size.fromHeight(54),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            onPressed: _startDrive,
                                            child: const Text('ابدأ الملاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                          ),
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: DarbColors.successGreen,
                                              side: BorderSide(color: DarbColors.successGreen.withOpacity(0.5)),
                                              minimumSize: const Size.fromHeight(48),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            icon: const Icon(Icons.play_circle_fill),
                                            label: const Text('محاكاة القيادة (تجربة)', style: TextStyle(fontWeight: FontWeight.bold)),
                                            onPressed: _startSimulation,
                                          ),
                                        ] else
"""

# The existing UI chunk to replace:
# if (_isRouteSelecting)
#   ElevatedButton(
#     ...
#   )
# else
import re
content = re.sub(
    r"if \(_isRouteSelecting\)\s*ElevatedButton\([\s\S]*?onPressed: _startDrive,[\s\S]*?\)[\s\S]*?else",
    ui_replacement.strip() + " ",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Injected Route Simulator successfully!")
