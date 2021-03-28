module "sns_topic_for_alerting" {
  source = "../../../modules/sns-topic"
  topic_name = "alerts-for-wordpress"
}