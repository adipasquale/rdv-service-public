web: ./bin/start_web_server
jobs_1: bundle exec good_job start --queues=default,cron,mailers,outlook_sync
jobs_2: bundle exec good_job start --queues=exports
jobs_3: bundle exec good_job start --queues=reminders,sms,trigger_webhook,webhook
postdeploy: bundle exec rake db:migrate
