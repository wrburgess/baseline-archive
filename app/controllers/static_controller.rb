class StaticController < ApplicationController
  include ApplicationHelper

  layout "application"

  # v0 is captain-only — no unauthenticated surfaces. Everything, including
  # the landing page, routes through Devise first.
  before_action :authenticate_user!

  def index; end
end
