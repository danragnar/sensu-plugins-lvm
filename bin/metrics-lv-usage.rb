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

  # Get group data
  #
  def volume_groups
    vgs = config.key?(:lvm_command) ? LVM::LVM.new(command: config[:lvm_command]).volume_groups : LVM::LVM.new.volume_groups
    vgs.each do |line|
      begin
        next if config[:ignorevg]&.include?(line.name)
        next if config[:ignorevgre]&.match(line.name)
        next if config[:includevg] && !config[:includevg].include?(line.name)
      rescue StandardError
        unknown 'An error occured getting the LVM info'
      end
      volume_group_metrics(line)
    end
  end

  def logical_volumes
    @logical_volumes ||= config.key?(:lvm_command) ? LVM::LVM.new(command: config[:lvm_command]).logical_volumes.list : LVM::LVM.new.logical_volumes.list
  end

  def filter_volumes(list)
    unknown empty_volumes_msg if list.empty?
    begin
      return list.select { |l| config[:lv].include?(l.name) } if config[:lv]
      return list.select { |l| config[:full_name].include?(l.full_name) } if config[:full_name]
    rescue StandardError
      unknown 'An error occured getting the LVM info'
    end
    list
  end

  def volume_group_metrics(line)
    used_b = line.size - line.free
    percent_b = ((used_b * 100) / line.size).round(2)

    output [config[:scheme], line.name, 'used'].join('.'), used_b
    output [config[:scheme], line.name, 'avail'].join('.'), line.free
    output [config[:scheme], line.name, 'used_percentage'].join('.'), percent_b
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

