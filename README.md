# Capistrano::ErbSudoUpload for Capistrano v2

Generate erb file and sudo upload.

## Exsample

add deploy.rb.

```
set :erb_sudo_upload_config, "infra/settings.yml"
set :erb_sudo_upload_root, "infra"
require 'capistrano/erb_sudo_upload'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

See [LICENSE.txt](./LICENSE.txt) for details.

