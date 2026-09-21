import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared_widgets/driver_safe_button.dart';

class UpdateFuelSheet extends StatefulWidget {
  final FuelStationModel station;

  const UpdateFuelSheet({super.key, required this.station});

  static Future<void> show(BuildContext context, FuelStationModel station) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateFuelSheet(station: station),
    );
  }

  @override
  State<UpdateFuelSheet> createState() => _UpdateFuelSheetState();
}

class _UpdateFuelSheetState extends State<UpdateFuelSheet> {
  late TextEditingController _petrolController;
  late TextEditingController _premiumController;
  late bool _isAvailable;
  String _selectedCrowd = 'LOW';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _petrolController = TextEditingController(text: widget.station.petrolPrice.toString());
    _premiumController = TextEditingController(text: widget.station.premiumPrice.toString());
    _isAvailable = widget.station.isPetrolAvailable;
    _selectedCrowd = widget.station.crowdLevel;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final appState = Provider.of<AppState>(context, listen: false);

    await appState.updateFuelStation(
      widget.station.id,
      petrolPrice: int.tryParse(_petrolController.text.trim()),
      premiumPrice: int.tryParse(_premiumController.text.trim()),
      isAvailable: _isAvailable,
      crowdLevel: _selectedCrowd,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'شكراً لك! تم تحديث بيانات الوقود وحصلت على +5 نقاط سمعة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تحديث أسعار وحالة: ${widget.station.nameAr}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 18),

              // Availability Switch
              SwitchListTile(
                title: const Text('هل الوقود متوفر حالياً؟', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                subtitle: Text(
                  _isAvailable ? 'متوفر' : 'غير متوفر / نفد الوقود',
                  style: TextStyle(color: _isAvailable ? AppTheme.successGreen : AppTheme.alertRed, fontFamily: 'Cairo'),
                ),
                value: _isAvailable,
                activeColor: AppTheme.primaryEmerald,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
              const SizedBox(height: 14),

              // Price Inputs
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _petrolController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر البنزين (د.ع)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _premiumController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر المحسن (د.ع)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('مستوى الازدحام على المضخات:', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 8),

              // Crowd Selection
              Row(
                children: [
                  _buildCrowdChip('LOW', '🟢 منخفض'),
                  const SizedBox(width: 8),
                  _buildCrowdChip('MEDIUM', '🟡 متوسط'),
                  const SizedBox(width: 8),
                  _buildCrowdChip('HIGH', '🔴 مزدحم'),
                ],
              ),
              const SizedBox(height: 24),

              DriverSafeButton(
                label: 'حفظ وتحديث المحطة',
                icon: Icons.check,
                onPressed: _isSaving ? () {} : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdChip(String value, String title) {
    final isSelected = _selectedCrowd == value;
    return Expanded(
      child: ChoiceChip(
        label: Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
        onSelected: (selected) {
          if (selected) setState(() => _selectedCrowd = value);
        },
      ),
    );
  }
}
