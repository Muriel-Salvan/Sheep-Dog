#!/bin/env ruby
#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rUtilAnts/Logging'
RUtilAnts::Logging::install_logger_on_object
require 'tmpdir'
lLogFile = "#{Dir.tmpdir}/SheepDog_#{Process.pid}.log"
set_log_file(lLogFile)
log_info 'Starting SheepDog'
require 'sheepdog/Executor'

lConfFileName = ARGV[0]
if (lConfFileName == nil)
  log_err "Usage: sheepdog.rb <ConfigFileName>"
elsif (File.exists?(lConfFileName))
  SheepDog::Executor.new.execute(eval(File.read(lConfFileName)))
else
  log_err "Missing file: #{lConfFileName}"
end

File.unlink(lLogFile)
