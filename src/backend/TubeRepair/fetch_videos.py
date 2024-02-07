import requests
import json
import sys

# Check if the token was passed as a command-line argument
if len(sys.argv) < 2:
    print("Usage: script.py <token>")
    sys.exit(1)

# The token is the first command-line argument
token = sys.argv[1]

# Define the URL and API key
url = 'https://www.youtube.com/youtubei/v1/browse'
params = {
    'key': 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
    'prettyPrint': 'false',
    'alt': 'json'
}

# Define the headers with the token
headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}',  # Use the token passed as argument
    'X-Origin': 'https://www.youtube.com',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
    'X-Goog-Visitor-Id': 'CgtfZ21JODZteEY2dyi-nf-tBjIOCgJFUxIIEgQSAgsMIEE%3D',
    'X-Youtube-Client-Version': '2.20240201.01.00'
}

# Define the POST request data
data = {
    'context': {
        'client': {
            'hl': 'en',
            'gl': 'US',
            'clientName': 'WEB',
            'clientVersion': '2.20240201.01.00'
        }
    },
    'browseId': 'FEwhat_to_watch'
}

# Make the POST request
response = requests.post(url, params=params, headers=headers, json=data)

# Check if the request was successful
if response.status_code == 200:
    # Load the JSON response
    json_data = response.json()
    
    # Print the JSON data
    print(json.dumps(json_data, indent=4))
else:
    print(f"Request failed with status code: {response.status_code}")
