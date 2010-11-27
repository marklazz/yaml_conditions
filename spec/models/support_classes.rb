class NotificationMailer
    def self.deliver_admin_login; end
end # define this for test purposes

class SimpleJob
  attr_accessor :name, :kind
  def perform; end

  def related_user
    User.first
  end
end
