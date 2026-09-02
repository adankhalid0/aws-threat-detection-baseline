module "guardduty" {
  source = "../../modules/guardduty"
  tags   = { Project = "aws-threat-detection-baseline" }
}

module "security_hub" {
  source = "../../modules/security-hub"
  region = var.region
}

module "alerting" {
  source      = "../../modules/alerting"
  name_prefix = "cloud-threat-detection"
  alert_email = var.alert_email
}
