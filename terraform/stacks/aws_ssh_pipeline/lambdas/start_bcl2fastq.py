import os
import json
import aws_pipeline_commons

lambda_env = os.environ.get("LAMBDA_ENV")
slack_lamdba_function_name = os.environ.get("SLACK_LAMBDA_NAME")
env_jump_host = os.environ.get("JUMP_HOST")
env_jump_host_port = os.environ.get("JUMP_HOST_PORT")
env_jump_host_user = os.environ.get("JUMP_HOST_USER")
env_dest_host = os.environ.get("DEST_HOST")
env_dest_host_port = os.environ.get("DEST_HOST_PORT")
env_dest_host_user = os.environ.get("DEST_HOST_USER")
script_path = os.environ.get("SCRIPT_PATH")


def build_remote_command(event, script_path, env="dev"):
    if event.get('parameters'):
        parameters = event['parameters']
    else:
        parameters = ""

    return "DEPLOY_ENV={} {} {}".format(env, script_path, parameters)


def lambda_handler(event, context):
    print("Received event: {}".format(json.dumps(event, indent=2)))

    if event.get('runfolder'):
        runfolder = event['runfolder']
        print("Handling bcl2fastq for {}".format(runfolder))
    else:
        raise ValueError('A runfolder name is mandatory!')
    
    print("Building remote command...")
    remote_command = build_remote_command(event=event,
                                          script_path=script_path,
                                          env=lambda_env)
    print("Remote command built: {}".format(remote_command))

    print("Calling external script, via SSH...")
    ssh_key = aws_pipeline_commons.get_secret("dev/aws_pipeline/novastor")
    print(ssh_key[:35])
    print(ssh_key[-35:])

    print("Executing remote command...")
    success = aws_pipeline_commons.execute_remote_command(remote_command=remote_command,
                                                          ssh_key=ssh_key,
                                                          dest_host=env_dest_host,
                                                          dest_host_user=env_dest_host_user,
                                                          dest_host_port=env_dest_host_port,
                                                          jump_host=env_jump_host,
                                                          jump_host_user=env_jump_host_user,
                                                          jump_host_port=env_jump_host_port)
    print("Remote command executed.")

    print("Sending Slack message...")
    if success:
        print("Successfully executed remote command.")
        # aws_pipeline_commons.call_slack_lambda(function_name=slack_lamdba_function_name,
        #                                        topic="Run: {}".format(runfolder),
        #                                        title="Start bcl2fastq",
        #                                        message="Successfully started bcl2fastq.")
    else:
        print("Failed to execute remote command.")
        # aws_pipeline_commons.call_slack_lambda(function_name=slack_lamdba_function_name,
        #                                        topic="Run: {}".format(runfolder),
        #                                        title="Start bcl2fastq",
        #                                        message="Failed to start bcl2fastq.")
    print("Slack message sent. All done.")
