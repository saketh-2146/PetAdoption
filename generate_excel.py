import sys
import pandas as pd
import random

def generate_300_short_test_names():
    features = [
        "Login", "Register", "Logout", "Profile", "AddPet", "EditPet", 
        "DeletePet", "Wishlist", "Search", "Filter", "Checkout", 
        "AdminApprove", "AdminReject", "NotifyEmail", "NotifyApp", 
        "UploadImage", "Database", "API_Health", "Payment", "AuthToken"
    ]
    scenarios = [
        "Valid", "Invalid", "Empty", "Null", "Timeout", 
        "Boundary", "MaxLen", "MinLen", "Duplicate", "Missing",
        "Success", "Failed", "Retry", "SQLi", "XSS"
    ]
    
    # 20 features * 15 scenarios = 300 exactly unique combinations
    all_combinations = []
    for feature in features:
        for scenario in scenarios:
            all_combinations.append(f"{feature}_{scenario}")
            
    # Shuffle for randomness
    random.shuffle(all_combinations)
    return all_combinations

def generate_report(name):
    data = []
    priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
    
    # Get exactly 300 unique short test names
    unique_test_names = generate_300_short_test_names()
    
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
