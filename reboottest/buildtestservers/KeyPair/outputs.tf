output "kp_name" {
  description = "Name of the new keypair."
  value       = aws_key_pair.kp.key_name
}
