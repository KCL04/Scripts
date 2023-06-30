import json
import random
import requests
import string
import uuid
import re
import pandas as pd
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-p','--path',help='Path to Swagger file. Expected JSON format; OAS 1.0',required=True)
parser.add_argument('-s','--sample',help='Sample dummy data. Default is 690a2e2f-a1ff-40fd-9bae-8d271091d886', default='690a2e2f-a1ff-40fd-9bae-8d271091d886') 
args = parser.parse_args()

swagger_file = args.path
sample_data = args.sample

results_df = pd.DataFrame(columns=['Method', 'Path', 'Body', 'Response'])

def generate_sample_body(schema, definitions):
    sample_body = {}
    properties = schema.get('properties', {})

    for prop_name, prop_schema in properties.items():
        prop_type = prop_schema.get('type')

        if prop_type == 'integer':
            sample_body[prop_name] = random.randint(0, 100)
        elif prop_type == 'string':
            if 'format' in prop_schema and prop_schema['format'] == 'uuid':
                sample_body[prop_name] = str(uuid.uuid4())
            else:
                sample_body[prop_name] = ''.join(random.choices(string.ascii_letters, k=10))
        elif prop_type == 'boolean':
            sample_body[prop_name] = random.choice([True, False])
        elif prop_type == 'array':
            items_schema = prop_schema.get('items', {})
            ref = items_schema.get('$ref')
            if ref:
                ref_definition = ref.split('/')[-1]
                sample_body[prop_name] = [generate_sample_body(definitions[ref_definition], definitions)]
            else:
                sample_body[prop_name] = [generate_sample_body(items_schema, definitions)]

    return sample_body

def replace_path_parameters(path, body):
    parameter_pattern = r'{([^}]*)}'
    parameters = re.findall(parameter_pattern, path)

    for parameter in parameters:
        matching_parameters = [param for param in body.keys() if param.lower() == parameter.lower()]
        if matching_parameters:
            path = path.replace('{' + parameter + '}', str(body[matching_parameters[0]]), 1)
        else:
            # If matching parameter is not found in body, replace it with a sample value
            path = path.replace('{' + parameter + '}', sample_data)

    return path

def save_to_dataframe(method, path, body, response_data):
    global results_df
    data = [(method, path, body, response_data)]
    results_df = results_df.append(pd.DataFrame(data, columns=['Method', 'Path', 'Body', 'Response']), ignore_index=True)
    
    # Write the complete data to the Excel file
    file_path = 'api_put_post_responses.xlsx'
    sheet_name = 'Responses'
    with pd.ExcelWriter(file_path) as writer:
        results_df.to_excel(writer, sheet_name=sheet_name, index=False)

# Load the OAS v1.0 JSON file
with open(swagger_file, 'r') as file:
    oas_data = json.load(file)

# Get the host information from the OAS file
host = oas_data.get('host', '')

# Get all definitions from the OAS file
definitions = oas_data.get('definitions', {})

# Iterate over paths and methods to find requests with a body
for path, path_details in oas_data.get('paths', {}).items():
    for method, method_details in path_details.items():
        if 'parameters' in method_details:
            for param in method_details['parameters']:
                if param.get('in') == 'body':
                    request_body_schema = param.get('schema')

                    # Generate a sample body using the request body schema
                    sample_body = {}
                    if request_body_schema:
                        ref = request_body_schema.get('$ref')
                        if ref:
                            ref_definition = ref.split('/')[-1]
                            sample_body = generate_sample_body(definitions[ref_definition], definitions)
                        else:
                            sample_body = generate_sample_body(request_body_schema, definitions)

                    # Replace path parameters with the corresponding values from the sample body
                    updated_path = replace_path_parameters(path, sample_body)

                    # Print the matching path, method, host, and the generated sample body
                    print(f"Request sent for Path: {updated_path}, Method: {method}, Host: {host}")

                    # Send the request with the sample body
                    url = 'https://' + host + updated_path
                    response = requests.request(method.upper(), url, json=sample_body)

                    # Save request details to the Excel file
                    save_to_dataframe(method, updated_path, sample_body, response.text)

# Display the DataFrame with request details
print(results_df)
