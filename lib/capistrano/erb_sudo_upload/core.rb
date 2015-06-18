require 'securerandom'

module Capistrano::ErbSudoUpload
  class Core
    def self.load_into(configuration)
      configuration.load do
        def self.run_sudo_commands(commands)
          switchuser(fetch(:erb_sudo_upload_user, fetch(:user))) do
            commands.each do |command|
              unless fetch(:erb_sudo_upload_dryrun, false)
                run "#{sudo} #{command}"
              else
                puts "#{sudo} #{command}"
              end
            end
          end
        end

        def self.sudo_upload_with_files(key, files, setting)
          switchuser(fetch(:erb_sudo_upload_user, fetch(:user))) do
            files.each do|filename|
              file_setting = setting[filename]
              deploy_file(filename, file_setting, key)
            end
          end
        end

        def self.generate_file_local(src, dest, erb)
          buf = File.read(src).force_encoding('utf-8')
          if erb
            buf = ERB.new(buf, nil, '-').result(binding)
          end
          FileUtils.mkdir_p(File.dirname(dest))
          File.write(dest, buf)
        end

        def self.set_vars(vars)
          return if vars.nil?
          vars.each do|variable_name, value|
            set variable_name.to_sym, value
          end
        end

        def self.deploy_file(filename, file_setting, key)
          root_dir = fetch(:erb_sudo_upload_root)
          tmp_dir = "/tmp/capistrano-#{SecureRandom.uuid}/#{key}"

          gen_file_path = "#{tmp_dir}/#{filename}"
          erb = file_setting['erb'].nil? ? true : file_setting['erb']
          generate_file_local("#{root_dir}/#{key}/#{filename}", gen_file_path, erb)

          commands = upload_file(gen_file_path, file_setting)

          commands << "#{sudo} rm -rf #{tmp_dir};true"
          run commands.join(';')
        end

        def self.upload_file(gen_file_path, file_setting)
          commands = []
          run "mkdir -p #{File.dirname(gen_file_path)}"
          upload(gen_file_path, gen_file_path, via: :scp)

          commands << "#{sudo} diff #{gen_file_path} #{file_setting['dest']}"
          dryrun = fetch(:erb_sudo_upload_dryrun, false)
          unless dryrun
            commands << "#{sudo} mkdir -p #{File.dirname(file_setting['dest'])}"
            commands << "#{sudo} mv #{gen_file_path} #{file_setting['dest']}"
            commands << "#{sudo} chown #{file_setting['owner']} #{file_setting['dest']}"
            commands << "#{sudo} chmod #{file_setting['mode']} #{file_setting['dest']}"
          else
            commands << "cat #{gen_file_path}"
          end
          commands << "ls -l #{file_setting['dest']}"
          commands
        end
      end
    end
  end
end
