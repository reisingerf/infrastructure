output "check_samplesheet_lambda_function_invoke_arn" {
  description = "The ARN of the Lambda function"
  value       = "${module.check_samplesheet_lambda.function_invoke_arn}"
}

output "bcl2fastq_lambda_function_invoke_arn" {
  description = "The ARN of the Lambda function"
  value       = "${module.bcl2fastq_lambda.function_invoke_arn}"
}
