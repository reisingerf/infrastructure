import json
import boto3
import base64
import paramiko
from botocore.exceptions import ClientError
from io import StringIO


def get_secret(secret_name, aws_region="ap-southeast-2"):
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=aws_region
    )

    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        # TODO: handle errors better
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        else:
            # Anything else
            raise e

    # Decrypts secret using the associated KMS CMK.
    # Depending on whether the secret is a string or binary, one of these fields will be populated.
    if 'SecretString' in get_secret_value_response:
        secret = get_secret_value_response['SecretString']
    else:
        secret = base64.b64decode(get_secret_value_response['SecretBinary'])
        raise ValueError('Got binary where secret string was expected!')

    return secret


def execute_remote_command(remote_command,
                           ssh_key,
                           dest_host,
                           dest_host_user,
                           dest_host_port=22,
                           jump_host=None,
                           jump_host_user=None,
                           jump_host_port=22):
    # try to call the external pipeline script

    success = False
    try:
        # Call remote pipeline script
        # TODO: check if a jump host is needed and configure accordingly
        # See: https://stackoverflow.com/questions/50977380/python-3-paramiko-ssh-agent-forward-over-jump-host-with-remote-command-on-third

        if jump_host:
            jumpHost = paramiko.SSHClient()
            sshKey = paramiko.RSAKey.from_private_key(StringIO(ssh_key))
            jumpHost.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            print("Connecting to jump host {} as {}".format(jump_host, jump_host_user))
            jumpHost.connect(hostname=jump_host, username=jump_host_user, pkey=sshKey)
            print("Connection established")
            jumpHostTransport = jumpHost.get_transport()
            dest_addr = (dest_host, int(dest_host_port))
            local_addr = (jump_host, int(jump_host_port))
            print("Open transport channel")
            jumpHostChannel = jumpHostTransport.open_channel("direct-tcpip", dest_addr, local_addr)

        destHost = paramiko.SSHClient()
        destHost.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        if jump_host:
            print("Connecting to dest host {} as {} via socket {}".format(dest_host, dest_host_user, jumpHostChannel))
            destHost.connect(hostname=dest_host, username=dest_host_user, sock=jumpHostChannel, pkey=sshKey)
        else:
            print("Connecting to dest host {} as {} via port {}".format(dest_host, dest_host_user, dest_host_port))
            destHost.connect(hostname=dest_host, username=dest_host_user, port=dest_host_port, pkey=sshKey)

        print("Get session")
        destHostAgentSession = destHost.get_transport().open_session()
        paramiko.agent.AgentRequestHandler(destHostAgentSession)
        print("Connection and session established to dest host. Executing command...")

        ssh_stdin, ssh_stderr, ssh_stdout = destHost.exec_command(remote_command)
        print("Command executed. Reading output from stdout/stderr.")
        print(ssh_stdout.read())
        print(ssh_stderr.read())

        print("Reading exit status...")
        exit_status = ssh_stdout.channel.recv_exit_status()
        print("exit status: {}".format(exit_status))
        if exit_status is 0:
            success = True

    except Exception as e:
        print(e)
        raise e

    return success


def call_slack_lambda(function_name, topic, title, message):
    slack_lambda = boto3.client('lambda')

    payload = {}
    payload['topic'] = topic
    payload['title'] = title
    payload['message'] = message

    try:
        response = slack_lambda.invoke(
            FunctionName=function_name,
            InvocationType="RequestResponse",
            Payload=json.dumps(payload)
        )
    except Exception as e:
        print(e)
        raise e
    print(response)

