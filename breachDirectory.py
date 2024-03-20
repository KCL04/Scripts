import requests
import argparse
import time
import concurrent.futures

url = "https://breachdirectory.p.rapidapi.com/"

parser = argparse.ArgumentParser()
parser.add_argument('-f', '--function', help="Function type: auto, sources, password, domain, or dehash. Default = auto", required=False, default="auto")
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-t', '--term', help="Search Term.", required=False)
group.add_argument('-l', '--list', help="Search using a list. One search term per row.", required=False)
parser.add_argument('-d', '--dehash', action='store_true', help="Dehash the password", required=False)
parser.add_argument('-o', '--output', help="Output file to store results.", required=False)
parser.add_argument('-v', '--verbose', action='store_true', help="Verbose mode to show status of the script.")
parser.add_argument('-w', '--workers', type=int, default=5, help="Number of worker threads for multithreaded processing. Default is 5.")
parser.add_argument('-r', '--retries', type=int, default=3, help="Number of retry attempts for failed requests. Default is 3.")
parser.add_argument('-k', '--key', required=True)

args = parser.parse_args()

headers = {
        "X-RapidAPI-Key": args.key,
        "X-RapidAPI-Host": "breachdirectory.p.rapidapi.com"
}

def send_request(querystring):
    try:
        response = requests.get(url, headers=headers, params=querystring)
        if args.verbose:
            print(f"Request URL: {response.url}")
        if response.ok:
            return response.json()
        elif response.status_code == 429:
            if args.verbose:
                print(f"Received status code 429 (Too Many Requests). Retrying request...")
            return None
        elif response.status_code == 500 or response.status_code == 504:
            if args.verbose:
                print(f"Received status code {response.status_code}. Retrying request...")
            return None
        else:
            print(f"Request failed with status code {response.status_code}")
            return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

def process_line(line):
    querystring = {
        'func': args.function,
        'term': line.strip()  # Remove newline character
    }
    retry_count = 0
    while retry_count < args.retries:
        data = send_request(querystring)
        if data:
            output_data = []
            if 'result' in data:
                if data['result']:
                    for result in data['result']:
                        email = result.get('email', 'N/A')
                        password = result.get('password', 'N/A')
                        hash_value = result.get('hash', 'N/A')
                        if args.dehash and hash_value != 'N/A':
                            dehashed_password = dehash_password(hash_value)
                            output_data.append(f"Email: {email}\nHashed password: {password}\nHash Value: {hash_value}\nDehashed Password: {dehashed_password}\n")
                        else:
                            output_data.append(f"Email: {email}\nHashed password: {password}\nHash Value: {hash_value}\n")
                else:
                    output_data.append("No results found\n")
            else:
                output_data.append("No results found\n")
            return ''.join(output_data)
        else:
            retry_count += 1
            time.sleep(1)  # Wait for 1 second before retrying
    return "Request failed\n"

def dehash_password(hash_value):
    querystring = {
        'func': 'dehash',
        'term': hash_value
    }
    data = send_request(querystring)
    return data['found']
    

try:
    if args.list:
        with open(args.list) as file:
            with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
                results = executor.map(process_line, file)
                output_data = list(results)
            if args.output:
                with open(args.output, 'w') as output_file:
                    output_file.writelines(output_data)
            else:
                print("Output file not specified. Results will be printed to console.")
                print("\n".join(output_data))
    else:
        querystring = {
            'func': args.function,
            'term': args.term
        }
        data = send_request(querystring)
        if data:
            output_data = []
            if 'result' in data:
                if data['result']:
                    for result in data['result']:
                        email = result.get('email', 'N/A')
                        password = result.get('password', 'N/A')
                        hash_value = result.get('hash', 'N/A')
                        if args.dehash and hash_value != 'N/A':
                            dehashed_password = dehash_password(hash_value)
                            output_data.append(f"Email: {email}\nHashed password: {password}\nHash Value: {hash_value}\nDehashed Password: {dehashed_password}\n")
                        else:
                            output_data.append(f"Email: {email}\nHashed password: {password}\nHash Value: {hash_value}\n")
                else:
                    output_data.append("No results found\n")
            else:
                output_data.append("No results found\n")
            if args.output:
                with open(args.output, 'w') as output_file:
                    output_file.writelines(output_data)
            else:
                print("Output file not specified. Results will be printed to console.")
                print("\n".join(output_data))
except KeyboardInterrupt:
    print("User interrupted execution.")

