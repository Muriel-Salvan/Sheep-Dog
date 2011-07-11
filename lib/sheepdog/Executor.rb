#--
# Copyright (c) 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'time'
require 'fileutils'
require 'sheepdog/Common'
require 'sheepdog/Report'

module SheepDog

  class Executor

    # Constructor
    def initialize
      # Parse plugins
      require 'rUtilAnts/Plugins'
      RUtilAnts::Plugins::initializePlugins
      parsePluginsFromDir('Notifiers', "#{File.expand_path(File.dirname(__FILE__))}/Notifiers", 'SheepDog::Notifiers')
      parsePluginsFromDir('Monitors', "#{File.expand_path(File.dirname(__FILE__))}/Monitors", 'SheepDog::Monitors')
    end

    # Execute a given configuration
    #
    # Parameters:
    # * *iConf* (<em>map<Symbol,Object></em>): The sheep dog configuration
    def execute(iConf)
      # Get the local database, storing dates of last reports sent...
      lDatabaseFileName = "#{iConf[:WorkingDir]}/Database"
      lDatabase = nil
      if (File.exists?(lDatabaseFileName))
        lDatabase = Marshal.load(File.read(lDatabaseFileName))
      else
        lDatabase = {
          # The time of last sent reports, per notifer and monitor name
          # map< MonitorName, map< NotifierName, Time > >
          :LastReportsSent => {}
        }
      end

      # The list of monitor reports to be sent at the end of the process, per notifier, along with their respective configuration
      # map< NotifierName, map< MonitorName, list < [ NotificationConf, list< ReportFileName > ] > > >
      lGroupedMonitorReports = {}
      # The map of monitor reports that are sent by our run
      # map< ReportFileName >
      lSentReports = {}
      # The map of monitor reports that will be sent by later runs
      # map< ReportFileName >
      lDelayedReports = {}
      # Loop through the objects to monitor
      iConf[:Monitors].each do |iMonitorName, iMonitorInfo|
        # Check that it is a known monitor, by accessing the plugin
        lMonitorPluginInstance, lError = getPluginInstance('Monitors', iMonitorInfo[:Type])
        if (lMonitorPluginInstance == nil)
          # Unknown monitor
          logErr "Unknown Monitor #{iMonitorInfo[:Type]}: #{lError}. Ignoring corresponding monitoring process. Please check configuration."
        else
          # Create the report to be filled by this process
          lReport = Report.new
          # Create the monitor configuration dir
          lMonitorDir = "#{iConf[:WorkingDir]}/#{iMonitorName}"
          FileUtils::mkdir_p(lMonitorDir)
          # Set instance variables and methods for this monitor
          lMonitorPluginInstance.instance_variable_set(:@SheepDogConf, iConf)
          lMonitorPluginInstance.instance_variable_set(:@Report, lReport)
          lMonitorPluginInstance.instance_variable_set(:@MonitorDir, lMonitorDir)
          if (!lMonitorPluginInstance.respond_to?(:report))
            # Report an entry
            #
            # Parameters:
            # * *iEntry* (_String_): Entry to be reported
            def lMonitorPluginInstance.report(iEntry)
              @Report.addEntry(iEntry)
              logInfo "Report: #{iEntry}"
            end
          end
          # Call this monitor
          begin
            logInfo "Executing monitoring process #{iMonitorName} ..."
            lMonitorPluginInstance.execute(iMonitorInfo)
          rescue Exception
            logErr "Exception while executing monitor #{iMonitorName}: #{$!}.\n#{$!.backtrace.join("\n")}"
            report "!!! Exception while executing monitor #{iMonitorName}: #{$!}.\n#{$!.backtrace.join("\n")}"
          end
          # If this report is not empty, save it in a file
          lCurrentReportFileName = nil
          lCurrentReportTime = nil
          if (!lReport.empty?)
            lCurrentReportTime = Time.now.utc
            lCurrentReportFileName = "#{lMonitorDir}/Report_#{lCurrentReportTime.strftime('%Y-%m-%d-%H-%M-%S')}"
            File.open(lCurrentReportFileName, 'w') do |oFile|
              oFile.write(Marshal.dump(lReport))
            end
          end
          # Get the list of reports to send, per time
          # map< Time, FileName >
          lReportFiles = {}
          Dir.glob("#{lMonitorDir}/Report_*").each do |iReportFile|
            lMatch = File.basename(iReportFile).match(/^Report_(\d\d\d\d)-(\d\d)-(\d\d)-(\d\d)-(\d\d)-(\d\d)$/)
            if (lMatch == nil)
              logErr "Invalid file report name: #{iReportFile}. Ignoring it."
            else
              lReportFiles[Time.parse("#{lMatch[1]}-#{lMatch[2]}-#{lMatch[3]} #{lMatch[4]}:#{lMatch[5]}:#{lMatch[6]} UTC")] = iReportFile
            end
          end
          # For each report file, compute the list of notifiers that will send it
          if (!lReportFiles.empty?)
            # There are some report files to be (maybe) sent.
            # Loop through the notifiers.
            iMonitorInfo[:Notifiers].each do |iNotifierName, iNotifierConf|
              lNotifierID = iNotifierConf[:Type]
              if (iNotifierConf[:GroupReports] == nil)
                # Send the report now if it exists
                if (lCurrentReportFileName != nil)
                  # Send [iMonitorInfo, [lCurrentReportFileName]] to iNotifierName
                  if (iNotifierConf[:GroupWithOtherMonitors] == true)
                    if (lGroupedMonitorReports[lNotifierID] == nil)
                      lGroupedMonitorReports[lNotifierID] = {}
                    end
                    if (lGroupedMonitorReports[lNotifierID][iMonitorName] == nil)
                      lGroupedMonitorReports[lNotifierID][iMonitorName] = []
                    end
                    lGroupedMonitorReports[lNotifierID][iMonitorName] << [ iNotifierConf, [ lCurrentReportFileName ] ]
                  else
                    notify(iConf, {lNotifierID => {iMonitorName => [ [ iNotifierConf, [lCurrentReportFileName] ] ] }}, lDelayedReports)
                  end
                  lSentReports[lCurrentReportFileName] = nil
                  # Remember last report sent
                  if (lDatabase[:LastReportsSent][iMonitorName] == nil)
                    lDatabase[:LastReportsSent][iMonitorName] = {}
                  end
                  lDatabase[:LastReportsSent][iMonitorName][iNotifierName] = lCurrentReportTime
                end
              else
                # Get the interval in seconds
                lSecsInterval = getSecsInterval(iNotifierConf[:GroupReports])
                # Maybe we don't want to send reports now
                # Get the last time we sent reports for this one
                if ((lDatabase[:LastReportsSent][iMonitorName] != nil) and
                    (lDatabase[:LastReportsSent][iMonitorName][iNotifierName] != nil) and
                    ((Time.now.utc - lDatabase[:LastReportsSent][iMonitorName][iNotifierName]) < lSecsInterval))
                  # Reports from last one sent to the most recent one are marked to be sent later
                  lReportFiles.each do |iReportTime, iReportFileName|
                    if (iReportTime > lDatabase[:LastReportsSent][iMonitorName][iNotifierName])
                      # This report will be sent another time
                      lDelayedReports[iReportFileName] = nil
                    end
                  end
                else
                  # Send all corresponding reports now
                  lLastReportSentDate = nil
                  if ((lDatabase[:LastReportsSent][iMonitorName] != nil) and
                      (lDatabase[:LastReportsSent][iMonitorName][iNotifierName] != nil))
                    lLastReportSentDate = lDatabase[:LastReportsSent][iMonitorName][iNotifierName]
                  else
                    lLastReportSentDate = Time.parse('1970-01-01 00:00:00 UTC')
                  end
                  lReportFilesToSend = []
                  lLastReportTime = Time.parse('1970-01-01 00:00:00 UTC')
                  lReportFiles.each do |iReportTime, iReportFileName|
                    if (iReportTime > lLastReportSentDate)
                      lReportFilesToSend << iReportFileName
                      lSentReports[iReportFileName] = nil
                      if (iReportTime > lLastReportTime)
                        lLastReportTime = iReportTime
                      end
                    end
                  end
                  if (!lReportFilesToSend.empty?)
                    # Send [iMonitorInfo, lReportFilesToSend] to iNotifierName
                    if (iNotifierConf[:GroupWithOtherMonitors] == true)
                      if (lGroupedMonitorReports[lNotifierID] == nil)
                        lGroupedMonitorReports[lNotifierID] = {}
                      end
                      if (lGroupedMonitorReports[lNotifierID][iMonitorName] == nil)
                        lGroupedMonitorReports[lNotifierID][iMonitorName] = []
                      end
                      lGroupedMonitorReports[lNotifierID][iMonitorName] << [ iNotifierConf, lReportFilesToSend ]
                    else
                      notify(iConf, {lNotifierID => {iMonitorName => [ [ iNotifierConf, lReportFilesToSend ] ]}}, lDelayedReports)
                    end
                    # Remember last report sent
                    if (lDatabase[:LastReportsSent][iMonitorName] == nil)
                      lDatabase[:LastReportsSent][iMonitorName] = {}
                    end
                    lDatabase[:LastReportsSent][iMonitorName][iNotifierName] = lLastReportTime
                  end
                end
              end
            end
          end
        end
      end
      if (!lGroupedMonitorReports.empty?)
        # Send all notifications that were grouped
        notify(iConf, lGroupedMonitorReports, lDelayedReports)
      end
      # Now we can delete reports that were sent and are also not marked for delayed sending
      lSentReports.each do |iReportFileName, iNil|
        if (!lDelayedReports.has_key?(iReportFileName))
          File.unlink(iReportFileName)
        end
      end
      # Log reports to be sent delayed
      lDelayedReports.keys.each do |iReportFileName|
        logInfo "Report to be sent later: #{iReportFileName}"
      end

      # Write back database
      File.open(lDatabaseFileName, 'w') do |oFile|
        oFile.write(Marshal.dump(lDatabase))
      end
    end

    private

    # Process notifications to be sent.
    #
    # Parameters:
    # * *iConf* (<em>map<Symbol,Object></em>): SheepDog config
    # * *iNotificationsInfo* (<em>map<NotifierName,map<MonitorName,list<[NotifierConf,list<ReportFileName>]>>></em>): The list of report files to send along with their notifier config, per monitor name, per notifier name
    # * *ioErrorReports* (<em>map<ReportFileName,nil></em>): The set of report file names that could not be sent through notifications
    def notify(iConf, iNotificationsInfo, ioErrorReports)
      iNotificationsInfo.each do |iNotifierName, iNotifierNotificationsInfo|
        # Find this notifier
        if (iConf[:Notifiers][iNotifierName] == nil)
          logErr "Unknown notifier named #{iNotifierName}. Ignoring notifications to be sent there. Please check configuration."
        else
          accessPlugin('Notifiers', iConf[:Notifiers][iNotifierName][:Type]) do |iNotifierPlugin|
            # List of reports to send through this notifier
            # list< Report >
            lLstReports = []
            # Set of report files that will be sent through this call
            # map< ReportFileName, nil >
            lReportFilesSet = {}
            iNotifierNotificationsInfo.each do |iMonitorName, iLstMonitorNotificationsInfo|
              iLstMonitorNotificationsInfo.each do |iMonitorNotificationsInfo|
                iNotifierConf, iLstReportFileNames = iMonitorNotificationsInfo
                iLstReportFileNames.each do |iReportFileName|
                  lReport = nil
                  begin
                    lReport = Marshal.load(File.read(iReportFileName))
                  rescue Exception
                    logErr "Invalid report stored in file #{iReportFileName}: #{$!}.\n#{$!.backtrace.join("\n")}"
                    ioErrorReports[iReportFileName] = nil
                    lReport = nil
                  end
                  if (lReport != nil)
                    lReport.setReportFileName(iReportFileName)
                    if (iNotifierConf[:Title] != nil)
                      lReport.setTitle(iNotifierConf[:Title])
                    end
                    lLstReports << lReport
                    lReportFilesSet[iReportFileName] = nil
                  end
                end
              end
            end
            begin
              logInfo "===== Send notification to #{iNotifierName} of #{lLstReports.size} reports..."
              iNotifierPlugin.sendNotification(iConf[:Notifiers][iNotifierName], lLstReports)
            rescue Exception
              logErr "Exception while sending notification from #{iNotifierName} for reports #{lReportFilesSet.keys.join(', ')}: #{$!}.\n#{$!.backtrace.join("\n")}"
              ioErrorReports.merge!(lReportFilesSet)
            end
          end
        end
      end
    end

    # Get the number of seconds defined in a configuration
    #
    # Parameters:
    # * *iConf* (<em>map<Symbol,Object></em>): The configuration
    # Return:
    # * _Fixnum_: The number of seconds
    def getSecsInterval(iConf)
      if (iConf[:Interval_Secs] != nil)
        return iConf[:Interval_Secs]
      else
        logErr "Unable to decode interval from #{iConf.inspect}"
        return 0
      end
    end

  end

end
