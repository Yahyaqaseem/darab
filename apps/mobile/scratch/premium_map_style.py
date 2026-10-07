import json
import re

style_path = r'C:\Users\Yahya\Downloads\darab\apps\mobile\assets\map\darb_style.json'

with open(style_path, 'r', encoding='utf-8') as f:
    style = json.load(f)

# Ultra-Premium Dark Navigation Palette
BG_COLOR = "#0A0F1A" # Deep space blue-black
WATER_COLOR = "#121A2F" # Slightly lighter space blue
PARK_COLOR = "#0D1A16" # Very dark subtle green
BUILDING_COLOR = "#111827" # Gray-900

# Roads
MOTORWAY_INNER = "#FFD166" # Vibrant Golden Yellow
MOTORWAY_CASING = "#B25E00" # Deep Orange/Brown casing
PRIMARY_INNER = "#F8FAFC" # Crisp white
PRIMARY_CASING = "#334155" # Slate-700
SECONDARY_INNER = "#94A3B8" # Slate-400
SECONDARY_CASING = "#1E293B" # Slate-800
LOCAL_LINE = "#334155" # Slate-700
MINOR_LINE = "#1E293B" # Slate-800

def update_paint(layer, key, value):
    if "paint" not in layer:
        layer["paint"] = {}
    layer["paint"][key] = value

for layer in style.get('layers', []):
    type_ = layer.get('type')
    id_ = layer.get('id', '').lower()
    source_layer = layer.get('source-layer', '')

    # Background
    if type_ == 'background':
        update_paint(layer, 'background-color', BG_COLOR)

    # Water
    elif source_layer == 'water':
        if type_ == 'fill':
            update_paint(layer, 'fill-color', WATER_COLOR)
            update_paint(layer, 'fill-opacity', 1.0)
        elif type_ == 'line':
            update_paint(layer, 'line-color', WATER_COLOR)

    # Parks / Landcover
    elif source_layer in ['landcover', 'park', 'landuse']:
        if type_ == 'fill':
            if 'wood' in id_ or 'park' in id_ or 'grass' in id_:
                update_paint(layer, 'fill-color', PARK_COLOR)
            else:
                update_paint(layer, 'fill-color', "#0F1626") # generic landuse
            update_paint(layer, 'fill-opacity', 1.0)

    # Buildings (3D)
    elif source_layer == 'building':
        if type_ == 'fill-extrusion':
            update_paint(layer, 'fill-extrusion-color', BUILDING_COLOR)
            update_paint(layer, 'fill-extrusion-opacity', 0.95) # Make them solid and premium
            # Remove any left-over 2D properties
            layer['paint'].pop('fill-color', None)
            layer['paint'].pop('fill-outline-color', None)
        elif type_ == 'fill':
            update_paint(layer, 'fill-color', BUILDING_COLOR)
            update_paint(layer, 'fill-opacity', 0.95)

    # Transportation (Roads)
    elif source_layer == 'transportation':
        is_casing = 'casing' in id_ or 'outline' in id_
        
        if 'motorway' in id_ or 'trunk' in id_ or 'ring' in id_:
            update_paint(layer, 'line-color', MOTORWAY_CASING if is_casing else MOTORWAY_INNER)
        elif 'primary' in id_:
            update_paint(layer, 'line-color', PRIMARY_CASING if is_casing else PRIMARY_INNER)
        elif 'secondary' in id_ or 'tertiary' in id_:
            update_paint(layer, 'line-color', SECONDARY_CASING if is_casing else SECONDARY_INNER)
        elif 'minor' in id_ or 'residential' in id_:
            update_paint(layer, 'line-color', LOCAL_LINE)
        elif 'path' in id_ or 'pedestrian' in id_:
            update_paint(layer, 'line-color', MINOR_LINE)
        else:
            update_paint(layer, 'line-color', MINOR_LINE)

        # Ensure line widths are appropriate
        if 'motorway' in id_ or 'trunk' in id_:
            if not is_casing:
                update_paint(layer, 'line-width', ["interpolate", ["linear"], ["zoom"], 10, 2, 14, 6, 18, 18])
            else:
                update_paint(layer, 'line-width', ["interpolate", ["linear"], ["zoom"], 10, 3, 14, 9, 18, 24])

    # Text / Labels
    elif type_ == 'symbol':
        if 'text-color' in layer.get('paint', {}):
            update_paint(layer, 'text-color', "#F1F5F9") # Crisp text
        if 'text-halo-color' in layer.get('paint', {}):
            update_paint(layer, 'text-halo-color', "#000000") # Pure black halo for contrast
            update_paint(layer, 'text-halo-width', 2.0)
            update_paint(layer, 'text-halo-blur', 1.0)
            
        # Hide minor POIs
        if source_layer == 'poi':
            if 'minzoom' not in layer or layer['minzoom'] < 15:
                layer['minzoom'] = 16

with open(style_path, 'w', encoding='utf-8') as f:
    json.dump(style, f, indent=2, ensure_ascii=False)

print("Premium map style updated successfully!")
