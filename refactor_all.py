import os
import re

def to_camel_case(s):
    return s[0].lower() + s[1:]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Imports
    if 'package:flutter_riverpod/flutter_riverpod.dart' not in content:
        if 'import \'package:flutter/material.dart\';' in content:
            content = content.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'package:flutter_riverpod/flutter_riverpod.dart\';')
        elif 'import \'package:provider/provider.dart\';' in content:
            content = content.replace('import \'package:provider/provider.dart\';', 'import \'package:flutter_riverpod/flutter_riverpod.dart\';')
    
    # Remove provider imports
    content = re.sub(r"import 'package:provider/provider\.dart';\n?", "", content)

    # StatefulWidget -> ConsumerStatefulWidget
    content = re.sub(r'class\s+(\w+)\s+extends\s+StatefulWidget', r'class \1 extends ConsumerStatefulWidget', content)
    
    # State<T> -> ConsumerState<T> (but ignore those with SingleTickerProviderStateMixin)
    content = re.sub(r'class\s+(_\w+State)\s+extends\s+State<(\w+)>', r'class \1 extends ConsumerState<\2>', content)
    
    # State<T> in createState
    content = re.sub(r'State<(\w+)>\s+createState\(\)', r'ConsumerState<\1> createState()', content)

    # StatelessWidget -> ConsumerWidget
    content = re.sub(r'class\s+(\w+)\s+extends\s+StatelessWidget', r'class \1 extends ConsumerWidget', content)
    content = re.sub(r'Widget\s+build\(BuildContext\s+context\)\s*{', r'Widget build(BuildContext context, WidgetRef ref) {', content)

    # Replace Provider.of<T>(context, listen: false) with ref.read(tProvider)
    # Using regex to find T and the variable assignment
    def replacer_read(m):
        t = m.group(2)
        var_name = t[0].lower() + t[1:] + 'Provider'
        if var_name == 'nyutjiAuthProvider': var_name = 'authProvider'
        return f'{m.group(1)}ref.read({var_name})'

    content = re.sub(r'(=\s*)Provider\.of<(\w+)>\(context,\s*listen:\s*false\)', replacer_read, content)

    # Replace Provider.of<T>(context) with ref.watch(tProvider)
    def replacer_watch(m):
        t = m.group(2)
        var_name = t[0].lower() + t[1:] + 'Provider'
        if var_name == 'nyutjiAuthProvider': var_name = 'authProvider'
        return f'{m.group(1)}ref.watch({var_name})'

    content = re.sub(r'(=\s*)Provider\.of<(\w+)>\(context\)', replacer_watch, content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Refactored {filepath}")

def process_dir(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    process_dir(r'c:\0905NyutjiDev\frontend\lib')
