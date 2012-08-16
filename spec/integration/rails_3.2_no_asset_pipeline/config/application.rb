require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module Rails32NoAssetPipeline
  class Application < Rails::Application
    config.assets.enabled = false
  end
end
