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
            before_commands = setting['before_commands']
            after_commands = setting['after_commands']
            file_settings = setting['file_settings']
            task_options =
              if setting['task_options'].nil?
                {}
              else
                setting['task_options'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
              end
            excludes = setting['excludes']
            role_map = Util.get_role_map(file_settings)

            method_names = []
            namespace key do
              desc "deploy #{key}"
              task "default", except: {no_release: true} do
                puts "#{key} deploy start"
              end
              role_map.each do |role_name, files|
                method_names << role_name
                option = role_name == 'all' ? {} : { roles: role_name }
                option[:except] = {no_release: true}
                option[:on_no_matching_servers] = :continue
                option = task_options.merge(option)

                desc "deploy [#{files.join(', ')}], Role is #{role_name} only"
                task(role_name, option) do
                  sudo_upload_with_files(key, files, file_settings, excludes)
                end
              end

              exec_commands_option = role_map.keys.include?('all') ? {} : { roles: role_map.keys }
              if before_commands
                desc "exec commands => #{before_commands.join(';')}"
                task('before', exec_commands_option) do
                  run_sudo_commands(before_commands, setting)
                end
              end

              if after_commands
                desc "exec commands => #{after_commands.join(';')}"
                task('after', exec_commands_option) do
                  run_sudo_commands(after_commands, setting)
                end
              end
            end
            deploy_task_names = method_names.map{ |role_name| "erb_sudo_upload:#{key}:#{role_name}"}

            tasks = ["erb_sudo_upload:#{key}"]
            tasks << "erb_sudo_upload:#{key}:before" if before_commands
            tasks = tasks.concat(deploy_task_names)
            tasks << "erb_sudo_upload:#{key}:after" if after_commands
            after *tasks
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
