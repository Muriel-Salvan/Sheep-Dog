#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

RubyPackager::ReleaseInfo.new.
  author(
    :name => 'Muriel Salvan',
    :email => 'muriel@x-aeon.com',
    :web_page_url => 'http://murielsalvan.users.sourceforge.net'
  ).
  project(
    :name => 'Sheep Dog',
    :web_page_url => 'http://sheepdogsys.sourceforge.net/',
    :summary => 'System administration helper to monitor files and processes.',
    :description => 'Simple command line tool that monitors files and processes and sends notifications or take corrective actions when problems arise. Monitor log files for errors, processes CPU and memory consumption (can kill if exceeding), respawn dead processes.',
    :image_url => 'http://sheepdogsys.sourceforge.net/wiki/images/c/c9/Logo.png',
    :favicon_url => 'http://sheepdogsys.sourceforge.net/wiki/images/2/26/Favicon.png',
    :browse_source_url => 'http://sheepdogsys.git.sourceforge.net/',
    :dev_status => 'Alpha'
  ).
  add_core_files( [
    '{lib,bin}/**/*'
  ] ).
#  add_test_files( [
#    'test/**/*'
#  ] ).
  add_additional_files( [
    'README',
    'LICENSE',
    'AUTHORS',
    'Credits',
    'ChangeLog',
    '*.example'
  ] ).
  gem(
    :gem_name => 'SheepDog',
    :gem_platform_class_name => 'Gem::Platform::RUBY',
    :require_path => 'lib',
    :has_rdoc => true,
    :gem_dependencies => [
      [ 'rUtilAnts', '>= 1.0' ]
    ],
#    :test_file => 'test/run.rb'
  ).
  source_forge(
    :login => 'murielsalvan',
    :project_unix_name => 'sheepdogsys'
  ).
  ruby_forge(
    :project_unix_name => 'sheepdogsys'
  ).
  executable(
    :startup_rb_file => 'bin/sheepdog.rb'
  )
