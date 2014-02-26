class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         :omniauth_providers => [:facebook]
  # create urls based on nickname
  #friendly_id :nickname, use: :slugged

  has_many :authentications, class_name: 'UserAuthentication'
  has_many :stations, inverse_of: :user

  validates_uniqueness_of :nickname

  # Use FriendlyId to create "pretty urls"
  extend FriendlyId
  friendly_id :nickname, :use => [:slugged]

  def self.create_from_omniauth(params)
    info = params[:info]
    create do |user|
        user.email    = info[:email]
        user.image    = info[:image]
        user.nickname = info[:nickname]
        user.password = Devise.friendly_token
    end
  end

  def update_from_omniauth(params)
    if params[:info].key?(:image)
      @image = params[:info][:image]
    end
  end

  def should_generate_new_friendly_id?
    if !slug?
      nickname_changed?
    else
      false
    end
  end

end
