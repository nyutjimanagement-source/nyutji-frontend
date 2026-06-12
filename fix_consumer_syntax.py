import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content

    # Fix return Text( ... ), ;
    # This happens when the arrow function => had a trailing comma
    # e.g. return Text( ... ),
    #      );
    # We replace `),\s*);` with `);`
    content = re.sub(r'\),\s*\);', r');', content)

    # Just in case there is `,;`
    content = re.sub(r',\s*;', r';', content)

    # In admin_main_screen, there might be `}),` where `})` was expected?
    # Wait, the Consumer is inside a children list, so it SHOULD be `}),`.
    # Let's check if there are any other malformed parts.

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
