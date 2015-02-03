# Capistrano::ErbSudoUpload for Capistrano v2

Generate erb file and sudo upload.

## Exsample

add deploy.rb.

```
set :erb_sudo_upload_config, "server/settings.yml"
set :erb_sudo_upload_root, "server"
set :erb_sudo_upload_user, "deploy" # default => fetch(:user)
require 'capistrano/erb_sudo_upload'
```

### yaml setting
```yaml:server/settings.yml
settings:
  td-agent:
    td-agent.conf.erb:
      dest: '/etc/td-agent/td-agent.conf'
      mode: '644'
      owner: 'root:root'
      roles:
        - td_agent
    conf.d/access.conf.erb:
      dest: '/etc/td-agent/conf.d/access.conf'
      mode: '644'
      owner: 'root:root'
      roles:
        - web
  nginx:
    conf/nginx.conf.erb:
      dest: '/usr/local/nginx/conf/nginx.conf'
      mode: '644'
      owner: 'root:root'
      roles:
        - web
  unicorn:
    init.d/unicorn:
      dest: '/etc/init.d/unicorn'
      mode: '755'
      owner: 'root:root'
      roles:
        - app
```

generate task becomes as below (indented):

```
cap erb_sudo_upload:nginx
cap erb_sudo_upload:nginx:web
cap erb_sudo_upload:td-agent
cap erb_sudo_upload:td-agent:td_agent
cap erb_sudo_upload:td-agent:web
cap erb_sudo_upload:unicorn
cap erb_sudo_upload:unicorn:app
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

See [LICENSE.txt](./LICENSE.txt) for details.

