# Graphiti Sinatra Example

Using [Graphiti](https://github.com/graphiti-api/graphiti), Sinatra, and
ActiveRecord with SQLite.

### Running

```bash
$ bundle install
$ bundle exec rackup -p 4567
```

Launched on http://ec2-3-26-7-103.ap-southeast-2.compute.amazonaws.com:4567/api/v1 as service:
```
sudo systemctl stop keyhook_backend.service
sudo systemctl restart keyhook_backend.service
sudo systemctl status keyhook_backend.service
```