# frozen_string_literal: true
# == Schema Information
#
# Table name: gumroad_subscribers
#
#  id                                     :bigint(8)        not null, primary key
#  gumroad_id                             :string           not null
#  gumroad_product_id                     :string           not null
#  gumroad_product_name                   :string           not null
#  gumroad_user_id                        :string           not null
#  gumroad_user_email                     :string           not null
#  gumroad_purchase_ids                   :string           not null, is an Array
#  gumroad_created_at                     :datetime         not null
#  gumroad_cancelled_at                   :datetime
#  gumroad_user_requested_cancellation_at :datetime
#  gumroad_charge_occurrence_count        :datetime
#  gumroad_ended_at                       :datetime
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#
# Indexes
#
#  index_gumroad_subscribers_on_gumroad_id          (gumroad_id) UNIQUE
#  index_gumroad_subscribers_on_gumroad_product_id  (gumroad_product_id)
#  index_gumroad_subscribers_on_gumroad_user_id     (gumroad_user_id)
#

class GumroadSubscriber < ApplicationRecord
  validates :gumroad_id, presence: true
  validates :gumroad_product_id, presence: true
end
