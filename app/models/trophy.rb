class Trophy
  include Mongoid::Document

  field :user_id, :type => String
  field :defeated_user_id, :type => String
  field :defeated_username, :type => String

  def self.grant!(user, defeated_user)
    upsert = {
      user_id: user.id.to_s, defeated_user_id: defeated_user.id.to_s,
      defeated_username: defeated_user.username
    }

    Trophy.collection.master.collection.update(
      upsert, upsert, upsert: true
    )
  end
end
