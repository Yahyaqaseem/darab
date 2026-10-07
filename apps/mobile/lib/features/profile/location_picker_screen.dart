import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_strings.dart';

class LocationPickerScreen extends StatefulWidget {
  final String title;
  const LocationPickerScreen({super.key, required this.title});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MaplibreMapController? _mapController;
  LatLng? _selectedLocation;
  
  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
  }
  
  void _onMapClick(Point<double> point, LatLng coordinates) {
    setState(() {
      _selectedLocation = coordinates;
    });
    
    // Animate to selection
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(coordinates)
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userPos = appState.userLocationNotifier.value;
    final isDark = appState.isDarkMode;
    final lang = appState.currentLanguage;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF07101F).withOpacity(0.8) : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MaplibreMap(
            onMapCreated: _onMapCreated,
            styleString: 'asset://assets/map/darb_style.json',
            initialCameraPosition: CameraPosition(
              target: LatLng(userPos.latitude, userPos.longitude),
              zoom: 15.0,
            ),
            onMapClick: _onMapClick,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none,
            myLocationRenderMode: MyLocationRenderMode.compass,
          ),
          
          if (_selectedLocation != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60), // Offset to put bottom of house on center
                child: Image.asset('assets/icons/home_marker.png', width: 120, height: 120),
              ),
            ),
            
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF07101F).withOpacity(0.8) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DarbColors.primaryYellow.withOpacity(0.5), width: 2),
                  ),
                  child: Text(
                    widget.title,
                    style: DarbTypography.h3,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          
          if (_selectedLocation != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DarbColors.primaryYellow,
                  foregroundColor: DarbColors.textInversePrimary,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                ),
                onPressed: () {
                  // Usually save to SharedPreferences or Provider
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم الحفظ بنجاح!', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: DarbColors.successGreen,
                    )
                  );
                  Navigator.pop(context);
                },
                child: const Text('حفظ الموقع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
