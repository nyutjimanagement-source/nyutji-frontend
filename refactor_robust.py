import os
import re

def extract_balanced(text, start_idx, open_char, close_char):
    count = 0
    for i in range(start_idx, len(text)):
        if text[i] == open_char:
            count += 1
        elif text[i] == close_char:
            count -= 1
            if count == 0:
                return text[start_idx:i+1], i
    return None, -1

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
    
    content = re.sub(r"import 'package:provider/provider\.dart';\n?", "", content)

    # StatefulWidget -> ConsumerStatefulWidget
    content = re.sub(r'class\s+(\w+)\s+extends\s+StatefulWidget', r'class \1 extends ConsumerStatefulWidget', content)
    content = re.sub(r'class\s+(_\w+State)\s+extends\s+State<(\w+)>', r'class \1 extends ConsumerState<\2>', content)
    content = re.sub(r'\s+State<(\w+)>\s+createState\(\)', r' ConsumerState<\1> createState()', content)
    content = re.sub(r'class\s+(\w+)\s+extends\s+StatelessWidget', r'class \1 extends ConsumerWidget', content)
    
    # build method for ConsumerWidget
    if 'extends ConsumerWidget' in content:
        content = re.sub(r'Widget\s+build\(BuildContext\s+context\)\s*{', r'Widget build(BuildContext context, WidgetRef ref) {', content)
        content = re.sub(r'Widget\s+build\(BuildContext\s+context\)\s*=>', r'Widget build(BuildContext context, WidgetRef ref) =>', content)

    def replacer_read(m):
        t = m.group(2)
        var_name = t[0].lower() + t[1:] + 'Provider'
        if var_name == 'nyutjiAuthProvider': var_name = 'authProvider'
        return f'{m.group(1)}ref.read({var_name})'

    content = re.sub(r'(=\s*)Provider\.of<(\w+)>\(context,\s*listen:\s*false\)', replacer_read, content)

    def replacer_watch(m):
        t = m.group(2)
        var_name = t[0].lower() + t[1:] + 'Provider'
        if var_name == 'nyutjiAuthProvider': var_name = 'authProvider'
        return f'{m.group(1)}ref.watch({var_name})'

    content = re.sub(r'(=\s*)Provider\.of<(\w+)>\(context\)', replacer_watch, content)

    # Robust Consumer<T> replacement
    idx = 0
    while True:
        match = re.search(r'Consumer\s*<\s*([a-zA-Z0-9_]+)\s*>\s*\(', content[idx:])
        if not match:
            break
        
        start_match = idx + match.start()
        provider_type = match.group(1)
        provider_var = provider_type[0].lower() + provider_type[1:] + 'Provider'
        if provider_var == 'nyutjiAuthProvider': provider_var = 'authProvider'
        
        paren_start = idx + match.end() - 1
        arg_block, end_idx = extract_balanced(content, paren_start, '(', ')')
        
        if arg_block:
            # We must find the `builder: (ctx, val, child)` part accurately without greedy swallowing
            b_match = re.search(r'builder\s*:\s*\(\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*\)\s*(?:\{|=>)', arg_block)
            if b_match:
                ctx = b_match.group(1)
                val = b_match.group(2)
                child = b_match.group(3)
                
                # We know the position of `{` or `=>`
                brace_or_arrow_idx = b_match.end() - 1
                if arg_block[b_match.end()-2:b_match.end()] == '=>':
                    # Arrow function
                    # The expression is from `=>` until the end of the block (excluding the final `)`)
                    expr = arg_block[b_match.end():-1].strip()
                    # If it ends with comma, strip it
                    if expr.endswith(','):
                        expr = expr[:-1].strip()
                    
                    new_arg_block = arg_block[:b_match.start()] + f"builder: ({ctx}, ref, {child}) {{\nfinal {val} = ref.watch({provider_var});\nreturn {expr};\n}})"
                else:
                    # Block function (ends with `{`)
                    # We inject `final val = ref.watch(provider);` right after `{`
                    # wait, b_match.end() - 1 is the `{`
                    new_arg_block = arg_block[:b_match.start()] + f"builder: ({ctx}, ref, {child}) {{\nfinal {val} = ref.watch({provider_var});" + arg_block[b_match.end():]

                new_consumer = f"Consumer{new_arg_block}"
                content = content[:start_match] + new_consumer + content[end_idx+1:]
                idx = start_match + len(new_consumer)
            else:
                idx = end_idx + 1
        else:
            idx += 1

    # manual fixes
    content = content.replace('__BeautyPopupWidgetState', '_BeautyPopupWidgetState')
    if filepath.endswith('api_service.dart'):
        if 'image_picker.dart' not in content:
            content = content.replace("import 'package:dio/dio.dart';", "import 'package:dio/dio.dart';\nimport 'package:image_picker/image_picker.dart';")
    content = content.replace('authProviderProvider', 'authProvider')
    content = content.replace('ConsumerConsumerState', 'ConsumerState') # just in case

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
