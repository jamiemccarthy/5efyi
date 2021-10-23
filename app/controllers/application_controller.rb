class ApplicationController < ActionController::Base
  def srd_dir
    if !@srd_dir
      @srd_dir = File.join(Rails.public_path, "srd").freeze
      FileUtils.mkdir_p srd_dir
    end
    @srd_dir
  end

  def srd_page_files
    @srd_page_files ||= Dir.new(srd_dir).each_child.sort.freeze
  end

  def ogl?
    false
  end
end
