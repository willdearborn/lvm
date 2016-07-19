#
# Cookbook Name:: lvm
# Library:: provider_lvm_volume_group
#
# Copyright 2009-2016, Chef Software, Inc.
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

require_relative 'provider_lvm_volume_group'

class Chef
  class Provider
    class Aix < Chef::Provider::LvmVolumeGroup
      provides :lvm_volume_group, os: 'aix'

      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmVolumeGroup] the lvm_volume_group resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmVolumeGroup.new(@new_resource.name)
        @current_resource
      end

      def platform_test
        Chef::Application.fatal!("Using AIX provider!")
      end
    end
  end
end
