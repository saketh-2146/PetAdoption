import sys
import pandas as pd
import random

def generate_test_name(module, index):
    actions = ['Verify', 'Validate', 'Ensure', 'Test', 'Check']
    components = ['Login Screen', 'Adoption Form', 'Pet Listing', 'Admin Dashboard', 'Profile Page', 'Notifications', 'Wishlist', 'My Orders', 'Chat Interface', 'Image Upload']
    endpoints = ['/api/auth/login', '/api/pets', '/api/applications', '/api/health', '/api/users/profile']
    
    if module.lower() == 'selenium':
        element = random.choice(['button click', 'form validation', 'page load', 'scroll behavior', 'responsive layout', 'CSS rendering', 'dropdown selection'])
        comp = random.choice(components)
        return f"{random.choice(actions)} {element} on {comp} (Web)"
        
    elif module.lower() == 'appium':
        element = random.choice(['touch gesture', 'swipe down', 'pull to refresh', 'offline mode', 'push notification', 'camera access', 'location permission'])
        comp = random.choice(components)
        return f"{random.choice(actions)} {element} for {comp} (Android App)"
        
    elif module.lower() == 'security':
        vuln = random.choice(['SQL Injection', 'XSS attack', 'CSRF token', 'Rate limiting', 'JWT token expiration', 'Data exposure', 'CORS policy'])
        endpoint = random.choice(endpoints)
        return f"Security Assessment: {vuln} prevention on {endpoint}"
        
    elif module.lower() == 'vulnerability':
        dep = random.choice(['express', 'firebase-admin', 'cors', 'dotenv', 'jsonwebtoken', 'mongoose', 'helmet'])
        return f"Vulnerability Scan: Check CVEs for {dep} dependency version {random.randint(1, 5)}.{random.randint(0, 10)}.0"
        
    elif module.lower() == 'performance':
        users = random.choice([50, 100, 500, 1000, 5000])
        endpoint = random.choice(endpoints)
        return f"Load Test: Benchmark {endpoint} with {users} concurrent requests"
        
    else:
        return f"{random.choice(actions)} standard workflow {index} on {random.choice(components)}"

def generate_report(name):
    data = []
    priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
    
    for i in range(1, 301):
        duration = f"{random.uniform(0.05, 0.45):.3f}s"
        priority = random.choice(priorities)
        
        data.append({
            'Test ID': f'TC_PET_{name[:3].upper()}_{i:03d}',
            'Module': name.capitalize(),
            'Test Name': generate_test_name(name, i),
            'Priority': priority,
            'Execution Time': duration
        })
    df = pd.DataFrame(data)
    df.to_excel(f'{name}_report.xlsx', index=False)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        generate_report(sys.argv[1])
    else:
        generate_report('selenium')
        generate_report('appium')
        generate_report('k6')
