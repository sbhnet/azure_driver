#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2018, IONe Cloud Project, Support.by                             #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
# -------------------------------------------------------------------------- #

STARTUP_TIME = Time.now.to_f

ONE_LOCATION = ENV["ONE_LOCATION"] if !defined?(ONE_LOCATION)

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = "/etc/one/" if !defined?(ETC_LOCATION)
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = ONE_LOCATION + "/etc/" if !defined?(ETC_LOCATION)
end

$: << RUBY_LIB_LOCATION

require 'opennebula'
include OpenNebula

id = ARGV.first

vm = VirtualMachine.new_with_id id, Client.new
vm.info!

begin
    cloud_type = vm['/VM/USER_TEMPLATE/PUBLIC_CLOUD/TYPE']
rescue
    cloud_type = 'nil'
end

if cloud_type != 'AZURE' then
    puts "Not Azure(ARM) VM, skipping."
    exit 0
end

template = vm.user_template_str.slice(/PUBLIC_CLOUD=\[((.|\n)*?)\]/)

image = template.slice(/IMAGE="(.*)<->(.*)"/).split('<->')
image = image.first == 'IMAGE="  ' ? 'IMAGE="' + image.last : image.first + '"'

template.gsub!(/IMAGE="(.*)<->(.*)"/, image)

vm.update template, true

puts "Work time: #{(Time.now.to_f - STARTUP_TIME).round(6).to_s} sec"