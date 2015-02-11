module JavascriptsHelper
  def dynamic_javascript_path(path)
    realpath = path.gsub('/dynamic_javascripts', 'app/views/javascripts') + '.erb'
    asset_id = File.mtime(realpath).to_i.to_s
    path + '?' + asset_id
  end
end
