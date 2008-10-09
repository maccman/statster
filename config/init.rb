$KCODE = 'UTF8'

# Move this to application.rb if you want it to be reloadable in dev mode.
Merb::Router.prepare do |r|
  r.match('/').to(:controller => 'stats', :action => 'record')
  r.match('/stats.js').to(:controller => 'stats', :action => 'stats_file')
  r.default_routes
end

Merb::Config.use { |c|
  c[:environment]         = 'production',
  c[:framework]           = {},
  c[:log_level]           = :debug,
  c[:use_mutex]           = false,
  c[:session_store]       = 'none',
  c[:exception_details]   = false,
  c[:reload_classes]      = false,
  c[:reload_time]         = 0.5
}


$:.unshift(File.join(Merb.root, 'lib'))

require 'string_ext'
require 'time_ext'
require 'array_ext'

require 'builder'

require 'app_config'
AppConfig.load

require 'stat'