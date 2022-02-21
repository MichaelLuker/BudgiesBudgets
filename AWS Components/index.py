import boto3
import base64
import gzip
import json

accountTable='budgies-budgets-accounts'
transactionTable='budgies-budgets-transactions'
imageBucket='budgies-budgets-images-something blah blah blah'

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
  accountResults = dynamo.scan(TableName=accountTable)['Items']
  for item in accountResults:
    returnData['accounts'].append({
      'user': item['user']['S'],
      'name': item['name']['S'],
      'balance': float(item['balance']['N']),
      'isGiftcard': item['isGiftcard']['BOOL']
    })
  # Then the transactions in the date range
  transactionResults = dynamo.scan(TableName=transactionTable, 
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

def writeNewTransaction(transaction):
  dynamo.put_item(TableName=transactionTable, Item={
    'guid':{'S': transaction['guid']},
    'user':{'S': transaction['user']},
    'hasMemoImage':{'BOOL': transaction['hasMemoImage']},
    'date':{'S': transaction['date']},
    'account':{'S': transaction['account']},
    'category':{'S': transaction['category']},
    'amount':{'N': str(transaction['amount'])},
    'memo':{'S': transaction['memo']},
  })

def deleteTransaction(transaction):
  dynamo.delete_item(TableName=transactionTable, Key={
    'guid':{'S': transaction['guid']}, 
    'user':{'S': transaction['user']}
  })

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
  if path == "/writeNewTransaction" and method == "POST":
    return {
      'statusCode': 200,
      'body': writeNewTransaction(decompressRequest(body))
    }
  if path == "/deleteTransaction" and method == "POST":
    return {
      'statusCode': 200,
      'body': deleteTransaction(decompressRequest(body))
    }
  return {
    'statusCode': 501,
    'body': json.dumps('Not Routed')
  }