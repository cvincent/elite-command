namespace :jammit do
  desc "Bundle assets."
  task :bundle_assets do
    require 'jammit'
    Jammit.package!
  end
end
