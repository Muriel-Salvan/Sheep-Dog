#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module SheepDog

  module Monitors

    class LogFile

      # Execute the monitoring process for a given configuration
      #
      # Parameters::
      # * *iConf* (<em>map<Symbol,Object></em>): The monitor configuration
      def execute(iConf)
        # Get past values
        lReadValuesFileName = "#{@MonitorDir}/ReadValues"
        lReadValues = nil
        if (File.exists?(lReadValuesFileName))
          begin
            lReadValues = Marshal.load(File.read(lReadValuesFileName))
          rescue Exception
            report "Error while reading previously read values: #{$!}"
            lReadValues = nil
          end
        else
          lReadValues = {
            :LastPos => 0,
            :LastUpdate => Time.parse('1970-01-01 00:00:00 UTC')
          }
        end
        if (File.exists?(iConf[:FileName]))
          lUpdateTime = File.stat(iConf[:FileName]).mtime
          if (lUpdateTime != lReadValues[:LastUpdate])
            # The file was modified
            # If the size is smaller, read from the beginning
            lStartPos = nil
            if (File.size(iConf[:FileName]) <= lReadValues[:LastPos])
              lStartPos = 0
            else
              lStartPos = lReadValues[:LastPos]
            end
            # Read file
            File.open(iConf[:FileName], 'r') do |iFile|
              iFile.seek(lStartPos)
              iFile.read.split("\n").each do |iLine|
                # Match the line against filters
                if (iConf[:Filters] == nil)
                  report iLine
                else
                  lMatch = false
                  iConf[:Filters].each do |iFilter|
                    if (iLine.match(iFilter) != nil)
                      lMatch = true
                      break
                    end
                  end
                  if (lMatch)
                    # Report this line
                    report iLine
                  end
                end
              end
              lReadValues[:LastPos] = iFile.pos
            end
            lReadValues[:LastUpdate] = lUpdateTime
          end
        else
          report "!!! Missing file #{iConf[:FileName]}"
          lReadValues[:LastPos] = -1
        end
        # Write back read values
        File.open(lReadValuesFileName, 'w') do |oFile|
          oFile.write(Marshal.dump(lReadValues))
        end
      end

    end

  end

end
