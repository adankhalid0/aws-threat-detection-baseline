output "account_id" {
  description = "Security Hub account subscription ID."
  value       = aws_securityhub_account.this.id
}
