#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module SheepDog

  module Notifiers

    class StdOut

      # Send notifications for a given list of reports.
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): The notifier config
      # * *iLstReports* (<em>list<Report></em>): List of reports to notify
      def send_notification(iConf, iLstReports)
        lTitle = nil
        lMessage = nil
        if (iLstReports.size > 1)
          lTitle = "#{iLstReports.size} reports"
          lMessage = ''
          iLstReports.each_with_index do |iReport, iIdx|
            lMessage << "===============================================\n"
            lMessage << "========== Report #{iIdx+1} (#{iReport.CreationTime.utc.strftime('%Y-%m-%d %H:%M:%S')} UTC from #{iReport.ReportFileName}): #{iReport.Title}\n"
            lMessage << iReport.getSimpleText
            lMessage << "\n===============================================\n\n"
          end
        else
          lReport = iLstReports.first
          lTitle = "#{lReport.Title} (#{lReport.CreationTime.utc.strftime('%Y-%m-%d %H:%M:%S')} UTC from #{lReport.ReportFileName})"
          lMessage = lReport.getSimpleText
        end
        puts lTitle
        puts
        puts lMessage
      end

    end

  end

end
