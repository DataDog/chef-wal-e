include_recipe 'python::virtualenv'

template node[:wal_e][:virtualenv][:helper] do
  source 'virtualenvhelper.sh.erb'
  path   node[:wal_e][:virtualenv][:helper]
  owner  node[:wal_e][:user]
  mode 0755
  action :create
end

directory node[:wal_e][:virtualenv][:path] do
  owner node[:wal_e][:user]
  group node[:wal_e][:group]
  recursive true
  action :create
end

python_virtualenv node[:wal_e][:virtualenv][:path] do
  owner node[:wal_e][:user]
  group node[:wal_e][:group]
  interpreter node[:wal_e][:virtualenv][:interpreter] if node[:wal_e][:virtualenv][:interpreter]
  action :create
end
