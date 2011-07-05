#!/bin/env ruby
#--
# Copyright (c) 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rUtilAnts/Logging'
RUtilAnts::Logging::initializeLogging('','')
require 'tmpdir'
lLogFile = "#{Dir.tmpdir}/SheepDog_#{Process.pid}.log"
setLogFile(lLogFile)
logInfo 'Starting SheepDog'
require 'sheepdog/Executor'

lConfFileName = ARGV[0]
if (lConfFileName == nil)
  logErr "Usage: sheepdog.rb <ConfigFileName>"
elsif (File.exists?(lConfFileName))
  SheepDog::Executor.new.execute(eval(File.read(lConfFileName)))
else
  logErr "Missing file: #{lConfFileName}"
end

File.unlink(lLogFile)
