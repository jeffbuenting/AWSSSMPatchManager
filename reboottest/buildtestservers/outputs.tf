output "password" {
  description = "Local Admin Password"
  value = [
    for g in aws_instance.unica_servers : rsadecrypt(g.password_data, file("C:/Users/kwbre/Downloads/InstanceKey.pem"))
  ]

}
