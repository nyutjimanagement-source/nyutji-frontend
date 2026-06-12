import os

providers = {
    'auth_provider.dart': ('authProvider', 'AuthProvider'),
    'order_provider.dart': ('orderProvider', 'OrderProvider'),
    'issue_provider.dart': ('issueProvider', 'IssueProvider'),
    'sentiment_provider.dart': ('sentimentProvider', 'SentimentProvider'),
    'simulasi_provider.dart': ('simulasiProvider', 'SimulasiProvider'),
    'wallet_provider.dart': ('walletProvider', 'WalletProvider'),
}

def process_file(filepath):
    filename = os.path.basename(filepath)
    if filename in providers:
        var_name, class_name = providers[filename]
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if 'ChangeNotifierProvider' not in content:
            declaration = f"\nfinal {var_name} = ChangeNotifierProvider<{class_name}>((ref) => {class_name}());\n"
            content += declaration
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Added {var_name} to {filename}")

if __name__ == "__main__":
    providers_dir = r'c:\0905NyutjiDev\frontend\lib\providers'
    for file in os.listdir(providers_dir):
        if file.endswith('.dart'):
            process_file(os.path.join(providers_dir, file))
