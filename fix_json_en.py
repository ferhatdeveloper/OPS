import json
import re

with open('./assets/translations/en.json', 'r', encoding='utf-8') as f:
    text = f.read()

# Lines 314 down to 329 are floating keys in en.json as well. Let's wrap them carefully.
lines = text.split('\n')
fixed_lines = []
for i, line in enumerate(lines):
    if i == 313 and line.strip() == '},':
        # Remove the closing bracket to merge the floating keys into customer_extra or next object
        fixed_lines.append('    "customer_extra": {')
    else:
        fixed_lines.append(line)

fixed_text = '\n'.join(fixed_lines)

try:
    json.loads(fixed_text)
    print("Fixed JSON successfully!")
    with open('./assets/translations/en.json', 'w', encoding='utf-8') as f:
        f.write(fixed_text)
except json.JSONDecodeError as e:
    print(f"Still broken: {e}")
    # Fallback aggressive fix: remove the trailing comma on line 329
    fixed_text = fixed_text.replace('"location_permission_denied_permanently": "Location permission permanently denied."\n},', '"location_permission_denied_permanently": "Location permission permanently denied."\n    },\n')
    try:
        json.loads(fixed_text)
        print("Aggressive fix worked.")
        with open('./assets/translations/en.json', 'w', encoding='utf-8') as f:
            f.write(fixed_text)
    except Exception as e2:
        print(f"Failed completely: {e2}")
