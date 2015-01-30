require 'securerandom'

module Capistrano::ErbSudoUpload
  class Core
    def self.load_into(configuration)
      configuration.load do
        def self.sudo_upload_with_files(key, files, setting)
          files.each do|filename|
            file_setting = setting[filename]
            generate_file(filename, file_setting, key)
          end
        end

        def self.generate_file(filename, file_setting, key)
          root_dir = fetch(:erb_sudo_upload_root)
          tmp_dir = "/tmp/capistrano/#{SecureRandom.uuid}/#{key}"
          run "mkdir -p #{tmp_dir}"
          FileUtils.mkdir_p(tmp_dir)
          buf = ERB.new(File.read("#{root_dir}/#{key}/#{filename}").force_encoding('utf-8'), nil, '-').result(binding)
          gen_file_path = "#{tmp_dir}/#{filename}"
          File.write(gen_file_path, buf)
          upload(gen_file_path, gen_file_path, via: :scp)
          run "#{sudo} diff #{gen_file_path} #{file_setting['dest']};true"
          dryrun = fetch(:erb_sudo_upload_dryrun, false)
          unless dryrun
            run "#{sudo} mv #{gen_file_path} #{file_setting['dest']}"
            run "#{sudo} chown #{file_setting['owner']} #{file_setting['dest']}"
            run "#{sudo} chmod #{file_setting['mode']} #{file_setting['dest']}"
          end
          run "ls -l #{file_setting['dest']}"
          run "#{sudo} rm -rf #{tmp_dir}"
        end
      end
    end
  end
end
