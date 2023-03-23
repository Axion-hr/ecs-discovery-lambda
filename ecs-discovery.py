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


def generateHttpSdResponse():
    ssm_client = boto3.client('ssm')
    stage = ssm_client.get_parameter(Name='/deployment/stage')['Parameter']['Value']
    cluster_name="logpay-dev"
    services = discoverTargets()
    response = {
        "targets": services,
        "labels": {
            "stage": stage
        }
    }
    return json.dumps(response), 200, {'Content-Type': 'application/json'}



def lambda_handler(event, context):
    print('## EVENT')
    print(event)
    print('## CONTEXT')
    print(context)
    return generateHttpSdResponse()
    
    

