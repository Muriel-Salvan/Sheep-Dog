#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

require 'rUtilAnts/Misc'
RUtilAnts::Misc::install_misc_on_object

module SheepDog

  module Monitors

    class Top

      include SheepDog::Common

      # Execute the monitoring process for a given configuration
      #
      # Parameters::
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
            lMemUsed, lMemFree = lMatch[1..2].map { |iStrValue| quantity2Int(iStrValue) }
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
