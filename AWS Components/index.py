import boto3
import base64
import gzip
import json

# Save the API key out here for quick reuse
ssm = boto3.client('ssm')
apiKey = ssm.get_parameter(Name='budgies-budgets-api-key')['Parameter']['Value']

# Dynamo client
dynamo = boto3.client('dynamodb')

# Reads the compressed and encoded body to a json object
def decompressRequest(body):
  return json.loads(base64.b64decode(gzip.decompress(base64.b64decode(body))))

# Converts a string to an encoded / compressed blob to send
def compressString(res):
  return base64.b64encode(gzip.compress(base64.b64encode(res.encode())))

def getAllFinancialData(start, end):
  # Get the account data first 
  returnData = {'accounts': [], 'transactions':[]}
  accountResults = dynamo.scan(TableName='budgies-budgets-accounts')['Items']
  for item in accountResults:
    returnData['accounts'].append({
      'user': item['user']['S'],
      'name': item['name']['S'],
      'balance': float(item['balance']['N']),
      'isGiftcard': item['isGiftcard']['BOOL']
    })
  # Then the transactions
  transactionResults = dynamo.scan(TableName='budgies-budgets-transactions', 
                                   FilterExpression="#d BETWEEN :start AND :end",
                                   ExpressionAttributeNames={"#d": "date"},
                                   ExpressionAttributeValues={":start":{"S": start}, ":end":{"S": end}},
                                   )['Items']
  for item in transactionResults:
    returnData['transactions'].append({
      'guid': item['guid']['S'],
      'date': item['date']['S'],
      'category': item['category']['S'],
      'account': item['account']['S'],
      'amount': float(item['amount']['N']),
      'user': item['user']['S'],
      'memo': item['memo']['S'],
      'hasMemoImage': item['hasMemoImage']['BOOL']
    })
  # Return the compressed string
  return compressString(json.dumps(returnData))

def lambda_handler(event, context):
  method = event.get('requestContext', {'NONE'}).get('http', {'method': 'NONE'}).get('method', 'NONE')
  path = event.get('rawPath', 'NONE')
  parameters = event.get('queryStringParameters', 'NONE')
  headers = event.get('headers', 'NONE')
  body = event.get('body', 'NONE')
  
  # Step 1: Validate the request has the API key and is correct
  if headers.get('apikey', 'NONE') != apiKey:
    return {
      'statusCode': 401,
      'body': json.dumps('Unauthorized')
    }
  # If that passed then start looking for a matching path and method
  if path == "/getAllFinancialData" and method == "GET":
    return {
      'statusCode': 200,
      'body': getAllFinancialData(parameters['startDate'], parameters['endDate'])
    }
  return {
    'statusCode': 501,
    'body': json.dumps('Not Routed')
  }