mysql_install_db
mysqld_safe & mysqladmin --wait=5 ping 
cd /openproject
bundle exec rake db:create:all
bundle exec rake generate_secret_token
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake db:seed
RAILS_ENV=production bundle exec rake assets:precompile
mysqladmin shutdown

