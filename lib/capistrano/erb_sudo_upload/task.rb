require 'capistrano/erb_sudo_upload/core'
require 'capistrano/erb_sudo_upload/util'
require 'capistrano/switchuser'
module Capistrano
  module ErbSudoUpload
    def self.load_into(configuration)
      configuration.load do
        namespace :erb_sudo_upload do
          config_path = fetch(:erb_sudo_upload_config, "config/erb_sudo_upload.yml")
          yaml = YAML.load(ERB.new(File.read(config_path)).result(binding))
          set_vars(yaml['vars'])
          yaml['settings'].each do |key, setting|
            role_map = Util.get_role_map(setting)

            method_names = []
            namespace key do
              task "default", except: {no_release: true} do
                puts "#{key} deploy start"
              end
              role_map.each do |role_name, files|
                method_names << role_name
                option = role_name == 'all' ? { except: {no_release: true} } : { roles: role_name, except: {no_release: true} }
                task(role_name, option) do
                  sudo_upload_with_files(key, files, setting)
                end
              end
            end
            task_names = method_names.map{ |role_name| "erb_sudo_upload:#{key}:#{role_name}"}
            after *(["erb_sudo_upload:#{key}"].concat(task_names))
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::ErbSudoUpload::Core.load_into(Capistrano::Configuration.instance)
  Capistrano::ErbSudoUpload.load_into(Capistrano::Configuration.instance)
end
