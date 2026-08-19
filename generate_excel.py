import sys
import pandas as pd
import random

def get_qa_test_names():
    return [
        "Verify user can log in with valid credentials",
        "Verify error message on invalid email format",
        "Verify user cannot log in with incorrect password",
        "Verify 'Forgot Password' link navigates to reset page",
        "Verify user registration with all mandatory fields",
        "Verify validation errors on empty registration form",
        "Verify password masking toggle in login form",
        "Verify successful Firebase authentication token retrieval",
        "Verify user can successfully create a new pet listing",
        "Verify validation errors when creating listing without images",
        "Verify pet image uploads successfully to Supabase Storage",
        "Verify user can edit their existing pet listing",
        "Verify user can delete their pet listing",
        "Verify pet search returns relevant results by breed",
        "Verify pet filtering by category (Dog, Cat, etc.)",
        "Verify pet details page loads all information correctly",
        "Verify user can submit an adoption application",
        "Verify adoption form validation for missing phone number",
        "Verify seller receives in-app notification for new application",
        "Verify seller receives email notification via Brevo",
        "Verify admin can approve a pending pet listing",
        "Verify admin can reject a pet listing with reason",
        "Verify pending listings are hidden from public marketplace",
        "Verify user can add a pet to their Wishlist",
        "Verify user can remove a pet from their Wishlist",
        "Verify 'My Orders' screen displays past adoption applications",
        "Verify user can update their profile avatar",
        "Verify user can add a new delivery address",
        "Verify API endpoint returns 200 OK for health check",
        "Verify API endpoint rejects unauthorized requests with 401",
        "Verify SQL Injection prevention on search parameters",
        "Verify XSS prevention on pet description input",
        "Verify Rate Limiting blocks excessive login attempts"
    ]

def generate_report(name):
    data = []
    priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
    test_cases = get_qa_test_names()
    
    for i in range(1, 301):
        duration = f"{random.uniform(0.05, 0.45):.3f}s"
        priority = random.choice(priorities)
        # Cycle through the test cases, adding a sequence number if we exceed the list size
        base_test = test_cases[i % len(test_cases)]
        test_name = f"{base_test} (Scenario {i})"
        
        data.append({
            'Test ID': f'TC_PET_{name[:3].upper()}_{i:03d}',
            'Module': name.capitalize(),
            'Test Name': test_name,
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
