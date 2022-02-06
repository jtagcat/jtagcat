# -*- coding: utf-8 -*-
####################################################################################################
#
# Your working dir (absolute, ending with slash, inside double quotes), usually the directory you git cloned the 2 files in to
wdir = "/home/redacted/.ytbu/"
#
# Do you want webhook notifier on? (When the OAuth token needs to be refreshed by you) (inside double quotes)
webhooky = "false"
# What's your webhook url? (inside double quotes)
webhook_url = ""
#
# NOTE! If the token needs to be refreshed/created, you will need to run the python script from the local terminal: python3 ytbu_getdata.py --noauth_local_webserver
# If this is run by cron (no way to input any data to it), kill ytbu: https://askubuntu.com/a/314292
#
####################################################################################################


import os
import google.oauth2.credentials
import google_auth_oauthlib.flow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from google_auth_oauthlib.flow import InstalledAppFlow

# The CLIENT_SECRETS_FILE variable specifies the name of a file that contains
# the OAuth 2.0 information for this application, including its client_id and
# client_secret.
CLIENT_SECRETS_FILE = "client_secret.json"

# This OAuth 2.0 access scope allows for full read/write access to the
# authenticated user's account and requires requests to use an SSL connection.
SCOPES = ['https://www.googleapis.com/auth/youtube.force-ssl']
API_SERVICE_NAME = 'youtube'
API_VERSION = 'v3'

from oauth2client import client # Added
from oauth2client import tools # Added
from oauth2client.file import Storage # Added

def get_authenticated_service(): # Modified
    credential_path = os.path.join('./', 'credential_sample.json')
    store = Storage(credential_path)
    credentials = store.get()
    if not credentials or credentials.invalid:
        #check if webhook report is enabled
        if webhooky is 'true':
            #make a webhook request
            import requests
            requests.post(webhook_url)
        else:
            print("No weebhook, OAuth token needed!")
        flow = client.flow_from_clientsecrets(CLIENT_SECRETS_FILE, SCOPES)
        credentials = tools.run_flow(flow, store)
    return build(API_SERVICE_NAME, API_VERSION, credentials=credentials)

def print_response(response):
  print(response)

# Build a resource based on a list of properties given as key-value pairs.
# Leave properties with empty values out of the inserted resource.
def build_resource(properties):
  resource = {}
  for p in properties:
    # Given a key like "snippet.title", split into "snippet" and "title", where
    # "snippet" will be an object and "title" will be a property in that object.
    prop_array = p.split('.')
    ref = resource
    for pa in range(0, len(prop_array)):
      is_array = False
      key = prop_array[pa]

      # For properties that have array values, convert a name like
      # "snippet.tags[]" to snippet.tags, and set a flag to handle
      # the value as an array.
      if key[-2:] == '[]':
        key = key[0:len(key)-2:]
        is_array = True

      if pa == (len(prop_array) - 1):
        # Leave properties without values out of inserted resource.
        if properties[p]:
          if is_array:
            ref[key] = properties[p].split(',')
          else:
            ref[key] = properties[p]
      elif key not in ref:
        # For example, the property is "snippet.title", but the resource does
        # not yet have a "snippet" object. Create the snippet object here.
        # Setting "ref = ref[key]" means that in the next time through the
        # "for pa in range ..." loop, we will be setting a property in the
        # resource's "snippet" object.
        ref[key] = {}
        ref = ref[key]
      else:
        # For example, the property is "snippet.description", and the resource
        # already has a "snippet" object.
        ref = ref[key]
  return resource

# Remove keyword arguments that are not set
def remove_empty_kwargs(**kwargs):
  good_kwargs = {}
  if kwargs is not None:
    for key, value in kwargs.items():
      if value:
        good_kwargs[key] = value
  return good_kwargs

def subscriptions_list_my_subscriptions(client, **kwargs):
  # See full sample for function
  kwargs = remove_empty_kwargs(**kwargs)

  response = client.subscriptions().list(
    **kwargs
  ).execute()

  return print_response(response)


if __name__ == '__main__':
  # When running locally, disable OAuthlib's HTTPs verification. When
  # running in production *do not* leave this option enabled.
  os.environ['OAUTHLIB_INSECURE_TRANSPORT'] = '1'
  client = get_authenticated_service()
  #Check if it's ran multiple times and get the nextPageToken
  nextpager = os.path.join(wdir, 'ytbu_nextpager.py')
  if os.path.isfile(nextpager):
    from ytbu_nextpager import *
    #Multiple times ran.
    #Get new data
    subscriptions_list_my_subscriptions(client,
      part='snippet',
      maxResults=50,
      order='alphabetical',
      pageToken=nextpagevar,
      mine=True)
  else:
    #First time ran, snippets contain the valuable ids
    subscriptions_list_my_subscriptions(client,
      part='snippet',
      maxResults=50,
      order='alphabetical',
      mine=True)

