#--
# Copyright (c) 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rUtilAnts/Misc'
RUtilAnts::Misc::initializeMisc

module SheepDog

  module Monitors

    class Top

      # Execute the monitoring process for a given configuration
      #
      # Parameters:
      # * *iConf* (<em>map<Symbol,Object></em>): The monitor configuration
      def execute(iConf)
        lLstTopOutput = `top -b -p0 -n1 | head -4`.split("\n").map { |iLine| iLine.strip }
        # The loads
        if (iConf[:Limits][:Loads] != nil)
          lLine = lLstTopOutput[0]
          lMatch = lLine.match(/load average: ([^,]+), ([^,]+), ([^,]+)$/)
          if (lMatch == nil)
            report "Unable to decode top output for loads: \"#{lLine}\"."
          else
            lTopValues = lMatch[1..3].map { |iStrValue| iStrValue.to_f }
            3.times do |iIdx|
              if ((iConf[:Limits][:Loads][iIdx] != nil) and
                  (lTopValues[iIdx] > iConf[:Limits][:Loads][iIdx]))
                report "Value ##{iIdx} of load exceeds limit: #{lTopValues[iIdx]} > #{iConf[:Limits][:Loads][iIdx]}"
              end
            end
          end
        end
        # The memory
        if (iConf[:Limits][:Memory] != nil)
          lLine = lLstTopOutput[3]
          lMatch = lLine.match(/\s+(\S+) used,\s+(\S+) free/)
          if (lMatch == nil)
            report "Unable to decode top output for memory: \"#{lLine}\"."
          else
            lMemUsed, lMemFree = lMatch[1..2].map do |iStrValue|
              rValue = nil
              # Convert k and m modifiers
              if (iStrValue[-1..-1] == 'k')
                rValue = iStrValue[0..-2].to_i * 1024
              elsif (iStrValue[-1..-1] == 'm')
                rValue = iStrValue[0..-2].to_i * 1024 * 1024
              else
                rValue = iStrValue[0..-2].to_i
              end
              next rValue
            end
            if ((iConf[:Limits][:Memory][:MaxUsed] != nil) and
                (lMemUsed > iConf[:Limits][:Memory][:MaxUsed]))
              report "Used memory exceed maximal limit: #{lMemUsed} > #{iConf[:Limits][:Memory][:MaxUsed]}"
            end
            if ((iConf[:Limits][:Memory][:MinFree] != nil) and
                (lMemFree < iConf[:Limits][:Memory][:MinFree]))
              report "Free memory below minimal limit: #{lMemFree} < #{iConf[:Limits][:Memory][:MinFree]}"
            end
          end
        end
      end

    end

  end

end
