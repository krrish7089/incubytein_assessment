class SpaController < ApplicationController
  def index
    path = Rails.root.join("public/index.html")
    if path.file?
      render body: path.read, content_type: "text/html; charset=utf-8"
    else
      render :missing
    end
  end
end
