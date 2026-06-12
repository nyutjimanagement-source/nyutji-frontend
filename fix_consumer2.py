import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # 1. Fix ProviderProvider
    content = content.replace('ProviderProvider', 'Provider')
    
    # 2. Fix Consumer2<A, B>(builder: (ctx, a, b, child) => ...) OR { ... }
    def replacer_consumer2(m):
        prov1 = m.group(1)
        prov2 = m.group(2)
        ctx = m.group(3)
        var1 = m.group(4)
        var2 = m.group(5)
        child = m.group(6)
        arrow_or_brace = m.group(7)
        
        p1_var = prov1[0].lower() + prov1[1:] + 'Provider'
        if p1_var == 'nyutjiAuthProvider': p1_var = 'authProvider'
        p2_var = prov2[0].lower() + prov2[1:] + 'Provider'
        if p2_var == 'nyutjiAuthProvider': p2_var = 'authProvider'
        
        if arrow_or_brace == '=>':
            # We can't easily parse arrow function body safely with simple regex if there are nested parentheses.
            # But we can try to find the end of the Consumer2 block.
            return f'Consumer(\n      builder: ({ctx}, ref, {child}) {{\n        final {var1} = ref.watch({p1_var});\n        final {var2} = ref.watch({p2_var});\n        return '
        else:
            return f'Consumer(\n      builder: ({ctx}, ref, {child}) {{\n        final {var1} = ref.watch({p1_var});\n        final {var2} = ref.watch({p2_var});\n'

    # Match block
    content = re.sub(r'Consumer2\s*<\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*>\s*\(\s*builder\s*:\s*\(\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*\)\s*(\{)', replacer_consumer2, content)

    # Note: If it's an arrow function =>, we need to convert it. Wait, I will just manually fix the arrow functions if they break.
    
    # Let's also fix the missed Consumer<WalletProvider> in courier_main_screen
    if "Consumer<WalletProvider>(" in content:
        content = re.sub(
            r'Consumer<WalletProvider>\(\s*builder:\s*\(([^,]+),\s*([^,]+),\s*([^\)]+)\)\s*=>\s*(.*?)\s*\)',
            r'Consumer(\n  builder: (\1, ref, \3) {\n    final \2 = ref.watch(walletProvider);\n    return \4;\n  }\n)',
            content,
            flags=re.DOTALL
        )

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
