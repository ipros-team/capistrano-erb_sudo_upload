module Capistrano::ErbSudoUpload
  class Util
    def self.get_role_map(setting)
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
      role_map
    end
  end
end