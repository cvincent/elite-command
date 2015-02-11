Mongoid.logger = nil

module MongoidIdentityMap
  MapHash = {}

  def find_by_identity(id)
    MapHash[self.name.to_s + ':' + id.to_s] ||= self.find(id)
  end
end
