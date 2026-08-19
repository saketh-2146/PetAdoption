import sys
import pandas as pd
import random
import itertools

def generate_300_unique_test_names():
    actions = ["Verify", "Validate", "Check", "Test", "Ensure"]
    subjects = ["user login", "registration", "password reset", "pet listing creation", "image upload", "adoption application", "admin approval", "search filter", "wishlist addition", "checkout process", "profile update", "notification delivery", "email dispatch", "Firebase authentication", "database write", "API rate limiting", "session timeout", "form validation", "error handling", "data synchronization"]
    conditions = ["with valid data", "with missing fields", "using invalid credentials", "on slow network", "with special characters", "exceeding max length", "with empty required fields", "during concurrent requests", "with expired token", "after cold start", "with caching disabled", "under heavy load", "with unsupported file format", "using SQL injection payload", "with XSS payload"]
    
    # Generate all possible combinations: 5 * 20 * 15 = 1500 unique names
    all_combinations = []
    for action in actions:
        for subject in subjects:
            for condition in conditions:
                all_combinations.append(f"{action} {subject} {condition}")
                
    # Shuffle and pick exactly 300 unique names
    random.shuffle(all_combinations)
    return all_combinations[:300]

def generate_report(name):
    data = []
    priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
    
    # Get exactly 300 unique test names
    unique_test_names = generate_300_unique_test_names()
    
    for i in range(1, 301):
        duration = f"{random.uniform(0.05, 0.45):.3f}s"
        priority = random.choice(priorities)
        
        data.append({
            'Test ID': f'TC_PET_{name[:3].upper()}_{i:03d}',
            'Module': name.capitalize(),
            'Test Name': unique_test_names[i - 1],
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
