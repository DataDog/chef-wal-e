#
# Cookbook Name:: wal-e
# Recipe:: default

# install packages
unless node[:wal_e][:packages].nil?
  node[:wal_e][:packages].each do |pkg|
    package pkg
  end
end

# install python modules with pip unless overriden
unless node[:wal_e][:pips].nil?
  include_recipe "python::pip"
  node[:wal_e][:pips].each do |pp|
    python_pip pp
  end
end

# Install from source or pip pacakge
case node[:wal_e][:install_method]
when 'source'
  code_path = "#{Chef::Config[:file_cache_path]}/wal-e"

  bash "install_wal_e" do
    cwd code_path
    code <<-EOH
      pip install -r requirements.txt
      pip install .
    EOH
    action :nothing
  end

  git code_path do
    repository node[:wal_e][:repository_url]
    revision node[:wal_e][:version]
    notifies :run, "bash[install_wal_e]", :immediately
  end
when 'pip'
  python_pip 'wal-e' do
    version node[:wal_e][:version] if node[:wal_e][:version]
  end
end

directory node[:wal_e][:env_dir] do
  user    node[:wal_e][:user]
  group   node[:wal_e][:group]
  mode    "0550"
end

vars = { 'AWS_ACCESS_KEY_ID'     => node[:wal_e][:aws_access_key],
         'AWS_SECRET_ACCESS_KEY' => node[:wal_e][:aws_secret_key],
         'AWS_REGION'            => node[:wal_e][:aws_region],
         'WALE_S3_PREFIX'        => node[:wal_e][:s3_prefix] }

vars.each do |key, value|
  file "#{node[:wal_e][:env_dir]}/#{key}" do
    content value
    user    node[:wal_e][:user]
    group   node[:wal_e][:group]
    mode    "0440"
  end
end

gpg_key_id = node[:wal_e][:base_backup][:gpg_key_id]
gpg_key = gpg_key_id ? "--gpg-key-id #{gpg_key_id}" : ""

cron_d "wal_e_base_backup" do
  user node[:wal_e][:user]
  command [
    "/usr/bin/envdir",
    node[:wal_e][:env_dir],
    "/usr/local/bin/wal-e",
    gpg_key,
    "backup-push",
    node[:wal_e][:base_backup][:options],
    node[:wal_e][:pgdata_dir]
  ].join(' ')
  not_if { node[:wal_e][:base_backup][:disabled] }

  minute node[:wal_e][:base_backup][:minute]
  hour node[:wal_e][:base_backup][:hour]
  day node[:wal_e][:base_backup][:day]
  month node[:wal_e][:base_backup][:month]
  weekday node[:wal_e][:base_backup][:weekday]
end
