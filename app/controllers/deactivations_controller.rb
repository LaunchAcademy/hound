class DeactivationsController < ApplicationController
  class FailedToActivate < StandardError; end
  class CannotDeactivatePrivateRepo < StandardError; end

  respond_to :json

  before_action :check_privacy

  def create
    if activator.deactivate(repo, session[:github_token])
      analytics.track_deactivated(repo)
      render json: repo, status: :created
    else
      report_exception(
        FailedToActivate.new('Failed to deactivate repo'),
        user_id: current_user.id, repo_id: params[:repo_id]
      )
      head 502
    end
  end

  private

  def repo
    @repo ||= current_user.repos.find(params[:repo_id])
  end

  def activator
    RepoActivator.new
  end

  def check_privacy
    raise CannotDeactivatePrivateRepo if repo.private?
  end
end
