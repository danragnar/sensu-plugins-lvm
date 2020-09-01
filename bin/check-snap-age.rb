#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   check-lv-usage
#
# DESCRIPTION:
#   Uses the chef-ruby-lvm gem to get the Data% from LVS command
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: chef-ruby-lvm
#
# USAGE:
#  ./check-snap-age.rb
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 Zach Bintliff <zbintliff@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'lvm'
require 'time'

#
# Check age of snapshots
#
class CheckLVSnapAge < Sensu::Plugin::Check::CLI
  option :lv,
         short: '-l LogicalVolume[,LogicalVolume]',
         description: 'Name of logical volume (thinpool)',
         proc: proc { |a| a.split(',') }

  option :full_name,
         short: '-f FullLogicalVolume[,FullLogicalVolume]',
         description: 'Name of logical volume (docker/thinpool)',
         proc: proc { |a| a.split(',') }

  option :warn,
         short: '-w SECONDS',
         long: '--age-warn SECONDS',
         description: 'Warn if snapshot is older than SECONDS seconds older',
         proc: proc(&:to_i),
         default: 24 * 60 * 60

  option :crit,
         short: '-c SECONDS',
         long: '--age-critical SECONDS',
         description: 'Critical if snapshot is older than SECONDS seconds older',
         proc: proc(&:to_i),
         default: 7 * 24 * 60 * 60

  option :lvm_command,
         short: '-m COMMAND',
         long: '--command COMMAND',
         description: 'Run this lvm command, e.g /bin/sudo /sbin/lvm'

  # Setup variables
  #
  def initialize(argv = ARGV)
    super(argv)
    @crit_lv = []
    @warn_lv = []
  end

  def logical_volumes
    @logical_volumes ||= config.key?(:lvm_command) ? LVM::LVM.new(command: config[:lvm_command]).logical_volumes.list : LVM::LVM.new.logical_volumes.list
  end

  def empty_volumes_msg
    <<~HEREDOC
      An error occured getting the LVM info: got empty list of volumes.
      Check to ensure sensu has been configured with appropriate permissions.
      On linux systems it will generally need to allow executing `/sbin/lvm`
    HEREDOC
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

  def check_snap_age(volume)
    created = Time.parse(volume.time)
    if created < (Time.now - config[:crit])
      @crit_lv << "#{volume.full_name} is older than #{config[:crit]} seconds"
    elsif created < (Time.now - config[:warn])
      @warn_lv << "#{volume.full_name} is older than #{config[:warn]} seconds"
    end
  end

  #
  # Generate output
  #
  def check_output
    (@crit_lv + @warn_lv).join(', ')
  end

  # Main function
  #
  def run
    volumes = filter_volumes(logical_volumes)
    volumes.each { |volume| check_snap_age(volume) if volume.volume_type == :snapshot }
    critical check_output unless @crit_lv.empty?
    warning check_output unless @warn_lv.empty?
    ok "All logical volume snapshots are younger than #{config[:warn]} seconds"
  end
end
