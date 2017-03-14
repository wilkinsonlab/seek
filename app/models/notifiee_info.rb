require 'uuid'

class NotifieeInfo < ActiveRecord::Base
  belongs_to :notifiee, polymorphic: true
  validates_presence_of :notifiee

  before_save :check_unique_key

  private

  def check_unique_key
    self.unique_key = UUID.generate if unique_key.nil? || unique_key.blank?
  end
end
