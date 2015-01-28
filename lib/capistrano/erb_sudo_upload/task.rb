require 'capistrano/erb_sudo_upload/core'
module Capistrano
  module ErbSudoUpload
    def self.load_into(configuration)
      configuration.load do
        namespace :erb_sudo_upload do
          config_path = fetch(:erb_sudo_upload_config, "config/erb_sudo_upload.yml")
          YAML.load_file(config_path).each do |key, setting|
            role_map = {}
            setting.each do|filename, v|
              v['roles'].each{ |role_name|
                if role_map[role_name]
                  role_map[role_name] << filename 
                else
                  role_map[role_name] = [filename]
                end
              }
            end

            method_names = ["#{key}"]
            role_map.each do |role_name, files|
              method_name = (key + '_' + role_name).gsub('-', '_')
              method_names << method_name
              if role_name == 'all'
                task method_name, except: {no_release: true} do
                  sudo_upload_with_files(key, files, setting)
                end
              else
                task method_name, roles: role_name, except: {no_release: true} do
                  sudo_upload_with_files(key, files, setting)
                end
              end
            end
            task_names = method_names.map{ |method_name| "erb_sudo_upload:" + method_name}
            after *task_names
            task key, except: {no_release: true} do
              puts "#{key} deploy start"
            end
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::ErbSudoUpload.load_into(Capistrano::Configuration.instance)
  Capistrano::ErbSudoUpload::Core.load_into(Capistrano::Configuration.instance)
end
