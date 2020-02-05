#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   metrics-lv-usage
#
# DESCRIPTION:
#   Uses the chef-ruby-lvm gem to get LVM volume group statistics
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: chef-ruby-lvm
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 Aaron Brady <aaron@insom.me.uk>
#   Copyright 2012 Sonian, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'
require 'lvm'

#
# LV Usage Metrics
#
class LvUsageMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.vg_usage"

  option :lv,
         short: '-l LogicalVolume[,LogicalVolume]',
         description: 'Name of logical volume (thinpool)',
         proc: proc { |a| a.split(',') }

  option :lvm_command,
         short: '-m COMMAND',
         long: '--command COMMAND',
         description: 'Run this lvm command, e.g /bin/sudo /sbin/lvm'

  def logical_volumes
    @logical_volumes ||= config.key?(:lvm_command) ? LVM::LVM.new(command: config[:lvm_command]).logical_volumes.list : LVM::LVM.new.logical_volumes.list
  end

  def filter_volumes(list)
    unknown empty_volumes_msg if list.empty?
    begin
      return list.select { |l| config[:lv].include?(l.name) } if config[:lv]
    rescue StandardError
      unknown 'An error occured getting the LVM info'
    end
    list
  end

  def logical_volume_metrics(volume)
    d_percent = volume.data_percent.to_i
    m_percent = volume.metadata_percent.to_i
    size = volume.size

    output [config[:scheme], volume.full_name, 'data', 'used_percentage'].join('.'), d_percent
    output [config[:scheme], volume.full_name, 'data', 'size'].join('.'), size
    output [config[:scheme], volume.full_name, 'metadata', 'used_percentage'].join('.'), m_percent
  end

  # Main function
  #
  def run
    volumes = filter_volumes(logical_volumes)
    volumes.each { |volume| logical_volume_metrics(volume) }
    ok
  end
end
