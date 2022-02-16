import boto3
import base64
import gzip
import json

# Reads the compressed and encoded body to a json object
def decompressRequest(body):
  return json.loads(base64.b64decode(gzip.decompress(base64.b64decode(body))))

# Converts a string to an encoded / compressed blob to send
def compressString(res):
  return base64.b64encode(gzip.compress(base64.b64encode(res.encode())))

def lambda_handler(event, context):
  return {
          'statusCode': 200,
          'body': json.dumps('Hello! Please replace me with the real code')
         }