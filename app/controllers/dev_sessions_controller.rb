# frozen_string_literal: true

# Developer sign-in (the kit's Developer Sign-In): in development and
# test, Sign In comes here instead of single sign-on. Pick a test account from
# config/test_accounts.yml and go back to the page you were on. The routes
# are drawn only there, and this refuses everywhere else too.
class DevSessionsController < ApplicationController
  before_action { head :not_found unless DemoMode.on? }
  layout 'cmu/sign_in'

  def new
    @accounts = TestAccount.all
    @return_to = safe_return_to(params[:return_to].presence || request.referer)
  end

  def create
    account = TestAccount.find(params[:andrew_id])
    return head(:not_found) unless account

    sign_in_participant(account.participant)
    redirect_to safe_return_to(params[:return_to]) || root_path
  end
end
