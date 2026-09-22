import os
import json
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, float):
            return str(obj)
        if hasattr(obj, 'as_tuple'):
            return str(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    table_name = os.environ.get('DYNAMODB_TABLE_NAME')
    if not table_name:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'DYNAMODB_TABLE_NAME is missing'})
        }
        
    table = dynamodb.Table(table_name)
    
    # API Gateway REST API event structure
    query_params = event.get('queryStringParameters') or {}
    user_id = query_params.get('user_id')
    
    try:
        if user_id:
            # Query specific user
            response = table.query(
                KeyConditionExpression=Key('pk').eq(f"USER#{user_id}") & Key('sk').begins_with("TXN#")
            )
            items = response.get('Items', [])
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'total_count': len(items),
                    'user_id': user_id,
                    'transactions': items
                }, cls=DecimalEncoder)
            }
        else:
            # Global scan for total count
            response = table.scan(Select='COUNT')
            total_count = response.get('Count', 0)
            
            # Handle pagination for full count (simple approach)
            while 'LastEvaluatedKey' in response:
                response = table.scan(Select='COUNT', ExclusiveStartKey=response['LastEvaluatedKey'])
                total_count += response.get('Count', 0)
                
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'total_transactions_in_table': total_count
                })
            }
            
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
