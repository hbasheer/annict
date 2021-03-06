# frozen_string_literal: true

class WorkRecordsController < ApplicationController
  permits :body, :rating_animation_state, :rating_music_state, :rating_story_state,
          :rating_character_state, :rating_overall_state

  before_action :authenticate_user!, only: %i(create edit update destroy)

  def index(work_id, page: nil)
    @work = Work.published.find(work_id)
    load_work_records

    return unless user_signed_in?

    @work_record = @work.work_records.new

    store_page_params(work: @work)
  end

  def create(work_id, work_record, page: nil)
    @work = Work.published.find(work_id)
    @work_record = @work.work_records.new(work_record)
    @work_record.user = current_user
    current_user.setting.attributes = setting_params
    ga_client.page_category = params[:page_category]
    keen_client.page_category = params[:page_category]
    logentries.page_category = params[:page_category]

    service = NewWorkRecordService.new(current_user, @work_record, current_user.setting)
    service.ga_client = ga_client
    service.keen_client = keen_client
    service.logentries = logentries
    service.page_category = params[:page_category]
    service.via = "web"

    begin
      service.save!
      flash[:notice] = t("messages._common.post")
      redirect_to work_records_path(@work)
    rescue
      load_work_records

      store_page_params(work: @work)

      render "work_records/index"
    end
  end

  def edit(work_id, id)
    @record = current_user.records.find(id)
    @work_record = current_user.work_records.published.where(work_id: work_id).find(@record.work_record&.id)
    @work = @work_record.work
    authorize @work_record, :edit?
    store_page_params(work: @work)
  end

  def update(work_id, id, work_record)
    @record = current_user.records.find(id)
    @work_record = current_user.work_records.published.where(work_id: work_id).find(@record.work_record&.id)
    @work = @work_record.work
    authorize @work_record, :update?

    @work_record.attributes = work_record
    @work_record.detect_locale!(:body)
    @work_record.modified_at = Time.now
    current_user.setting.attributes = setting_params

    begin
      ActiveRecord::Base.transaction do
        @work_record.save!
        current_user.setting.save!
      end
      if current_user.setting.share_review_to_twitter?
        ShareWorkRecordToTwitterJob.perform_later(current_user.id, @work_record.id)
      end
      flash[:notice] = t("messages._common.updated")
      redirect_to record_path(@work_record.user.username, @work_record.record)
    rescue
      store_page_params(work: @work)
      render :edit
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:share_review_to_twitter, :share_review_to_facebook)
  end

  def load_work_records
    @work_records = @work.
      work_records.
      published.
      with_body.
      includes(user: :profile).
      merge(User.published)
    @work_records = localable_resources(@work_records)

    if user_signed_in?
      @my_work_records = current_user.work_records.published.where(work: @work).includes(user: :profile).order(created_at: :desc)
      @work_records = @work_records.
        where.not(user: current_user).
        where.not(user_id: current_user.mute_users.pluck(:muted_user_id))
    end

    @work_records = @work_records.order(created_at: :desc).page(params[:page])
    @is_spoiler = user_signed_in? && @work_records.present? && current_user.hide_work_record_body?(@work_records.first.work)
  end
end
