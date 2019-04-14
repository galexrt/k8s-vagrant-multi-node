begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant reboot plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '2.2.0'
  raise 'The Vagrant DiskAndReboot plugin is only compatible with Vagrant 2.2.0+'
end

require 'log4r'
require 'fileutils'

module VagrantPlugins
  module DiskAndReboot
    VERSION = '0.0.1'.freeze
    class Plugin < Vagrant.plugin('2')
      name 'DiskAndReboot Plugin'
      description <<-DESC
      The disk and reboot plugin allows a VM to be outfitted with disk and rebooted as a provisioning step.
      DESC
      provisioner 'diskandreboot' do
        class DiskAndRebootProvisioner < Vagrant.plugin('2', :provisioner)
          def initialize(machine, config)
            super
          end

          def configure(root_config); end

          def provision
            $machineUUID = machine.provider.driver.uuid
            puts("Halting vm #{machine.name} (#{$machineUUID})")
            options = {}
            options[:provision_ignore_sentinel] = false
            @machine.action(:halt, options)

            if $storagecontrollerneedstobecreated
              vboxStorageCtl = `VBoxManage showvminfo #{$machineUUID}`
              if vboxStorageCtl.include?("#{$storagecontroller}")
                puts('Removing storage controller')
                unless system("VBoxManage storagectl #{$machineUUID} --name #{$storagecontroller} --remove")
                  abort("Failed to remove storagecontroller to vm #{machine.name}")
                end
                puts('Removed storage controller')
              end
              puts('Adding storage controller')
              unless system("VBoxManage storagectl #{$machineUUID} --name #{$storagecontroller} --add sata")
                abort("Failed to add storagecontroller to vm #{machine.name}")
              end
              puts('Added storage controller')
            end

            (1..DISK_COUNT.to_i).each do |diskID|
              puts("Adding disk #{diskID}")
              diskPath = ".vagrant/#{BOX_OS}-#{machine.name}-disk-#{diskID}.vdi"
              if !File.exist?(diskPath)
                puts("Creating disk #{diskID} for #{machine.name}")
                unless system("VBoxManage createhd --variant Standard --size #{DISK_SIZE_GB * 1024} --filename #{diskPath}")
                  abort("Failed to create disk #{diskID} for vm #{machine.name}")
                end
                puts("Created disk #{diskID} for #{machine.name}")
              else
                puts("Disk #{diskID} for #{machine.name} already exists")
              end
              unless system("VBoxManage storageattach #{$machineUUID} --storagectl '#{$storagecontroller}' --port #{diskID - 1} --device 0 --type hdd --medium #{diskPath}")
                abort("Failed to add disk #{diskID} for vm #{machine.name}")
              end
              puts("Added disk #{diskID}")
            end

            puts("Starting vm #{machine.name}")
            options = {}
            options[:provision_enabled] = false
            @machine.action(:up, options)
            begin
              sleep 10
            end until @machine.communicate.ready?
          end

          def cleanup; end
        end
        DiskAndRebootProvisioner
      end
    end
  end
end
