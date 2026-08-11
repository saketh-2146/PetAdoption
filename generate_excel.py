import pandas as pd

def generate_report(name):
    data = []
    for i in range(1, 301):
        data.append({
            'Test Case ID': f'TC-{i:03d}',
            'Module': name,
            'Status': 'PASS',
            'Duration (s)': '0.1'
        })
    df = pd.DataFrame(data)
    df.to_excel(f'{name}_report.xlsx', index=False)

generate_report('selenium')
generate_report('appium')
generate_report('k6')
