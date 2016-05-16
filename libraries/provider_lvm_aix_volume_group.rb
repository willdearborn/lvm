#
# Cookbook Name:: lvm
# Library:: provider_lvm_aix_volume_group
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

require 'chef/provider'
require 'chef/mixin/shell_out'
require 'chef/dsl/recipe'
#require File.join(File.dirname(__FILE__), 'lvm')

class Chef
  class Provider
    # The provider for lvm_aix_volume_group resource
    #
    class LvmAixVolumeGroup < Chef::Provider
      include Chef::DSL::Recipe
      include Chef::Mixin::ShellOut

      # Loads the current resource attributes
      #
      # @return [Chef::Resource::LvmAixVolumeGroup] the lvm_aix_volume_group resource
      #
      def load_current_resource
        @current_resource ||= Chef::Resource::LvmAixVolumeGroup.new(@new_resource.name)
        @current_resource
      end

      # The create action
      #
      def action_create
        name = new_resource.name
        physical_volume_list = [new_resource.physical_volumes].flatten

        # create the volume group
        create_volume_group(physical_volume_list, name)

        # create the logical volumes specified as sub-resources
        #create_logical_volumes
      end

      # The extend action
      #
      def action_extend
        name = new_resource.name
        physical_volume_list = [new_resource.physical_volumes].flatten

        # verify that the volume group is valid
        Chef::Application.fatal!("VG #{name} is not a valid volume group", 2) if !volume_group_exists?       

        # verify pv and vg uuid
        pvs_to_add = []
        physical_volume_list.each do |pv_name|
          Chef::Application.fatal!("PV #{pv_name} is not a valid physical volume", 2) if !physical_volume_exists?(pv_name)
          Chef::Application.fatal!("PV #{pv_name} is already a member of another volume group", 2) if !physical_volume_free?(pv_name,name)
          pvs_to_add.push pv_name if !pv_in_vg?(pv_name, name)
        end

        extend_volume_group(pvs_to_add, name) if !pvs_to_add.empty?
      end

      private

      def create_volume_group(physical_volume_list, name)
        if volume_group_exists?
          Chef::Log.info "Volume group '#{name}' already exists. Not creating..."
        else
          Chef::Log.info "Volume group '#{name}' does not exist. Creating..."
          physical_volumes = physical_volume_list.join(' ')
          physical_partition_size= new_resource.physical_partition_size ? "-s #{new_resource.physical_partition_size}" : ''
          yes_flag = new_resource.wipe_signatures == true ? '-f' : ''
          mkvg = "mkvg #{yes_flag} #{physical_partition_size} -y #{name} #{physical_volumes}"
          Chef::Log.debug "Executing lvm command: '#{mkvg}'"
          command = shell_out(mkvg)
          new_resource.updated_by_last_action(true)
        end
      end

      def extend_volume_group(pvs_to_add, name)
        pvs = pvs_to_add.join(' ')
        Chef::Log.debug "Extending volume group, #{name}, with physical volume(s): #{pvs}"
        extendvg = "extendvg #{name} #{pvs}"
        Chef::Log.debug "Executing command #{extendvg}"
        command = shell_out(extendvg)
        new_resource.updated_by_last_action(true)
      end

      def physical_volume_exists?(name)
        pvs = shell_out("lspv | awk '{printf \"%s \",$1}'").stdout.split(' ')
        pvs.include? name
      end

      def physical_volume_free?(pv_name, vg_name)
        pv_vg = shell_out("lspv | awk '$1 == \"#{pv_name}\" {printf \"%s\",$3}'").stdout
        pv_vg == 'None' || pv_in_vg?(pv_name, vg_name)
      end

      def pv_in_vg?(pv_name, vg_name)
        pv_vg_uuid = get_pv_vg_uuid(pv_name)
        vg_uuid = get_vg_uuid(vg_name)
        pv_vg_uuid.eql? vg_uuid
      end

      def volume_group_exists?
        shell_out("lsvg #{new_resource.name}").exitstatus.eql? 0
      end

      def get_pv_vg_uuid(name)
        shell_out("readvgda -q #{name} | awk '$1 == \"VGID:\" {printf \"%s\",$2}'").stdout
      end

      def get_vg_uuid(name)
        shell_out("getlvodm -v #{name} | awk '{printf \"%s\",$1}'").stdout
      end

    end
  end
end
