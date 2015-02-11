require 'digest/md5'

class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  field :from_user_id, type: String
  field :to_user_id, type: String
  field :message, type: String
  field :thread_identifier, type: String
  field :unread, type: Boolean, default: true

  scope :to_user, lambda { |u| where(to_user_id: u.id.to_s) }
  scope :from_user, lambda { |u| where(from_user_id: u.id.to_s) }
  scope :visible_to_user, lambda { |u|
    any_of({ to_user_id: u.id.to_s }, { from_user_id: u.id.to_s })
  }

  validates_presence_of :from_user_id
  validates_presence_of :to_user_id
  validates_presence_of :message

  before_create :generate_thread_identifier

  def self.latest_threads_for_user(user)
    thread_ids = Message.visible_to_user(user).distinct(:thread_identifier)
    thread_ids.map do |thread_id|
      Message.where(thread_identifier: thread_id).desc(:created_at).first
    end.sort_by(&:created_at).reverse
  end

  def self.latest_unread_threads_for_user(user)
    thread_ids = Message.to_user(user).where(unread: true).distinct(:thread_identifier)
    thread_ids.map do |thread_id|
      Message.where(thread_identifier: thread_id).desc(:created_at).first
    end
  end

  def sender
    @sender ||= User.find(self.from_user_id) rescue nil
  end

  def receiver
    @receiver ||= User.find(self.to_user_id) rescue nil
  end

  def other_user(user)
    user == self.sender ? self.receiver : self.sender
  end

  def show_as_unread?(user)
    user == self.receiver and self.unread
  end

  protected

  def generate_thread_identifier
    self.thread_identifier = Digest::MD5.hexdigest([self.to_user_id, self.from_user_id].sort.join('-'))
  end
end
