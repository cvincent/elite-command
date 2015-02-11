unless Rails.env == 'test'
  # Force all Achievement classes to load
  Dir.glob(File.join(Rails.root, 'app', 'achievements', '*.rb')).each do |f|
    require File.basename(f).gsub('.rb', '')
  end

  ActiveSupport::Notifications.subscribe /^ec\./ do |name, start, finish, id, payload|
    name = name.split('.').last.to_sym

    Achievement.achievements.each do |a|
      if a.triggered_on?(name)
        a.enqueue_check!(payload)
      end
    end
  end
end
