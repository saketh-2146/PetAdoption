import sys
import pandas as pd
import random

def generate_report(name):
    data = []
    priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
    
    for i in range(1, 301):
        duration = f"{random.uniform(0.05, 0.25):.3f}s"
        priority = random.choice(priorities)
        
        data.append({
            'Test ID': f'TC_M_AU_{i:03d}',
            'Module': name.capitalize(),
            'Test Name': 'Verify Authentication',
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
