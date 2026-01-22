locals {
  compartment_name   = "sandbox"
  instance_shape     = "VM.Standard.A1.Flex"
  instance_ocpus     = 4
  instance_memory    = 24
  mysql_shape        = "MySQL.Free"
  mysql_storage      = 50
  mysql_display_name = "mysql-db"
  bastion_name       = "bastion"
}
