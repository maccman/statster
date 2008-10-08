require 'yaml'
require 'erb'
class AppConfig  
  def self.load
    path = File.join(Merb.root, "config", "config.yml")

    if File.exists?(path)
      config = YAML.load(ERB.new(File.read(path)).result)[Merb.env.to_sym]

      config.keys.each do |key|
        cattr_accessor key
        send("#{key}=", config[key])
      end
    end
  end
end