# -*- coding: utf-8 -*-

import os
import sys
import json

import requests
import jwt

import markdown

from datetime import datetime as date
from optparse import OptionParser

# Admin API key goes here
api_url = 'https://pie01.com/ghost/api/admin/posts/'
api_key = os.environ['GHOST_ADMIN_API_KEY']

# Split the key into ID and SECRET
id, secret = api_key.split(':')

# Prepare header and payload
iat = int(date.now().timestamp())

header = {'alg': 'HS256', 'typ': 'JWT', 'kid': id}
payload = { 'iat': iat, 'exp': iat + 5 * 60, 'aud': '/admin/' }

# Create the token (including decoding secret)
token = jwt.encode(payload, bytes.fromhex(secret), algorithm='HS256', headers=header)

def create_post(post_file, options):
    # Make an authenticated request to create a post
    with open(post_file, "r") as f:
        post_content = f.read()
    html_content = markdown.markdown(post_content)

    mobiledoc = {
            "version": '0.3.1',
            "markups": [],
            "atoms": [],
            "cards": [['html', {'cardName': 'html', 'html': html_content}]],
            "sections": [[10, 0]]
            };

    file_name = os.path.basename(post_file)
    post_data = {
            "posts": [{
                "title": options.post_title or os.path.splitext(file_name)[0],
                "mobiledoc": json.dumps(mobiledoc),
                'status': 'published' if options.publish else 'draft'
                #"html": True
                }]
            }

    headers = {'Authorization': 'Ghost {}'.format(token)}
    if options.dry_run: 
        print(post_data)
        return

    response = requests.post(api_url, headers=headers, json=post_data)


    if response.status_code // 100 == 2:
        print(response.content)
    else:
        print(f'Error: {response.status_code} - {response.content}')

def main(argv=None):
    usage = "usage: %prog [options] input_path title [arg2 ...]"
    parser = OptionParser(usage)
    parser.add_option("-t", "--title", dest="post_title", help="post title")
    parser.add_option("-p", "--publish", action="store_true", dest="publish", help="publish the post")
    parser.add_option("-n", "--dry-run", action="store_true", dest="dry_run", help="dry run")
    (options, args) = parser.parse_args(argv)
    #print(options, args)
    create_post(args[1], options)
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv))

