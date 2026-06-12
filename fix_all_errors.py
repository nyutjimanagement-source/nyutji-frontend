import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # 1. Fix ConsumerConsumerState
    content = content.replace('ConsumerConsumerState', 'ConsumerState')
    content = content.replace('ConsumerConsumerWidget', 'ConsumerWidget')
    
    # 2. Fix ConsumerState build method signatures
    # If the class extends ConsumerState, its build method must not have WidgetRef ref.
    # A simple hack: just remove "WidgetRef ref" if we are inside a ConsumerState class.
    # Let's just find "class _XXXXState extends ConsumerState" or "State<XXXX>" and then "Widget build(BuildContext context, WidgetRef ref) {"
    # Actually, simpler: in dart, any class extending ConsumerState should just have "Widget build(BuildContext context)".
    # Wait, what if it's a ConsumerWidget? Then it MUST have "WidgetRef ref".
    # So let's look at the class declaration.
    parts = re.split(r'(class\s+\w+\s+extends\s+(?:ConsumerState|State)<[^>]+>\s*(?:with\s+[\w<>, ]+)?\s*{)', content)
    # parts[0] is before first such class, parts[1] is the class decl, parts[2] is body, etc.
    if len(parts) > 1:
        new_content = parts[0]
        for i in range(1, len(parts), 2):
            class_decl = parts[i]
            class_body = parts[i+1]
            
            # Remove WidgetRef ref from build method in this State class
            class_body = re.sub(r'Widget\s+build\(BuildContext\s+context,\s*WidgetRef\s+ref\)', r'Widget build(BuildContext context)', class_body)
            # also remove it if it was added incorrectly to initState, etc. (just in case)
            
            new_content += class_decl + class_body
        content = new_content
    
    # 3. Fix __BeautyPopupWidgetState
    content = content.replace('__BeautyPopupWidgetState', '_BeautyPopupWidgetState')
    
    # 4. Fix api_service.dart import
    if filepath.endswith('api_service.dart'):
        if 'image_picker.dart' not in content:
            content = content.replace("import 'package:dio/dio.dart';", "import 'package:dio/dio.dart';\nimport 'package:image_picker/image_picker.dart';")
            
    # 5. Fix Consumer syntax issues.
    # My refactor_consumers script created lines like `), \n ; \n })` or `), \n ); \n }`
    # Let's clean them up globally.
    content = re.sub(r'\),\s*;\s*\}\)', r');\n})', content)
    content = re.sub(r'\),\s*\);\s*\}', r');\n})', content)
    content = re.sub(r';\s*\}\)', r';\n})', content)  # Ensure proper formatting

    # Specific fix for customer_home_screen and admin_main_screen missing closing parentheses for Consumer
    # We want to replace `            ;\n})` with `            );\n})` if it follows a comma or something
    # Actually, the simplest way is to manually fix the specific lines we know are broken
    content = re.sub(r'\n\s*;\n\}\)', r'\n);\n})', content)
    content = re.sub(r'\n\s*\);\n\}', r'\n);\n})', content)
    content = re.sub(r'\),\n\s*;\n\}\)', r');\n})', content)

    # 6. Fix `State<XXXX> createState()` to `ConsumerState<XXXX> createState()` if it wasn't caught
    content = re.sub(r'\s+State<(\w+)>\s+createState\(\)', r' ConsumerState<\1> createState()', content)
    
    # 7. authProviderProvider typo
    content = content.replace('authProviderProvider', 'authProvider')

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

import glob
for root, dirs, files in os.walk(r'c:\0905NyutjiDev\frontend\lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
