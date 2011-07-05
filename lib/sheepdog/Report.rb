#--
# Copyright (c) 2011 Muriel Salvan (murielsalvan@users.sourceforge.net)
# Licensed under the terms specified in LICENSE file. No warranty is provided.
#++

module SheepDog

  # A report is a collection of entries, associated to a monitor run
  class Report

    # Title of the report
    #   String
    attr_reader :Title

    # File name of the report
    #   String
    attr_reader :ReportFileName

    # Time of this report's creation (UTC)
    #   Time
    attr_reader :CreationTime

    # Constructor
    def initialize
      @Entries = []
      @CreationTime = Time.now
      @ReportFileName = nil
      @Title = nil
    end

    # Add an entry to the report
    #
    # Parameters:
    # * *iEntry* (_String_): Entry to be added
    def addEntry(iEntry)
      @Entries << iEntry
    end

    # Set the report's title
    #
    # Parameters:
    # * *iTitle* (_String_): Report's title
    def setTitle(iTitle)
      @Title = iTitle
    end

    # Set the report's file name
    #
    # Parameters:
    # * *iFileName* (_String_): Report's file name
    def setReportFileName(iFileName)
      @ReportFileName = iFileName
    end

    # Get the report as simple text
    #
    # Return:
    # * _String_: The report as simple text
    def getSimpleText
      return @Entries.join("\n")
    end

    # Is this report empty ?
    #
    # Return:
    # * _Boolean_: Is this report empty ?
    def empty?
      return @Entries.empty?
    end

  end

end
