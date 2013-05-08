#
# Cookbook Name:: jenkins
# Recipe:: ghprb.rb
#
# Author:: Ramiro Berrelleza <raberrel@elasticbox.com>
#
# Copyright 2011, elasticbox
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "jenkins::server"


data_dir = node['jenkins']['server']['data_dir']

template "#{data_dir}/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml" do
  source      "ghprb.erb"
  owner       node['jenkins']['server']['user']
  group       node['jenkins']['server']['group']
  mode        '0700'
  variables(
    :server_api_url   => node['jenkins']['ghprb']['server_api_url'],
    :username     => node['jenkins']['ghprb']['username'],
    :password     => node['jenkins']['ghprb']['password'],
    :access_token  => node['jenkins']['ghprb']['access_token'],
    :published_url => node['jenkins']['ghprb']['published_url']
  )
notifies :restart, "runit_service[jenkins]"
end

ruby_block "block_until_operational" do
  block do
    Chef::Log.info "Waiting until Jenkins is listening on port #{node['jenkins']['server']['port']}"
    until JenkinsHelper.service_listening?(node['jenkins']['server']['port']) do
      sleep 1
      Chef::Log.debug(".")
    end

    Chef::Log.info "Waiting until the Jenkins API is responding"
    test_url = URI.parse("#{node['jenkins']['server']['url']}/api/json")
    until JenkinsHelper.endpoint_responding?(test_url) do
      sleep 1
      Chef::Log.debug(".")
    end
  end
  action :nothing
end

