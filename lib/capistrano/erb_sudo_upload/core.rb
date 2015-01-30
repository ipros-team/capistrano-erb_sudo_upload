require 'securerandom'

module Capistrano::ErbSudoUpload
  class Core
    def self.load_into(configuration)
      configuration.load do
        def self.sudo_upload_with_files(key, files, setting)
          run "mkdir -p /tmp/capistrano"
          run "#{sudo} chown -R #{fetch(:erb_sudo_upload_user, fetch(:user))} /tmp/capistrano"
          files.each do|filename|
            file_setting = setting[filename]
            generate_file(filename, file_setting, key)
          end
        end

        def self.set_vars(vars)
          return if vars.nil?
          vars.each do|variable_name, value|
            set variable_name.to_sym, value
          end
        end

        def self.generate_file(filename, file_setting, key)
          root_dir = fetch(:erb_sudo_upload_root)
          tmp_dir = "/tmp/capistrano/#{SecureRandom.uuid}/#{key}"

          buf = ERB.new(File.read("#{root_dir}/#{key}/#{filename}").force_encoding('utf-8'), nil, '-').result(binding)
          gen_file_path = "#{tmp_dir}/#{filename}"

          target_dir = File.dirname(gen_file_path)
          run "mkdir -p #{target_dir}"
          FileUtils.mkdir_p(target_dir)
          File.write(gen_file_path, buf)
          upload(gen_file_path, gen_file_path, via: :scp)
          run "#{sudo} diff #{gen_file_path} #{file_setting['dest']};true"
          dryrun = fetch(:erb_sudo_upload_dryrun, false)
          unless dryrun
            run "#{sudo} mv #{gen_file_path} #{file_setting['dest']}"
            run "#{sudo} chown #{file_setting['owner']} #{file_setting['dest']}"
            run "#{sudo} chmod #{file_setting['mode']} #{file_setting['dest']}"
          else
            run "cat #{gen_file_path}"
          end
          run "ls -l #{file_setting['dest']};true"
          run "#{sudo} rm -rf #{tmp_dir}"
        end
      end
    end
  end
end
