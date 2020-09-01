## sensu-plugins-lvm

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-lvm.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-lvm)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-lvm.svg)](http://badge.fury.io/rb/sensu-plugins-lvm)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-lvm/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-lvm)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-lvm/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-lvm)
[![Community Slack](https://slack.sensu.io/badge.svg)](https://slack.sensu.io/badge)

## Functionality

**check-lv-usage**

Checks the usage on the logical volume.  Checks both data and metadata volumes associated with Physical Volume

**check-vg-usage**

Check volume group capacity based upon the gem chef-ruby-lvm.

**metrics-vg-usage**

Output graphite metrics for volume group capacity and usage based upon the gem chef-ruby-lvm.


## Files
 * bin/check-lv-usage.rb
 * bin/check-vg-usage.rb
 * bin/metrics-vg-usage.rb
 * bin/check-snap-age.rb

## Installation

Sensu core:

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

Sensu go:

[Installation of Sensu go asset](https://docs.sensu.io/sensu-go/latest/reference/assets/#sharing-an-asset-on-bonsai)
