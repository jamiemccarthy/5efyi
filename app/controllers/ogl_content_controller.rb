class OglContentController < ApplicationController
  mattr_accessor :ogl_file, default: {}

  FILENAME_REGEX = Regexp.new("[a-z0-9-]+").freeze
  FILENAME_REGEX_ANCHORED = Regexp.new("\\A[a-z0-9-]+\\z").freeze

  def show
    render status: :not_found, html: "Not found" unless ogl_file_abspath
  end

  def is_ogl?
    true
  end

  def ogl_content
    filename = ogl_file_abspath
    filename ? File.read(filename) : nil
  end

  def ogl_file_abspath
    ogl_name = ogl_content_params["ogl_name"]
    ogl_file_abspath = ogl_name ? Rails.public_path.join("srd", ogl_name) : nil
    (ogl_file_abspath && File.exists?(ogl_file_abspath)) ? ogl_file_abspath : nil
  end

  def ogl_content_params
    p = params.permit(:ogl_name)
    # This shouldn't be necessary due to a routing constraint, but just in case.
    p.delete("ogl_name") if p["ogl_name"] && !p["ogl_name"].match?(FILENAME_REGEX_ANCHORED)
    p
  end
end
