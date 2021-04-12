require "test_helper"

class OglContentControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get ogl_content_show_url
    assert_response :success
  end
end
