class OglContentController < ApplicationController
  mattr_accessor :ogl_file, default: {}

  FILENAME_REGEX = Regexp.new("\\A[a-z-]+\\z").freeze

  def show
    filename = ogl_content_params["ogl_name"]
    return :not_found unless filename.match? FILENAME_REGEX

    ogl_file[filename] ||= File.read(File.join(Rails.public_dir, "srd", filename))

    render file_contents: ogl_file[filename]
  end

  def ogl_content_params
    params.require(:ogl_name)
  end
end
