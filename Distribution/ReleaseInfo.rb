#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

RubyPackager::ReleaseInfo.new.
  author(
    :Name => 'Muriel Salvan',
    :EMail => 'muriel@x-aeon.com',
    :WebPageURL => 'http://murielsalvan.users.sourceforge.net'
  ).
  project(
    :Name => 'Sheep Dog',
    :WebPageURL => 'http://sheepdogsys.sourceforge.net/',
    :Summary => 'System administration helper to monitor files and processes.',
    :Description => 'Simple command line tool that monitors files and processes and sends notifications or take corrective actions when problems arise. Monitor log files for errors, processes CPU and memory consumption (can kill if exceeding), respawn dead processes.',
    :ImageURL => 'http://sheepdogsys.sourceforge.net/wiki/images/c/c9/Logo.png',
    :FaviconURL => 'http://sheepdogsys.sourceforge.net/wiki/images/2/26/Favicon.png',
    :SVNBrowseURL => 'http://sheepdogsys.git.sourceforge.net/',
    :DevStatus => 'Alpha'
  ).
  addCoreFiles( [
    '{lib,bin}/**/*'
  ] ).
#  addTestFiles( [
#    'test/**/*'
#  ] ).
  addAdditionalFiles( [
    'README',
    'LICENSE',
    'AUTHORS',
    'Credits',
    'ChangeLog',
    '*.example'
  ] ).
  gem(
    :GemName => 'SheepDog',
    :GemPlatformClassName => 'Gem::Platform::RUBY',
    :RequirePath => 'lib',
    :HasRDoc => true
#    :TestFile => 'test/run.rb'
  ).
  sourceForge(
    :Login => 'murielsalvan',
    :ProjectUnixName => 'sheepdogsys'
  ).
  rubyForge(
    :ProjectUnixName => 'sheepdogsys'
  ).
  executable(
    :StartupRBFile => 'bin/sheepdog.rb'
  )
