# frozen_string_literal: true
class NotificationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :render_home_page_unless_authenticated, only: [:index]
  before_action :find_notification, only: [:archive, :unarchive, :star]

  def index
    scope = current_user.notifications
    scope = params[:archive].present? ? scope.archived : scope.inbox

    @types               = scope.distinct.group(:subject_type).count
    @statuses            = scope.distinct.group(:unread).count
    @reasons             = scope.distinct.group(:reason).count
    @unread_repositories = scope.distinct.group(:repository_full_name).count
    @starred             = scope.starred.count

    scope = scope.repo(params[:repo])     if params[:repo].present?
    scope = scope.reason(params[:reason]) if params[:reason].present?
    scope = scope.type(params[:type])     if params[:type].present?
    scope = scope.status(params[:status]) if params[:status].present?
    scope = scope.starred                 if params[:starred].present?

    @notifications = scope.newest.page(params[:page])
  end

  def archive
    @notification.update_columns archived: true
    redirect_to root_path(type: params[:type], repo: params[:repo])
  end

  def archive_all
    scope = current_user.notifications.inbox

    scope = scope.repo(archive_params[:repo])     if archive_params[:repo].present?
    scope = scope.reason(archive_params[:reason]) if archive_params[:reason].present?
    scope = scope.type(archive_params[:type])     if archive_params[:type].present?
    scope = scope.status(archive_params[:status]) if archive_params[:status].present?
    scope = scope.starred                         if archive_params[:starred].present?

    scope.update_all(archived: true)
    redirect_to root_path
  end

  def unarchive
    @notification.update_columns archived: false
    redirect_to root_path(type: params[:type], repo: params[:repo], archive: true)
  end

  def star
    @notification.update_columns starred: !@notification.starred?
    head :ok
  end

  def sync
    current_user.sync_notifications
    redirect_to root_path(type: params[:type], repo: params[:repo])
  end

  private

  def find_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def render_home_page_unless_authenticated
    return render 'pages/home' unless logged_in?
  end

  def archive_params
    params.permit(:repo, :reason, :type, :status, :starred)
  end
end
