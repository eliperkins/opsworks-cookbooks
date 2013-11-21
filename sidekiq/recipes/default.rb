#
# Cookbook Name:: sidekiq
# Recipe:: default
#

worker_count = 1

node[:deploy].each do |application, deploy|
  template "/etc/monit.d/sidekiq_#{application}.monitrc" do 
    owner 'root' 
    group 'root' 
    mode 0644 
    source "monitrc.conf.erb" 
    variables({ 
      :num_workers => worker_count,
      :app_name => application, 
      :rails_env => deploy[:rails_env] 
    }) 
  end

  template "/usr/local/bin/sidekiq" do
    owner 'root'
    group 'root' 
    mode 0755
    source "sidekiq.erb" 
  end

  worker_count.times do |count|
    template "/srv/www/#{application}/shared/config/sidekiq_#{count}.yml" do
      group deploy[:group]
      owner deploy[:user]

      mode 0644
      source "sidekiq.yml.erb"
      variables({
        :require => "/srv/www/#{application}/current"
      })
    end
  end

  execute "ensure-sidekiq-is-setup-with-monit" do 
    command %Q{ 
      monit reload 
    } 
  end

  execute "restart-sidekiq" do 
    command %Q{ 
      echo "sleep 20 && monit -g #{application}_sidekiq restart all" | at now 
    }
  end
end