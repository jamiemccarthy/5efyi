Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      bytes: event.payload[:response].body.bytesize,
      cpu_time: event.cpu_time,
      time: Time.now.strftime("%FT%T")
    }
  end
  config.lograge.ignore_custom = lambda do |event|
    # Only log 1/1000th of health checks
    event.payload[:controller] == "HealthCheck::HealthCheckController" && rand >= 0.001
  end
end
