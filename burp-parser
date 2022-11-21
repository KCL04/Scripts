import bs4
import base64
from bs4 import BeautifulSoup
import argparse
import lxml

parser = argparse.ArgumentParser()
parser.add_argument('-f','--file', help='file to use', required=True)
parser.add_argument('-s','--separator', help='seperator to choose file name (i.e. name)', required=True)
args = parser.parse_args()

burp_file = open(args.file,'r')
xml = burp_file.read()
parsed = BeautifulSoup(xml, features="xml")

for document in parsed.find_all('item'):
    try:
        bodyTag = document.find('response')
        bodyContents = bodyTag.contents[0]
        data = base64.b64decode(bodyContents)
        content = data.split(b'\r\n\r\n')[1]
        stringss = content.split(bytes(args.separator, encoding='utf-8'))[1]
        json = stringss.split(b'\"')[2]
        filename = json.decode('utf-8')
        f = open(filename + ".json", "a")
        f.write(content.decode('utf-8'))
        f.close()
    except Exception as e:
        print(e)
