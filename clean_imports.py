import os

files_to_clean = {
    r'lib\core\utils\status_helper.dart': "import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
    r'lib\core\widgets\nyutji_image_picker.dart': "import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
    r'lib\core\widgets\nyutji_loading_overlay.dart': "import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
    r'lib\providers\auth_provider.dart': "import 'package:nyutji_laundry_mobile/providers/auth_provider.dart';\n",
    r'lib\providers\issue_provider.dart': "import 'package:nyutji_laundry_mobile/providers/issue_provider.dart';\n",
    r'lib\providers\order_provider.dart': "import 'package:nyutji_laundry_mobile/providers/order_provider.dart';\n",
    r'lib\providers\sentiment_provider.dart': "import 'package:nyutji_laundry_mobile/providers/sentiment_provider.dart';\n",
    r'lib\providers\simulasi_provider.dart': "import 'package:nyutji_laundry_mobile/providers/simulasi_provider.dart';\n",
    r'lib\providers\wallet_provider.dart': "import 'package:nyutji_laundry_mobile/providers/wallet_provider.dart';\n"
}

for rel_path, line_to_remove in files_to_clean.items():
    filepath = os.path.join(os.getcwd(), rel_path)
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content.replace(line_to_remove, '')
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Cleaned {rel_path}')
