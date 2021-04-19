class OglContentController < ApplicationController
  mattr_accessor :ogl_file, default: {}

  FILENAME_REGEX = Regexp.new("\\A[a-z-]+\\z").freeze

  def ogl_content_params
    p = params.permit(:ogl_name)
    if p["ogl_name"] && !p["ogl_name"].match?(FILENAME_REGEX)
      raise Sprockets::FileNotFound, "unknown filename" # TODO this throws a 500, is there some non-ActiveRecord way to throw a 404?
      # p.delete("ogl_name")
    end
    p
  end

  def ogl_name_abspath
    Rails.public_path.join("srd", ogl_content_params["ogl_name"])
  end
end
