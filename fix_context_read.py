import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content

    def replacer(m, is_read):
        t = m.group(1)
        var_name = t[0].lower() + t[1:] + 'Provider'
        if var_name == 'nyutjiAuthProvider': var_name = 'authProvider'
        method = 'read' if is_read else 'watch'
        return f'ref.{method}({var_name})'

    # Replace context.read<T>()
    content = re.sub(r'context\.read\s*<\s*([a-zA-Z0-9_]+)\s*>\s*\(\)', lambda m: replacer(m, True), content)
    
    # Replace context.watch<T>()
    content = re.sub(r'context\.watch\s*<\s*([a-zA-Z0-9_]+)\s*>\s*\(\)', lambda m: replacer(m, False), content)

    # Missing imports check
    providers = {
        'authProvider': "import 'package:nyutji_laundry_mobile/providers/auth_provider.dart';",
        'orderProvider': "import 'package:nyutji_laundry_mobile/providers/order_provider.dart';",
        'issueProvider': "import 'package:nyutji_laundry_mobile/providers/issue_provider.dart';",
        'sentimentProvider': "import 'package:nyutji_laundry_mobile/providers/sentiment_provider.dart';",
        'walletProvider': "import 'package:nyutji_laundry_mobile/providers/wallet_provider.dart';",
        'simulasiProvider': "import 'package:nyutji_laundry_mobile/providers/simulasi_provider.dart';"
    }

    # If the file uses a provider but doesn't import it, add the import
    # We will just add the absolute import at the top (after other imports)
    for p_var, import_stmt in providers.items():
        if p_var in content and import_stmt not in content:
            # Check if it has relative import
            if f"providers/{p_var.replace('Provider', '_provider')}.dart" not in content:
                # Add import right after package:flutter/material.dart or any flutter import
                if "import 'package:flutter/material.dart';" in content:
                    content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_stmt}")
                elif "import 'package:flutter_riverpod/flutter_riverpod.dart';" in content:
                    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", f"import 'package:flutter_riverpod/flutter_riverpod.dart';\n{import_stmt}")

    # Also, some places might have used `ref.read` in a StatefulWidget that wasn't converted?
    # If a file has `ref.read` or `ref.watch` but doesn't import flutter_riverpod, add it.
    if ('ref.read' in content or 'ref.watch' in content) and 'package:flutter_riverpod/flutter_riverpod.dart' not in content:
        if "import 'package:flutter/material.dart';" in content:
            content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';")

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
