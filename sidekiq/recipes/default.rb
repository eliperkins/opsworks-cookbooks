#
# Cookbook Name:: sidekiq
# Recipe:: default
#

worker_count = 1

node[:deploy].each do |application, deploy|
  template "/etc/monit.d/sidekiq_#{app}.monitrc" do 
    owner 'root' 
    group 'root' 
    mode 0644 
    source "monitrc.conf.erb" 
    variables({ 
      :num_workers => worker_count,
      :app_name => app, 
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
    template "#{deploy[:deploy_to]}/shared/config/sidekiq_#{count}.yml" do
      group deploy[:group]
      owner deploy[:user]

      mode 0644
      source "sidekiq.yml.erb"
      variables({
        :require => "#{deploy[:deploy_to]}/current"
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
      echo "sleep 20 && monit -g #{app}_sidekiq restart all" | at now 
    }
  end
end