require 'securerandom'

module Capistrano::ErbSudoUpload
  class Core
    def self.load_into(configuration)
      configuration.load do
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
          generate_file_local("#{root_dir}/#{key}/#{filename}", gen_file_path, file_setting['erb'] || true)

          upload_file(gen_file_path, file_setting)
          run "#{sudo} rm -rf #{tmp_dir}"
        end

        def self.upload_file(gen_file_path, file_setting)
          run "mkdir -p #{File.dirname(gen_file_path)}"
          upload(gen_file_path, gen_file_path, via: :scp)

          run "#{sudo} diff #{gen_file_path} #{file_setting['dest']};true"
          dryrun = fetch(:erb_sudo_upload_dryrun, false)
          unless dryrun
            run "#{sudo} mkdir -p #{File.dirname(file_setting['dest'])}"
            run "#{sudo} mv #{gen_file_path} #{file_setting['dest']}"
            run "#{sudo} chown #{file_setting['owner']} #{file_setting['dest']}"
            run "#{sudo} chmod #{file_setting['mode']} #{file_setting['dest']}"
          else
            run "cat #{gen_file_path}"
          end
          run "ls -l #{file_setting['dest']};true"
        end
      end
    end
  end
end
