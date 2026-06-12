import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content

    # 1. Missing revenueSplitProvider
    if filepath.endswith('revenue_split_provider.dart'):
        if 'ChangeNotifierProvider' not in content:
            content += "\nfinal revenueSplitProvider = ChangeNotifierProvider<RevenueSplitProvider>((ref) => RevenueSplitProvider());\n"
    
    # 2. Add import for revenueSplitProvider if missing but used
    if 'revenueSplitProvider' in content and "import 'package:nyutji_laundry_mobile/providers/revenue_split_provider.dart';" not in content and 'revenue_split_provider.dart' not in filepath:
        if "import '../../providers/revenue_split_provider.dart';" not in content and "import '../../../providers/revenue_split_provider.dart';" not in content:
            # simple import addition
            match = re.search(r"import\s+'[^']+';\n?", content)
            if match:
                content = content[:match.end()] + "import 'package:nyutji_laundry_mobile/providers/revenue_split_provider.dart';\n" + content[match.end():]

    # 3. Shadowing errors (e.g. final walletProvider = ref.read(walletProvider);)
    # We will rename the local variable to xxxProv.
    # We need to find `final xxxProvider = ref.read(xxxProvider);` or `ref.watch`
    shadow_match = re.finditer(r'(?:final|var)\s+([a-zA-Z0-9]+Provider)\s*=\s*ref\.(?:read|watch)\(\1\);', content)
    for m in shadow_match:
        var_name = m.group(1)
        new_name = var_name.replace('Provider', 'Prov')
        # Replace the declaration
        content = content.replace(m.group(0), m.group(0).replace(f" {var_name} =", f" {new_name} ="))
        # Replace subsequent usages of var_name as a local variable
        # We only want to replace it when used as a local method caller, like `walletProvider.balance`
        # Using a simple regex to replace \bvar_name\b as long as it's not preceded by ref.read( or ref.watch(
        # Since the scope is usually just the method, replacing all whole words that are not in `ref.read/watch`
        content = re.sub(rf'(?<!ref\.read\()(?<!ref\.watch\()\b{var_name}\b', new_name, content)

    # 4. Uncaught Provider.of calls without assignments
    def replacer_read(m):
        t = m.group(1)
        var_name = t[0].lower() + t[1:] + 'Provider'
        if var_name == 'nyutjiAuthProvider': var_name = 'authProvider'
        return f'ref.read({var_name})'

    content = re.sub(r'Provider\.of<(\w+)>\(context,\s*listen:\s*false\)', replacer_read, content)

    def replacer_watch(m):
        t = m.group(1)
        var_name = t[0].lower() + t[1:] + 'Provider'
        if var_name == 'nyutjiAuthProvider': var_name = 'authProvider'
        return f'ref.watch({var_name})'

    content = re.sub(r'Provider\.of<(\w+)>\(context\)', replacer_watch, content)

    # 5. Fix remaining `context.read<T>()` and `context.watch<T>()` just in case
    # that were missed because they had no `= ` assignment
    content = re.sub(r'context\.read<(\w+)>\(\)', replacer_read, content)
    content = re.sub(r'context\.watch<(\w+)>\(\)', replacer_watch, content)

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
