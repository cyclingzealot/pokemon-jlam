# Installation

On Linux systems:

1. `docker-compose build && docker-compose up`
2. In a seperate window: `docker-compose exec web /bin/sh`
3. `bundle exec rake db:create`
4. `bundle exec rake db:schema:load`
5. `bundle exec rake db:seed`
6. In a browser, go to [localhost:3001/creature](http://localhost:3001/creature)
