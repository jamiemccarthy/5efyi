require 'byebug'
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      bytes: event.payload[:response].body.bytesize,
      cpu_time: event.cpu_time,
      time: Time.now.strftime("%FT%T")
    }
  end
end
