#--
# Copyright (c) 2011 - 2012 Muriel Salvan (muriel@x-aeon.com)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module SheepDog

  module Common

    # Convert a string representing a memory quantity to its integer value.
    # Useful to decode top output, that uses k and m for its quantities.
    #
    # Parameters::
    # * *iStrValue* (_String_): The value as a string
    # Return::
    # * _Integer_: Corresponding value
    def quantity2Int(iStrValue)
      rResult = nil

      if (iStrValue[-1..-1] == 'k')
        rResult = iStrValue[0..-2].to_i * 1024
      elsif (iStrValue[-1..-1] == 'm')
        rResult = iStrValue[0..-2].to_i * 1024 * 1024
      else
        rResult = iStrValue.to_i
      end

      return rResult
    end

  end

end
