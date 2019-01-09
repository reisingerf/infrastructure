deploy_env = "dev"

notify_slack_lambda_function_name = "bootstrap_slack_lambda_dev"

################################################################################
# SSH parameter

dest_host = "novastor01.mdhs.unimelb.edu.au"

dest_host_port = "4321"

dest_host_user = "limsadmin"

jump_host = "spartan.hpc.unimelb.edu.au"

jump_host_port = "22"

jump_host_user = "freisinger"

################################################################################
# Script paths for scripts of the pipeline

check_samplesheet_script_path = "/opt/Pipeline/dev/scripts/aws_pipeline_test.sh"

start_bcl2fastq_script_path = "/opt/Pipeline/dev/scripts/aws_pipeline_test.sh"
