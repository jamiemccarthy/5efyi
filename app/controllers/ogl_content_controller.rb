class OglContentController < ApplicationController
  mattr_accessor :ogl_file, default: {}

  def show
    filename = ogl_content_params["ogl_name"]
    # read file into @@ogl_file hash, render
  end

  def ogl_content_params
    params.require(:ogl_name)
  end
end
