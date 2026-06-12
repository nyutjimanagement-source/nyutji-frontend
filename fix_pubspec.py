with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
in_dev_deps = False
for line in lines:
    if line.startswith('dev_dependencies:'):
        in_dev_deps = True
    elif line.startswith('flutter_launcher_icons:') or line.startswith('dependency_overrides:') or line.startswith('flutter:'):
        in_dev_deps = False
        
    if in_dev_deps and 'flutter_riverpod:' in line:
        continue # Skip this line
    new_lines.append(line)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('pubspec.yaml cleaned')
