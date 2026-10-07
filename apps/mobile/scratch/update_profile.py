import re

file_path = r'C:\Users\Yahya\Downloads\darab\apps\mobile\lib\features\profile\profile_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildListTile signature
content = content.replace(
    "Widget _buildListTile(DarbIconType icon, String title, String? value, Color textColor, bool isDark) {",
    "Widget _buildListTile(BuildContext context, DarbIconType icon, String title, String? value, Color textColor, bool isDark, {VoidCallback? onTap}) {"
)

# Replace the ListTile inside _buildListTile to have onTap
content = content.replace(
    "return ListTile(",
    "return ListTile(\n      onTap: onTap ?? () {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: Text('سيتم تفعيل هذه الخاصية في التحديث القادم!', style: TextStyle(fontFamily: 'Cairo')),\n            backgroundColor: DarbColors.primaryYellow,\n            behavior: SnackBarBehavior.floating,\n          )\n        );\n      },"
)

# Update _buildListTile calls in the file
content = content.replace("_buildListTile(DarbIconType.history", "_buildListTile(context, DarbIconType.history")
content = content.replace("_buildListTile(DarbIconType.verified", "_buildListTile(context, DarbIconType.verified")
content = content.replace("_buildListTile(DarbIconType.route", "_buildListTile(context, DarbIconType.route")
content = content.replace("_buildListTile(DarbIconType.home", "_buildListTile(context, DarbIconType.home")
content = content.replace("_buildListTile(DarbIconType.work", "_buildListTile(context, DarbIconType.work")
content = content.replace("_buildListTile(DarbIconType.trafficFlow", "_buildListTile(context, DarbIconType.trafficFlow")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Profile Screen updated successfully!")
