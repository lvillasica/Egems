class BranchesController < ApplicationController

  respond_to :json
  before_filter :authenticate_user!

  def index
    branches = Branch.all
    respond_to do |format|
      format.html { render :template => "layouts/application" }
      format.json { render :json => branches.to_json }
    end
  end
end
