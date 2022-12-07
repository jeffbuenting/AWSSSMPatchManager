# create key pair for the instances.  then export the private key to a local file for use later.data" "name"   
# https://stackoverflow.com/questions/67389324/create-a-key-pair-and-download-the-pem-file-with-terraform-aws
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "InstanceKey"
  public_key = tls_private_key.pk.public_key_openssh

  # provisioner "local-exec" {
  #   command = "echo '${tls_private_key.pk.private_key_pem}' > ${path.module}/InstanceKey.pem"
  # }

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "rm -f ${path.module}/InstanceKey.pem"
  # }
}
