import re

file_path = r'C:\Users\Yahya\Downloads\darab\apps\mobile\lib\features\profile\profile_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if not present
if "DestinationSearchScreen" not in content:
    content = "import '../search/destination_search_screen.dart';\n" + content

# Fix Home Address
content = re.sub(
    r"_buildListTile\(context,\s*DarbIconType\.home[^)]+\),",
    r"""_buildListTile(context, DarbIconType.home, lang == 'en' ? 'Home Address' : 'عنوان المنزل', null, textColor, isDark, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSearchScreen()));
                        }),""",
    content
)

# Fix Work Address
content = re.sub(
    r"_buildListTile\(context,\s*DarbIconType\.work[^)]+\),",
    r"""_buildListTile(context, DarbIconType.work, lang == 'en' ? 'Work Address' : 'عنوان العمل', null, textColor, isDark, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSearchScreen()));
                        }),""",
    content
)

# Fix Settings
content = re.sub(
    r"_buildListTile\(context,\s*DarbIconType\.trafficFlow,\s*lang[^)]+\),",
    r"""_buildListTile(context, DarbIconType.trafficFlow, lang == 'en' ? 'Navigation Settings' : 'إعدادات الملاحة', null, textColor, isDark),""",
    content
)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Profile Screen updated successfully!")
