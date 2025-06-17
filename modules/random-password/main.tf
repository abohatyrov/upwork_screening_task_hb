resource "random_password" "password" {
  length           = 16
  special          = true
  min_special      = 2
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
