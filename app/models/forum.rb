class Forum
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :description, :type => String
  field :position, :type => Integer, :default => 99
  
  def topics
    @topic ||= Topic.where(:forum_id => self._id.to_s).desc(:updated_at)
  end
end
