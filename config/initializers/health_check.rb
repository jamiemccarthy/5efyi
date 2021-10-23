HealthCheck.setup do |config|
  config.standard_checks -= ["migrations"]
  config.origin_ip_whitelist = ""
  # config.include_error_in_response_body = true # TODO once health_check gem makes this an option, post-3.0.0
end
