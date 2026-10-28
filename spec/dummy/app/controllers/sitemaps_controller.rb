class SitemapsController < ActionController::Base
  class_attribute :body, default: ""
  class_attribute :answer_status, default: 200
  class_attribute :last_request

  def show
    self.class.last_request = request
    render plain: body, status: answer_status, content_type: "application/xml"
  end
end
