import json
import boto3

def discoverTargets():
    client = boto3.client('ecs')
    res = []    
    cluster_name = [x.split('/')[-1] for x in client.list_clusters()['clusterArns'] if 'logpay' in x][0]
    tasks = client.list_tasks(cluster=cluster_name)
    taskIds = [x.split('/')[-1] for x in tasks['taskArns']]
    for task_desc in client.describe_tasks(cluster=cluster_name, tasks=taskIds)['tasks']:
        attachments = task_desc['attachments']   
        taskIp = [x for x in attachments[0]['details'] if x['name'] == 'privateIPv4Address'][0]['value']
        taskDefinition = client.describe_task_definition(taskDefinition=task_desc['taskDefinitionArn'])['taskDefinition']
        for containerDefintion in taskDefinition['containerDefinitions']:
            for portMapping in containerDefintion['portMappings']:
                res.append(f"{taskIp}:{portMapping['hostPort']}")
    return res

def discoverTargets2(stage):
    client = boto3.client('servicediscovery')
    instances = []
    response = client.list_namespaces(Filters=[{'Name': 'NAME', 'Values': ['logpay'], 'Condition': 'EQ'}])
    namespace_id = response['Namespaces'][0]['Id']
    response = client.list_services( Filters=[{'Name': 'NAMESPACE_ID', 'Values': [namespace_id], 'Condition': 'EQ' }])
    res = []
    for service in response['Services']:
        srv_id = service['Id']
        instances = client.list_instances(ServiceId=srv_id)['Instances']
        targets = []
        labels = {'service_name' : service['Name'], 'stage' : stage}
        for instance in instances:
            ip = instance['Attributes']['AWS_INSTANCE_IPV4']
            port = instance['Attributes']['AWS_INSTANCE_PORT']
            targets.append(f"{ip}:{port}")
            labels['cluster'] = instance['Attributes']["ECS_CLUSTER_NAME"]
        res.append({'targets' : targets, "labels" : labels})
    return(res)

def wrap_response_body(statusCode, body, headers=None, statusDescription=None):
    response = { "statusCode": 200, "isBase64Encoded": False, "headers": {
        "Content-Type": "application/json"}, "body" : body}
    if (statusDescription is not None):
        response['statusDescription'] = statusDescription
    if (headers is not None):
        response['headers'].update(headers)
    return response
    
def generateHttpSdResponse():
    ssm_client = boto3.client('ssm')
    stage = ssm_client.get_parameter(Name='/deployment/stage')['Parameter']['Value']
    response  = discoverTargets2(stage)    
    return wrap_response_body(200, json.dumps(response))

def handle_healthcheck():
    return wrap_response_body(200, '{"healthy" : true }')

def lambda_handler(event, context):
    if event['path'] == "/healthcheck":
        return handle_healthcheck()
    else:
        return generateHttpSdResponse()
#    print('## EVENT')
#    print(event)
#    print('## CONTEXT')
#    print(context)

 
print(generateHttpSdResponse())

