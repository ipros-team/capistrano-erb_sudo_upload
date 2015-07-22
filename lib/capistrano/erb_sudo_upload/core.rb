require 'securerandom'

module Capistrano::ErbSudoUpload
  class Core
    def self.load_into(configuration)
      configuration.load do
        def self.run_sudo_commands(commands, setting)
          deploy_user = setting['user'] || fetch(:erb_sudo_upload_user, nil) || fetch(:user, nil)
          switchuser(deploy_user) do
            commands.each do |command|
              unless fetch(:erb_sudo_upload_dryrun, false)
                run "#{sudo} #{command}"
              else
                puts "#{sudo} #{command}"
              end
            end
          end
        end

        def self.sudo_upload_with_files(key, files, setting, excludes)
          deploy_user = setting['user'] || fetch(:erb_sudo_upload_user, nil) || fetch(:user, nil)
          switchuser(deploy_user) do
            files.each do|filename|
              file_setting = setting[filename]
              deploy_file(filename, file_setting, key, excludes)
            end
          end
        end

        def self.deploy_file(filename, file_setting, key, excludes)
          root_dir = fetch(:erb_sudo_upload_root)
          tmp_base_dir = "/tmp/capistrano-#{SecureRandom.uuid}"
          tmp_dir = "#{tmp_base_dir}/#{key}"

          gen_file_path = "#{tmp_dir}/#{filename}"
          erb = file_setting['erb'].nil? ? true : file_setting['erb']
          base_dir = File.absolute_path("#{root_dir}/#{key}/#{filename}")
          generate_file_local(base_dir, gen_file_path, erb, excludes)

          # commands = upload_file(gen_file_path, file_setting)
          commands = upload_files(gen_file_path, file_setting)

          commands << "#{sudo} rm -rf #{tmp_base_dir};true"
          run commands.join(';')
        end

        def self.generate_file_local(src, dest, erb, excludes)
          array = FileTest.directory?(src) ? Dir.glob("#{src}/**/*") : [src]
          array.each{ |item|
            if !excludes.nil? && /#{excludes.join('|')}/ =~ item
              next
            end
            next if FileTest.directory?(item)
            file_path = File.absolute_path(item)
            dest_path = File.absolute_path(dest)
            buf = File.read(file_path).force_encoding('utf-8')
            if erb
              begin
                buf = ERB.new(buf, nil, '-').result(binding)
              rescue Exception => e
                puts "ERROR => #{file_path}"
                puts "\n#{e.message}\n#{e.backtrace.join("\n")}"
              end
            end
            target_path = dest_path + item.gsub(src, '')
            FileUtils.mkdir_p(File.dirname(target_path))
            File.write(target_path, buf)
            File.chmod(File::Stat.new(item).mode, target_path)
          }
        end

        def self.set_vars(vars)
          return if vars.nil?
          vars.each do|variable_name, value|
            set variable_name.to_sym, value
          end
        end

        def self.upload_files(gen_file_path, file_setting)
          commands = []
          target_dir = File.absolute_path(gen_file_path)
          run "mkdir -p #{File.dirname(target_dir)}"
          upload(target_dir, target_dir, :via => :scp, :recursive => true)
          commands << "#{sudo} diff -r #{target_dir} #{file_setting['dest']}; true"
          dryrun = fetch(:erb_sudo_upload_dryrun, false)
          unless dryrun
            commands << "#{sudo} mkdir -p #{File.dirname(file_setting['dest'])}"
            commands << "#{sudo} cp -rp #{target_dir} #{FileTest.directory?(target_dir) ? File.dirname(file_setting['dest']) : file_setting['dest']}"
            commands << "#{sudo} chown -R #{file_setting['owner']} #{file_setting['dest']}"
          end
          commands << "ls -l #{file_setting['dest']}"
          commands
        end
      end
    end
  end
end
