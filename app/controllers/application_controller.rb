class ApplicationController < ActionController::Base
  mattr_accessor :srd_dir, :srd_page_files, instance_writer: false

  @@srd_dir = File.join(Rails.public_path, "srd").freeze
  FileUtils.mkdir_p @@srd_dir
  @@srd_page_files = Dir.new(srd_dir).each_child.sort.freeze

  def is_ogl?
    false
  end
end
