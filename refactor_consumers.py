import os
import re

def to_camel_case(s):
    return s[0].lower() + s[1:]

def fix_consumers(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content
    
    # Regex to find Consumer<ProviderType>(builder: (context, providerVar, child) { ... })
    # We will use a more robust regex that finds Consumer<T>(builder: (a,b,c) { ... })
    
    pattern = re.compile(r'Consumer\s*<\s*([a-zA-Z0-9_]+)\s*>\s*\(\s*builder\s*:\s*\(\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*\)\s*\{([^}]*)\}\s*\)', re.DOTALL)
    
    def repl(m):
        provider_type = m.group(1)
        ctx = m.group(2)
        val = m.group(3)
        child = m.group(4)
        body = m.group(5).strip()
        
        provider_var = provider_type[0].lower() + provider_type[1:] + 'Provider'
        
        if body.startswith('return'):
            # It's a simple return statement
            return f"Consumer(builder: ({ctx}, ref, {child}) {{\nfinal {val} = ref.watch({provider_var});\n {body}\n}})"
        else:
            return f"Consumer(builder: ({ctx}, ref, {child}) {{\nfinal {val} = ref.watch({provider_var});\n {body}\n}})"

    content = pattern.sub(repl, content)
    
    # Handle single line Consumers without brackets: builder: (context, val, child) => Widget
    pattern2 = re.compile(r'Consumer\s*<\s*([a-zA-Z0-9_]+)\s*>\s*\(\s*builder\s*:\s*\(\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*\)\s*=>\s*(.*?)\)', re.DOTALL)
    
    def repl2(m):
        provider_type = m.group(1)
        ctx = m.group(2)
        val = m.group(3)
        child = m.group(4)
        body = m.group(5).strip()
        
        provider_var = provider_type[0].lower() + provider_type[1:] + 'Provider'
        
        return f"Consumer(builder: ({ctx}, ref, {child}) {{\nfinal {val} = ref.watch({provider_var});\nreturn {body};\n}})"

    content = pattern2.sub(repl2, content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Refactored Consumers in {filepath}")

import glob
for root, dirs, files in os.walk(r'c:\0905NyutjiDev\frontend\lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_consumers(os.path.join(root, file))
