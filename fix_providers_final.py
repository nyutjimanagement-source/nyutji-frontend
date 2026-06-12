import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content

    # 1. Clean up ProviderProvider
    content = content.replace('ProviderProvider', 'Provider')

    # 2. Add missing imports
    providers = {
        'authProvider': "import 'package:nyutji_laundry_mobile/providers/auth_provider.dart';",
        'orderProvider': "import 'package:nyutji_laundry_mobile/providers/order_provider.dart';",
        'issueProvider': "import 'package:nyutji_laundry_mobile/providers/issue_provider.dart';",
        'sentimentProvider': "import 'package:nyutji_laundry_mobile/providers/sentiment_provider.dart';",
        'walletProvider': "import 'package:nyutji_laundry_mobile/providers/wallet_provider.dart';",
        'simulasiProvider': "import 'package:nyutji_laundry_mobile/providers/simulasi_provider.dart';"
    }

    for p_var, import_stmt in providers.items():
        if p_var in content and import_stmt not in content:
            # Check for relative import
            rel_import = f"{p_var.replace('Provider', '_provider')}.dart"
            if rel_import not in content:
                # Add import after the first import statement
                match = re.search(r"import\s+'[^']+';\n?", content)
                if match:
                    content = content[:match.end()] + import_stmt + '\n' + content[match.end():]
                else:
                    content = import_stmt + '\n' + content

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

def process_dir(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    process_dir(r'c:\0905NyutjiDev\frontend\lib')
