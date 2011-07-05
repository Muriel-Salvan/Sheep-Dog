#--
# Copyright (c) 2010 - 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module SheepDog

  module Notifiers

    class SendMail

      # Send notifications for a given list of reports.
      #
      # Parameters:
      # * *iConf* (<em>map<Symbol,Object></em>): The notifier config
      # * *iLstReports* (<em>list<Report></em>): List of reports to notify
      def sendNotification(iConf, iLstReports)
        lTitle = nil
        lMessage = nil
        if (iLstReports.size > 1)
          lTitle = "#{iLstReports.size} reports"
          iLstReports.each_with_index do |iReport, iIdx|
            lMessage << "===============================================\n"
            lMessage << "========== Report #{iIdx+1} (#{iReport.CreationTime.utc.strftime('%Y-%m-%d %H:%M:%S')} UTC from #{iReport.ReportFileName}): #{iReport.Title}\n"
            lMessage << iReport.getSimpleText
            lMessage << "===============================================\n\n"
          end
        else
          lReport = iLstReports.first
          lTitle = "#{lReport.Title} (#{lReport.CreationTime.utc.strftime('%Y-%m-%d %H:%M:%S')} UTC from #{lReport.ReportFileName})"
          lMessage = lReport.getSimpleText
        end
        require 'mail'
        Mail.defaults do
         delivery_method(:smtp, iConf[:SMTP])
        end
        Mail.deliver do
          from iConf[:From]
          to iConf[:To]
          subject "SheepDog notification - #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')} UTC - #{lTitle}"
          body lMessage
        end
      end

    end

  end

end
