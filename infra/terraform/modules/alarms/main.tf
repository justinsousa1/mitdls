terraform {
  required_version = ">= 0.12, < 0.14"
}

// take as input the sns topic created to be notified
// this is just an example of a metric alarm using cloudwatch metrics from the
// ALB/target groups created. I've been relying mostly on Datadog for alerting but cloudwatch is also
// relatively easy to work with.

resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name                = "${local.app_name}-example-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  threshold                 = "10"
  alarm_description         = "Request error rate has exceeded 10%"
  actions_enabled     = true
  alarm_actions       = [var.alert_sns_topic_arn]
  ok_actions          = [var.alert_sns_topic_arn]
  insufficient_data_actions = [var.alert_sns_topic_arn]

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "120"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = var.load_balancer_arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "HTTPCode_ELB_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "120"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        LoadBalancer = var.load_balancer_arn_suffix
      }
    }
  }
}
