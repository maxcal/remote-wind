# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default("")
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  image                  :string(255)
#  nickname               :string(255)
#  slug                   :string(255)
#  timezone               :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  invitation_token       :string(255)
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  invitations_count      :integer          default(0)
#

# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do

  factory :user do
    nickname 'j_random_user'
    email 'example@example.com'
    password 'changeme'
    password_confirmation 'changeme'
    # required if the Devise Confirmable module is used
    confirmed_at Time.now
  end

  factory :unconfirmed_user, class: User do
    nickname 'j_random_user'
    email 'example@example.com'
    password 'changeme'
    password_confirmation 'changeme'
  end

  factory :admin, class: User  do
    nickname 'the_boss'
    email "admin@example.com"
    password "abc123123"
    password_confirmation { "abc123123" }
    after(:create) do |admin|
      admin.add_role(:admin)
    end
    confirmed_at Time.now
  end

end

