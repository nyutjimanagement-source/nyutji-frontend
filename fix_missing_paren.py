import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content

    # Find all Consumer blocks
    idx = 0
    while True:
        match = re.search(r'Consumer\s*\(\s*builder\s*:\s*\([^)]+\)\s*\{', content[idx:])
        if not match:
            break
        
        start_match = idx + match.start()
        # Find the matching closing brace for the {
        brace_start = idx + match.end() - 1
        count = 0
        end_brace = -1
        for i in range(brace_start, len(content)):
            if content[i] == '{':
                count += 1
            elif content[i] == '}':
                count -= 1
                if count == 0:
                    end_brace = i
                    break
        
        if end_brace != -1:
            # Check what follows the }
            after_brace = content[end_brace+1:end_brace+10].lstrip()
            # If it's a comma (e.g. `},`), then it's missing a parenthesis!
            if after_brace.startswith(','):
                # Replace } with })
                content = content[:end_brace] + '})' + content[end_brace+1:]
                idx = end_brace + 2
            # If it's empty or something else and the Consumer is a return statement or assigned to a var
            elif after_brace.startswith(';'):
                # But wait, if it's `};`, then it's missing `)` -> `});`
                content = content[:end_brace] + '})' + content[end_brace+1:]
                idx = end_brace + 2
            elif after_brace == '' or after_brace.startswith('\n') or after_brace.startswith(']'):
                # Sometimes it might just be missing entirely if it was the last thing
                # Let's see if the character right before `}` is `;` (indicating the end of the block).
                # But how do we know if Consumer wasn't already closed?
                # If the original code was Consumer( ... ), it would be `})`.
                # If it is currently `}`, we need to change it to `})`.
                # But wait! If it's already `})`, then content[end_brace+1] is `)`.
                # So `after_brace.startswith(')')` would be True.
                if not after_brace.startswith(')'):
                    # It means `)` is missing!
                    content = content[:end_brace] + '})' + content[end_brace+1:]
                    idx = end_brace + 2
                else:
                    idx = end_brace + 1
            else:
                idx = end_brace + 1
        else:
            idx = start_match + len(match.group(0))

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
