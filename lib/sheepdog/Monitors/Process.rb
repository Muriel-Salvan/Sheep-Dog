#--
# Copyright (c) 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rUtilAnts/Misc'
RUtilAnts::Misc::initializeMisc

module SheepDog

  module Monitors

    class Process

      # Execute the monitoring process for a given configuration
      #
      # Parameters:
      # * *iConf* (<em>map<Symbol,Object></em>): The monitor configuration
      def execute(iConf)
        # Get the list of processes
        # list< Integer >
        lLstPIDs = []
        `ps -Af`.split("\n")[1..-1].map { |iLine| iLine.strip }.each do |iLine|
          lMatch = iLine.match(/^(\S+)\s+(\d+)\s+\d+\s+\d+\s+\S+\s+\S+\s+\S+\s+(.+)$/)
          if (lMatch == nil)
            report "Unable to decode ps output: \"#{iLine}\". Ignoring this line."
          else
            lUser, lPID, lCmd = lMatch[1..3]
            iConf[:Processes].each do |iProcessFilterInfo|
              if (iProcessFilterInfo.empty?)
                report 'Process filter info is empty. ignoring it. Please check configuration.'
              else
                lOut = false
                if (iProcessFilterInfo.has_key?(:UserFilter))
                  lOut = (lUser.match(iProcessFilterInfo[:UserFilter]) == nil)
                end
                if ((!lOut) and
                    (iProcessFilterInfo.has_key?(:NameFilter)))
                  lOut = (lCmd.match(iProcessFilterInfo[:NameFilter]) == nil)
                end
                if (!lOut)
                  # This PID is selected
                  lLstPIDs << lPID.to_i
                end
              end
            end
          end
        end
        if (lLstPIDs.empty?)
          # Maybe we want to execute something
          if (iConf.has_key?(:ExecuteIfMissing))
            report "Missing process. Executing \"#{iConf[:ExecuteIfMissing][:CmdLine]}\" from \"#{iConf[:ExecuteIfMissing][:Pwd]}\":"
            changeDir(iConf[:ExecuteIfMissing][:Pwd]) do
              report `#{iConf[:ExecuteIfMissing][:CmdLine]}`
            end
          end
        elsif (iConf.has_key?(:Limits))
          # Monitor the processes
          # Set of PIDs exceeding limits
          # map< Integer, nil >
          lAboveLimitsPIDs = {}
          lLstPIDs.each do |iPID|
            lCPUPercent, lMemPercent, lVirtualSize = getPIDMetrics(iPID)
            # Challenge metrics against limits
            if ((iConf[:Limits].has_key?(:CPUPercent)) and
                (lCPUPercent > iConf[:Limits][:CPUPercent]))
              report "PID #{iPID} exceeds CPU percent limit: #{lCPUPercent} > #{iConf[:Limits][:CPUPercent]}"
              lAboveLimitsPIDs[iPID] = nil
            end
            if ((iConf[:Limits].has_key?(:MemPercent)) and
                (lMemPercent > iConf[:Limits][:MemPercent]))
              report "PID #{iPID} exceeds Mem percent limit: #{lMemPercent} > #{iConf[:Limits][:MemPercent]}"
              lAboveLimitsPIDs[iPID] = nil
            end
            if ((iConf[:Limits].has_key?(:VirtualMemSize)) and
                (lVirtualSize > iConf[:Limits][:VirtualMemSize]))
              report "PID #{iPID} exceeds virtual mem size limit: #{lVirtualSize} > #{iConf[:Limits][:VirtualMemSize]}"
              lAboveLimitsPIDs[iPID] = nil
            end
          end
          if (!lAboveLimitsPIDs.empty?)
            # What to do with PIDs exceeding limits ?
            if (iConf[:ActionAboveLimits] == :Kill)
              # Kill them
              report "Killing PIDs #{lAboveLimitsPIDs.keys.join(' ')} ..."
              report `kill -9 #{lAboveLimitsPIDs.keys.join(' ')}`
            end
          end
        end
      end

      private

      # Get metrics of a PID
      #
      # Parameters:
      # * *iPID* (_Integer_): The PID to get metrics from
      # Return:
      # * _Float_: The CPU percentage
      # * _Float_: The mem percentage
      # * _Integer_: The total virtual memory size
      def getPIDMetrics(iPID)
        rCPUPercent = nil
        rMemPercent = nil
        rVS = nil

        # From top
        lTopOutput = `top -n1 -p#{iPID} -b | tail -2 | head -1`.strip
        lMatch = lTopOutput.match(/^\d+\s+\S+\s+\d+\s+\d+\s+\S+\s+\S+\s+\d+\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+.+$/)
        if (lMatch == nil)
          report "Unable to decode top output for PID #{iPID}: \"#{lTopOutput}\""
        else
          rCPUPercent, rMemPercent = lMatch[1..2].map { |iStrValue| iStrValue.to_f }
        end
        # From proc/<PID>/stat
        lStatOutput = `cat /proc/#{iPID}/stat`.strip
        lMatch = lStatOutput.match(/^\d+\s+\(.+\)\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+/)
        if (lMatch == nil)
          report "Unable to decode stat output for PID #{iPID}: \"#{lStatOutput}\""
        else
          rVS = lMatch[1].to_i
        end

        return rCPUPercent, rMemPercent, rVS
      end

    end

  end

end
