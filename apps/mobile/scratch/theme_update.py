import json
import re

style_path = r'C:\Users\Yahya\Downloads\darab\apps\mobile\assets\map\darb_style.json'

with open(style_path, 'r', encoding='utf-8') as f:
    style = json.load(f)

# Colors
BG_COLOR = "#07101F"
WATER_COLOR = "#0A1931"
PARK_COLOR = "#0F1F19"
BUILDING_COLOR = "#09121F"
HALO_COLOR = "#07101F"

# Road colors
MOTORWAY_FILL = "#C19C45" # Muted gold
MOTORWAY_CASING = "#02050A"
PRIMARY_FILL = "#6A778B" # Muted warm gray/blue
PRIMARY_CASING = "#040A14"
SECONDARY_FILL = "#435269"
LOCAL_FILL = "#263449"
MINOR_FILL = "#172336"

# Helper to update colors in paint
def update_paint(layer, key, value):
    if "paint" not in layer:
        layer["paint"] = {}
    if isinstance(layer["paint"].get(key), dict):
        # Could be an interpolated color array, replace completely
        layer["paint"][key] = value
    else:
        layer["paint"][key] = value

for layer in style.get('layers', []):
    type_ = layer.get('type')
    id_ = layer.get('id', '').lower()
    source_layer = layer.get('source-layer', '')

    # Background
    if type_ == 'background' or id_.startswith('background'):
        update_paint(layer, 'background-color', BG_COLOR)

    # Water
    elif source_layer == 'water':
        if type_ == 'fill':
            update_paint(layer, 'fill-color', WATER_COLOR)
        elif type_ == 'line':
            update_paint(layer, 'line-color', WATER_COLOR)

    # Parks / Landcover
    elif source_layer in ['landcover', 'park']:
        if type_ == 'fill':
            update_paint(layer, 'fill-color', PARK_COLOR)
            update_paint(layer, 'fill-opacity', 0.8)

    # Buildings
    elif source_layer == 'building':
        if type_ == 'fill':
            layer['type'] = 'fill-extrusion'
            update_paint(layer, 'fill-extrusion-color', BUILDING_COLOR)
            update_paint(layer, 'fill-extrusion-opacity', 0.8)
            update_paint(layer, 'fill-extrusion-height', ["get", "render_height"])
            update_paint(layer, 'fill-extrusion-base', ["get", "render_min_height"])
            if 'fill-color' in layer['paint']: del layer['paint']['fill-color']
            if 'fill-opacity' in layer['paint']: del layer['paint']['fill-opacity']
            if 'fill-outline-color' in layer['paint']: del layer['paint']['fill-outline-color']

    # Roads (Transportation)
    elif source_layer == 'transportation':
        # Disable generic roundabout huge yellow rings if they are matched
        
        is_casing = 'casing' in id_ or 'outline' in id_
        
        if 'motorway' in id_ or 'trunk' in id_:
            update_paint(layer, 'line-color', MOTORWAY_CASING if is_casing else MOTORWAY_FILL)
        elif 'primary' in id_:
            update_paint(layer, 'line-color', PRIMARY_CASING if is_casing else PRIMARY_FILL)
        elif 'secondary' in id_ or 'tertiary' in id_:
            update_paint(layer, 'line-color', PRIMARY_CASING if is_casing else SECONDARY_FILL)
        elif 'minor' in id_ or 'service' in id_ or 'residential' in id_:
            update_paint(layer, 'line-color', LOCAL_FILL)
        elif 'path' in id_ or 'pedestrian' in id_:
            update_paint(layer, 'line-color', MINOR_FILL)
        else:
            # fallback for other roads
            update_paint(layer, 'line-color', MINOR_FILL)
            
        # Ensure roundabouts are normal geometry, if there's a specific roundabout styling, map it to normal road class
        # (Already handled by matching class names like primary/secondary above since 'roundabout' isn't usually the primary ID)

    # Labels
    elif type_ == 'symbol':
        # Text styling
        if 'text-color' in layer.get('paint', {}):
            layer['paint']['text-color'] = "#E2E8F0"
        
        # Halo styling
        if 'text-halo-color' in layer.get('paint', {}):
            layer['paint']['text-halo-color'] = HALO_COLOR
            layer['paint']['text-halo-width'] = 1.5
            
        # Adjust zoom levels for labels
        if source_layer == 'poi':
            layer['minzoom'] = 15 # Hide POIs at low zoom
        elif source_layer == 'transportation_name':
            if 'minor' in id_ or 'local' in id_:
                layer['minzoom'] = 15
            elif 'secondary' in id_:
                layer['minzoom'] = 13.5
            elif 'primary' in id_:
                layer['minzoom'] = 12
                
        # Fix Kurdish/Arabic RTL / Localized text
        if 'layout' in layer and 'text-field' in layer['layout']:
            # Example text field: "{name:latin} {name:nonlatin}"
            # Let's enforce local name (Arabic/Kurdish) first
            layer['layout']['text-field'] = "{name}" # Local name first

with open(style_path, 'w', encoding='utf-8') as f:
    json.dump(style, f, indent=2, ensure_ascii=False)

print("Map style updated successfully!")
