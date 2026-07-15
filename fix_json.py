import json
import re

with open('./assets/translations/tr.json', 'r', encoding='utf-8') as f:
    text = f.read()

# Lines 318 down to 332 are missing an object key, let's wrap them in "customer_details": { ... }
# Or simply remove the closing bracket at 317 and let them be part of field_sales

lines = text.split('\n')
# We know the issue was introduced around line 316-320 from the output.
# Let's just fix it by string replacement.
fixed_lines = []
for i, line in enumerate(lines):
    if i == 316 and line.strip() == '},':
        # Remove the closing bracket to merge the floating keys into field_sales or next object
        fixed_lines.append('    "customer_extra": {')
    else:
        fixed_lines.append(line)

fixed_text = '\n'.join(fixed_lines)

try:
    json.loads(fixed_text)
    print("Fixed JSON successfully!")
    with open('./assets/translations/tr.json', 'w', encoding='utf-8') as f:
        f.write(fixed_text)
except json.JSONDecodeError as e:
    print(f"Still broken: {e}")
    # Fallback aggressive fix: remove the trailing comma on line 332
    fixed_text = fixed_text.replace('"location_permission_denied_permanently": "Konum izni kalıcı olarak reddedildi, ayarlardan izin vermelisiniz."\n},', '"location_permission_denied_permanently": "Konum izni kalıcı olarak reddedildi, ayarlardan izin vermelisiniz."\n    },\n')
    try:
        json.loads(fixed_text)
        print("Aggressive fix worked.")
        with open('./assets/translations/tr.json', 'w', encoding='utf-8') as f:
            f.write(fixed_text)
    except Exception as e2:
        print(f"Failed completely: {e2}")
