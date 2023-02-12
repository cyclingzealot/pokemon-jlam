require "csv"

module Loadable

  # Ideally I'd like this to be in sge/lib/prompt.rb,
  # but I was having trouble loading it (circular dependency)
  # Returns false if the user does not enter Y or timeouts
  def get_prompt(question, timeoutSecs = 10)
    require "timeout"
    STDOUT.print "#{question} (Y/n) > "

    begin
      prompt = Timeout::timeout(timeoutSecs) { STDIN.gets.chomp }
      if prompt == "Y"
        return true
      else
        return false
      end
    rescue Timeout::Error
      puts "\nTimeout exceeded..... doing nothing!"
      return false
    end
  end

  def log_not_imported(hashes)
    require "pp"
    logLocation = "log/import_clients#{DateTime.now.strftime("-%Y%m%d-%H%M%S")}.log"
    File.open(logLocation, "ab") do |f|
      f.puts "\n\n"
      f.puts ["===", DateTime.now, "=" * 100].join(" ")
      hashes.each_with_index { |hash, i|
        printProgress("Logging not imported... ", i, hashes.count)
        f.puts "Could not import #{hash.pretty_inspect}"
      }
      f.puts "\n\n"
    end

    return logLocation
  end

  ########################################################################
  # Detect what seperator is most likely used in a csv file
  ########################################################################
  def self.detectSeperator(filePath)
    seperators = [";", ":", "\t", ",", "|"]
    begin
      firstLine = File.open(filePath, &:readline)
    rescue EOFError => e
      $stderr.puts "EOFError while reading file #{filePath}"
      raise e
    end

    seperator = seperators.max_by { |s|
      firstLine.split(s).count
    }

    #Sanity check on column count
    secondLine = IO.readlines(filePath)[1]

    headersCount = firstLine.split(seperator).count
    columnsCount = secondLine.split(seperator).count

    raise "Using seperator '#{seperator}', there are #{headersCount} of them in the first (header) line but #{columnsCount} in the second line in #{filePath}" if headersCount != columnsCount

    return seperator
  end

  def checkMapping(mapping)
    cloneWithoutCommentKeys(mapping).each { |attribute, csvHandler|
      # Is the attribute in the table column keys  or is in the assocations

      methodToLookFor = attribute.to_s
      methodToLookFor += "=" if attribute != :id

      if (not self.columns_hash.keys.include?(attribute.to_s)) and self.reflect_on_association(attribute).nil? and not self.instance_methods.include?(methodToLookFor.to_sym)
        raise "#{self} does not respond to #{methodToLookFor}"
      end
    }
  end

  ########################################################################
  # Update data in models according to csv file
  # @param [String] filePath The path of the file
  # @param [Hash] mapping Mapping of model attribute (in the form of a symbol) => csv header (string)
  #
  #               See Service::IMPORT_ROW for a good example.
  #
  #               If ImportMapping == :symetric, it will expect all csv columns to exacly
  #                   match class attributes (ex: CPQ export & import)
  #
  #               In basic case, it can be
  #                   :modelAttribute => "$csvHeaderName"
  #
  #               The code can handle quite allot of special cases.
  #               In particular, if the attribute is an association to another object
  #                   the code will take care of looking up the other classes's
  #                   IMPORT_PRIMARY_KEY constant if the value (in the csv row) is numeric OR
  #                   IMPORT_IDENTIFIER if the value (in the csv) row is a string.  In retrospect, this is probably not the right approach to decide between IMPORT_PRIMARY_KEY and IMPORT_IDENTFIER
  #
  #               If mapping is nil, it will look in the model's IMPORT_MAPPING constant.
  #
  #               If you need to feed it an object, use
  #                    :modelAttribute => {
  #                       :csvHeader  => "$csvHeaderName",
  #                       :code       => Proc.new { |csvValue| Client.find(csvValue) }]
  #                     }
  #               where :modelAttribute is the name of the attribute of your
  #                   model
  #               The value between || needs to be somewhere in your code block
  #
  #               The above is not neccesarry if the relationship is already
  #               described in the rails model.  It will detect and search
  #               according to eihter:
  #               * the IMPORT_PRIMARY_KEY of the associated model IF
  #                       the value in the csv row is numeric OR
  #               * the IMPORT_IDENTIFER IF the value in the csv row is a string
  #
  #               If you need to give it a value calculated at run time,
  #                   the code can also handle
  #                   :modelAttribute => {:exec => Proc.new {...your code}}
  #               (ex: returning the current date time)
  #
  #               You can also give it the entire row with
  #                   :modelAttribute => {:rowHandler => Proc.new {|row| ...your code}}
  #
  #               The difference between
  #                   :modelAttribute => {:exec => Proc.new {...your code}}
  #                       and
  #                   :modelAttribute => {:rowHandler => Proc.new {|row| ...your code}}
  #                       is that :rowHandler takes a row argument, but :exec does not
  #
  #               If you need to feed it either two values, give it
  #                   :modelAttribute => ["csvHeader1", "$csvHeader2"]
  #               If you need to feed it a constant, give it
  #                   :modelAttribute => {:literal => false}
  #                   :modelAttribute => {:literal => 3}
  #                   :modelAttribute => {:literal => "a string"}
  #               The method will take care of plucking the csvValue in the right spot.
  # @param [Hash] primaryKeyColumn A hash with {csvColumn => :modelAttribute}
  #               used to match row to object for updating.  This can be
  #               A string: csv header to use to search for the object
  #               A proc: it will be fed dataEntrry, which is the hash after processing mapping.  For example, if you had a column of BTNs, you could do in your mapping:
  #                       '#BTN' => 'btn'
  #                   and your primary key would be
  #                       primaryKeyColumn = Proc.new {|row| Client.find_by_btn(row['#BTN'])}
  #                   The hash in '#BTN' makes it such that mapping will bring the value into dataEntry hash as valuable info, but will not attempt to save that bit of data.
  #               An array: arguments to be fed to .where_one method
  #
  #               nil : defaults to using self.IMPORT_PRIMARY_KEY
  #               false : Don't update, just create (not implemented)
  # @param [Hash] options Give the follow options
  # @opts [boolean] :dontCreate Report object as error if can't be found
  # @opts [boolean] :truncate trunate Truncate the table before. Not implemented.
  # @opts [boolean] :skipCondition Skip this row if the proc returns true.  Proc is fed the csv row
  ########################################################################
  def update_from_csv(filePath, mapping = nil, primaryKeyColumn = nil, options = {})
    raise "No filePath specified (nil or blank)" if filePath.blank?
    raise "File #{File.expand_path(filePath)} does not exist" if not File.exist?(File.expand_path(filePath))

    if mapping.nil? and self::IMPORT_MAPPING.nil?
      raise "No mapping defined: both mapping and #{self.name}.IMPORT_MAPPING constant are nil"
    end

    knownOptions = [:seperator, :skipCondition, :skipPostImport, :maxElapsedMinutes, :dontUpdate, :dontCreate, :noPrompt, :notEmpty, :alreadyInDb]
    unknownOptions = (options.keys - knownOptions)
    if unknownOptions.count > 0
      msg = "WARNING: unkown option #{unknownOptions.map { |o| o.to_s }.join(", ")}"
      puts "\n#{msg}\n"
      Rails.env.development? ? byebug : (sleep 5)
      sleep 1
    end

    beforeCount = self.count

    mapping = self::IMPORT_MAPPING if mapping.nil?

    seperator = (ENV["seperator"] or options[:seperator])
    seperator = Loadable::detectSeperator(filePath) if seperator.nil?

    # I would have prefered putting :symetric in a module constant, but rails couldn't find
    # ActiveRecord::Loadable::SYMETRIC_MAPPING
    if mapping == :symetric
      mapping = createSymetricMapping(filePath, seperator)
      #primaryKeyColumn = :id if primaryKeyColumn.nil?
    end

    if not mapping.is_a?({}.class)
      raise "Somehow I did not end up with a hash for mapping.  mapping was a #{mapping.class}: #{mapping.to_s[0..100]}"
    end

    # Add a mapping to :imported_at if nil. This forces timestamping the import for better data import management
    if mapping[:imported_at].nil?
      mapping = mapping.merge({ :imported_at => {
        exec: Proc.new { DateTime.now() },
      } })
    end

    checkMapping(mapping)

    notLoaded = []
    dataInHashes = []
    rowsImported = 0
    CSV.open(filePath, "r:bom|utf-8", headers: :first_row, col_sep: seperator) do |csv|
      totalLines = `wc -l "#{filePath}"`.strip.split(" ")[0].to_i - 1
      if ((options[:noPrompt].nil? or options[:noPrompt] == false) and (get_prompt("Load #{filePath} (#{totalLines} lines)?") == false))
        next
      end

      #Create a hash of stats
      desiredStats = ["Objects created", "Objects updated", "Rows skipped", "Objects not created", "Objects already in, not created"]
      stats = Hash[desiredStats.collect { |stat| [stat, 0] }]

      ### Read data ########################################################
      beginImportTS = DateTime.now
      count = 0
      #csv.rewind

      lastCheck = DateTime.now - 1.day
      csv.each do |row|
        count += 1
        pctError = ((notLoaded.count * 100.to_f) / totalLines).round

        if (DateTime.now >= lastCheck + 1.seconds or totalLines < 50 or count == totalLines)
          printProgress("Reading #{filePath} (#{pctError}% errors)", count, totalLines)
          lastCheck = DateTime.now
        end

        #byebug if Rails.env.development? and csv.headers.first.size > 2

        begin
          if options[:skipCondition].class == Proc
            #byebug if Rails.env.development? and row["0wi
            if options[:skipCondition].call(row)
              stats["Rows skipped"] += 1
              next
            end
          end

          # All columns blank
          if row.to_h.values.uniq.reject { |v| v.blank? }.count == 0
            stats["Rows skipped"] += 1
            next
          end

          if row.to_h.values.first == "Ran on"
            stats["Rows skipped"] += 1
            next
          end

          entry = processMappingAndRow(row, mapping)
          dataInHashes << entry
        rescue => e
          row[:errorMsg] = e.message + " (#{e.backtrace[0]})"
          notLoaded << row
          if notLoaded.count < 4
            $stderr.puts "Could not read\n#{row}"
            byebug if Rails.env.development?
          end
        end
      end
      puts "\n"

      ### Create or update data ############################################
      total = dataInHashes.length
      count = 0

      lastCheck = DateTime.now - 1.day
      totalHashes = dataInHashes.count
      dataInHashes.each do |dataEntry|
        count += 1

        pctError = ((notLoaded.count * 100.to_f) / totalLines).round

        if (DateTime.now >= lastCheck + 1.seconds or totalLines < 50 or count == totalHashes)
          printProgress("Updating / creating data (#{notLoaded.count} (#{pctError}%) errors)", count, dataInHashes.count)
          lastCheck = DateTime.now
        end

        object = nil

        if not options[:maxElapsedMinutes].nil? and options[:maxElapsedMinutes].to_i
          if ((DateTime.now - beginImportTS).to_f) * 60 * 24 > options[:maxElapsedMinutes].to_i
            $stderr.puts "#{options[:maxElapsedMinutes].to_i} max minutes elapsed"
            break
          end
        end

        begin
          object = nil

          dontUpdate = nil
          dontUpdate = options[:dontUpdate] if options[:dontUpdate].present?
          dontUpdate ||= self::IMPORT_DONT_UPDATE if defined?(self::IMPORT_DONT_UPDATE)

          alreadyInDb = nil
          alreadyInDb = options[:alreadyInDb] if options[:alreadyInDb].present?
          alreadyInDb ||= self::IMPORT_ALREADY_IN if defined?(self::IMPORT_ALREADY_IN)

          # dontUpdate is deprecated, we use alreadyInDb now
          if alreadyInDb.nil? and dontUpdate.present?
            alreadyInDb = :alwaysCreate if dontUpdate == true
          end

          #byebug if (Rails.env.development? and dataEntry[:name] == "PROGCLASSIC4B-MSTEAMS")

          #byebug if Rails.env.development? and (0..100).to_a.sample < 30
          #We enter this section if alreadyInDb == :skip, cause ...
          #we need to know if it's already in the database
          if (alreadyInDb.nil? or [:skip, :update].include?(alreadyInDb))
            if primaryKeyColumn.nil? and defined?(self::IMPORT_PRIMARY_KEY)
              primaryKeyColumn = self::IMPORT_PRIMARY_KEY
            end

            raise "Not sure I should have a nil or empty key.  Primary key column was #{primaryKeyColumn}" if (primaryKeyColumn.blank?)

            object = findObject(dataEntry, primaryKeyColumn)
          end

          #byebug if (Rails.env.development? and object.present?)

          if object.nil? or alreadyInDb == :alwaysCreate
            # Object not found lets create
            if options[:dontCreate] == true
              stats["Objects not created"] += 1
            else
              self.create!(cloneWithoutCommentKeys(dataEntry))
              stats["Objects created"] += 1
            end
          elsif (alreadyInDb.nil? or alreadyInDb != :skip)
            # Object found, lets update
            object.update(cloneWithoutCommentKeys(dataEntry))
            object.save!
            stats["Objects updated"] += 1
          elsif alreadyInDb == :skip
            stats["Objects already in, not created"] += 1
          elsif alreadyInDb == :raiseException
            msg = "Object #{object.to_s} already exists (#{object.class.name} #{object.id})"
            byebug if Rails.env.development?
            raise msg
          else
            msg = "Undefined behavior for alreadyInDb == #{alreadyInDb.to_s}, " + (object.nil? ? "nil" : "present") + " object"
            byebug if Rails.env.development?
            raise msg
          end
        rescue => e
          dataEntry[:errorMsg] = e.message + " (#{e.backtrace[0]})"
          notLoaded << dataEntry
          if notLoaded.count < 4
            $stderr.puts "Could not update or create #{dataEntry}"
            byebug if Rails.env.development?
            $stderr.puts e.backtrace if notLoaded.count <= 2
          end
        end
      end
      puts "\n"

      endImportTS = DateTime.now

      if (defined?(self::IMPORT_DELETE_NOT_UPDATED) and self::IMPORT_DELETE_NOT_UPDATED)
        toDelete = self.where(imported_at: nil)
        stats["Rows 'deleted' or *deleted*"] = toDelete.count
        toDelete.delete_all
      end

      rowsImported = stats["Objects updated"] + stats["Objects created"]

      puts "#{beforeCount} #{self.name} objects in database before creation"
      puts "#{self.count} #{self.name} objects in database after creation"
      puts "#{((endImportTS - beginImportTS) * 60 * 24).to_f.round(2)} minutes for import"

      stats["Rows not imported"] = notLoaded.count
      stats.each { |label, number| puts "#{label}: #{number} (#{((number * 100.to_f) / totalLines).round(2)} %)" }

      if notLoaded.count > 0
        logLocation = log_not_imported(notLoaded)
        $stderr.puts "See #{Rails.root}/#{logLocation} for details on not loaded objects"
      end
    end

    self::import_post_exec if (rowsImported > 0 and self.respond_to?(:import_post_exec) and (options[:skipPostImport].nil? or options[:skipPostImport] == false))

    return rowsImported
  end

  protected

  def cloneWithoutCommentKeys(hash)
    copy = hash.clone

    copy.each { |key, value|
      if key.is_a?(String) and key.start_with?("#")
        copy.delete(key)
      end
    }
    return copy
  end

  # With ActiveRecord::Loadable.findObject, the proc must actually return an object
  # dataEntry has gone through processMappingAndRow, but not cloneWithoutCommentKeys yet,
  # so comment entries from IMPORT_BW_MAPPING should still be there and could be used
  def findObject(dataEntry, key)
    case key
    when Symbol, String
      raise "No way to find primary key #{key} in #{dataEntry}" if not dataEntry.keys.include?(key)
      value = dataEntry[key]
      raise "Null primary key with key #{key} and data #{dataEntry}" if value.nil?
      object = self.unscope(:where).find_by("#{key.to_s} = ?", value)
    when Array
      # By this point, dataEntry has already been mapped to the classes' attributes.  So we don't map do csv columns.
      whereArgs = key.map { |k|
        [k, dataEntry[k]]
      }.to_h
      object = self.where_one(*whereArgs)
    when Proc
      object = key.call(dataEntry)
    else
      raise "I don't know how to find objects with #{key.class.name}"
    end

    return object
  end

  def checkRow(row, key)
    # If the column can't be found, raise an error after suggesting a hint what might be wrong
    if not row.has_key?(key)
      msg = "Row does not have entry #{key}"

      hint = ":\n#{row.headers}\n#{row}"

      byebug if Rails.env.test?

      if row.to_h.keys.map(&:to_s).include?(key)
        hint = ".  Seems like the row has it's keys in the wrong class, likely symbols. "
      elsif row.to_h.keys.map { |k| k.to_s.strip.gsub("\xEF\xBB\xBF".force_encoding("UTF-8"), "") }.include?(key)
        hint = ".  Looks like there's a hidden character causing a mismatch (likely UTF BOM). "
      end

      hint += "\n"

      msg += hint

      byebug if Rails.env.development?

      raise msg
    end
  end

  ########################################################################
  # See documentation for update_from_csv for sturcture of args
  ########################################################################
  def processMappingAndRow(row, mapping)
    returnHash = {}

    mapping.each { |classAttribute, csvHandler|
      begin
        value = nil

        case csvHandler.class.name
        when "String"
          #byebug if classAttribute == :supplier

          checkRow(row, csvHandler)

          # Here, we just want the value of the cell from the column
          # that has the value in csvHandler as a column
          value = row[csvHandler]

          # Detect if it's an assocation, and if it is, use
          # reflection to get the class
          # See https://stackoverflow.com/questions/3234991/what-is-the-class-of-an-association-based-on-the-foreign-key-attribute-only
          if not self.reflect_on_association(classAttribute).nil? and (not value.nil?) and (not value.empty?)
            associationClassName = self.reflect_on_association(classAttribute).class_name
            assocClass = Object.const_get(associationClassName)

            # This lets up speed up coding for classes that are structured like enumerator
            # or when the client can't be bothered to look up rails ID
            if value.numeric?
              assocImportKey = assocClass::IMPORT_PRIMARY_KEY
              valueObj = assocClass.find_by(assocImportKey => value)
            else
              assocImportKey = assocClass::IMPORT_IDENTIFIER
              searchObjs = assocClass.where("lower(#{assocImportKey}) = ?", value.downcase)
              raise "More than one found for #{assocImportKey} = #{value} (case insensitive)" if searchObjs.count > 1
              valueObj = searchObjs.take
            end

            if valueObj.nil?
              raise "No object found for rails assocation for attribute #{classAttribute} using #{assocClass}.find_by(#{assocImportKey} => #{value})"
            else
              value = valueObj
            end
          end

          # Get the column data to see if we can do a smart transformation
          # ex: boolean, datetime, decimal
          columnData = self.columns_hash[classAttribute.to_s]
          if (not columnData.nil?)
            case columnData.sql_type_metadata.type

            when :boolean
              value = (%w(1 yes true oui vrai t v).include?(value.to_s.downcase.strip))
            when :datetime
              value = DateTime.parse(value) if value.present?
            when :decimal
              # Definitely french number formatting and we know how to take care of it
              if value.present?
                value = value.gsub(" ", "") if value.include?(" ")

                # What to do with commas?
                if value.include?(",")
                  # More than one comma: english formatting, eliminate them
                  value = value.gsub(",", "") if /,/.match(value).to_a.count > 1

                  # A comma and a period: english formatting, eliminate them
                  value = value.gsub(",", "") if /,[0-9]{3}\./.match(value).to_a.count = 1

                  # Unambiguous french decimal use of comma, swap it with period
                  # Ie: it is not a comma, followed by 3 decimals
                  if /,[0-9]{3}$/.match(value).to_a.count == 0
                    value = value.gsub(",", ".")
                  else
                    raise "Ambiguous usage of a comma for a decimal (comma followed by 3 decimals.  You will have to edit your data."
                  end
                end

                value = BigDecimal.new(value)
              end
            else
              nil # variable 'value' keep it as is
            end
          end
        when "Array"
          # This should probably changed to a hash, where you
          # can feed it the keys :columns and :default

          # We are picking the first non false value of the array
          value = row.to_h.select { |k, v|
            #Keep the elements of the row specified in csvHandler
            csvHandler.include?(k)
          }

          # select the ones that return true, and pick the first value
          value = value.select { |k, v| v }.values.first

          if value.nil?
            value = csvHandler.last
          end
        when "Hash"
          if csvHandler.keys.first == :literal
            value = csvHandler.values.first
          elsif csvHandler.keys.include?(:code)
            checkRow(row, csvHandler[:csvHeader])
            csvValue = row[csvHandler[:csvHeader]]
            value = csvHandler[:code].call(csvValue)

            if value.nil? and csvValue.present?
              raise "For string #{csvValue} under column #{csvHandler[:csvHeader]}, got nil object from Proc defined at #{csvHandler[:code].to_s} ."
            end
          elsif csvHandler.keys.include?(:rowHandler)
            value = csvHandler[:rowHandler].call(row)
          elsif csvHandler.keys.include?(:exec)
            value = csvHandler[:exec].call()
          else
            raise "Don't know what to do with the hash #{csvHandler.to_s}"
          end
        else
          raise "Don't know what to do with a csvHandler of type #{csvHandler.class.name} used for attribute #{classAttribute.to_s}.  String representation of that csvHandler is:\n#{csvHandler.to_s}"
        end

        returnHash[classAttribute] = value
      rescue Exception => e
        puts "Error with #{classAttribute.to_s}"

        # Don't stop all the time
        # Maybe there's a way I can add a piece of data to the exception?
        byebug if Rails.env.development? and DateTime.now.second % 4 == 0

        raise e
      end
    }

    returnHash
  end

  def createSymetricMapping(filePath, seperator)
    headers = nil
    CSV.open(filePath, "r:bom|utf-8", headers: :first_row, col_sep: seperator) do |csv|
      csv.first
      headers = csv.headers
      if headers.first != "id" and Rails.env.development?
        puts "The first column header is not 'id', are you sure  the file is correct?"
        byebug
        nil
      end
      csv.rewind
    end

    headers.delete("imported_at")

    mapping = headers.map { |header| [header.to_sym, header] }.to_h

    return mapping
  end

  ########################################################################
  # Just print a line to indicate progress
  # @param [String] doingWhatStr What do you want to tell the user you are doing
  ########################################################################
  def printProgress(doingWhatStr, count, total, zeroBased = false)
    count += 1 if zeroBased == true
    puts "Started #{DateTime.now.strftime("%H:%M:%S")}" if count == 1
    progressStr = "#{count} / #{total} #{(count.to_f * 100 / total).round} %"
    print ("\u001b[1000D" + progressStr + " : " + doingWhatStr)
    if count == total
      puts "\n"
      puts "Last one #{DateTime.now.strftime("%H:%M:%S")}"
      puts "\n"
    else
      print "... "
    end
  end
end
