module MailGrator
    class MboxFiles
        def initialize
            @files = Hash.new
            @lock = Mutex.new
        end

        # name:: file name to add (full path)
        # Adds a file to the Mbox file list
        def add_file(name)
            @files[name] = nil unless @files.has_key?(name)
        end

        # name:: file name to remove (full path)
        # Removes a file from the Mbox file list
        def remove_file(name)
            @files.delete_at(name) if @files[name]
        end

        # name:: name of file to read next message from (full path)
        # uploaded_ids:: message-ids of already read messages
        # strip_emailchemy:: Strips header added by email alchemy converter
        # Reads next message from mbox file. Will raise duplicate
        # message error if message-id is found in uploaded_ids
        def read_message(name, uploaded_ids, strip_emailchemy=false)
            raise UnknownMbox.new(name) unless @files[name]
            raise EOFError.new if !@files[name].nil? && @files[name].closed?
            @lock.synchronize do
                @files[name] = File.open(name) if @files[name].nil?
                message = Array.new
                skip_message = false
                message_id = nil
                convert_header = !strip_emailchemy
                begin
                    currentpos = 0
                    while(line = @files[name].readline) do
                        if(message.size == 0 && line !~ /^From - ... ... .+?[0-9]{4}$/)
                            Logger.info('Line does not match message start. Skipping to next line.')
                            next
                        end
                        if(message.size != 0 && line =~ /^From - ... ... .+?[0-9]{4}$/)
                            @files[name].pos = currentpos - line.length
                            break
                        else
                            unless(skip_message)
                                if(line =~ /^message-id: (.+)$/i)
                                    message_id = $1.strip
                                    Logger.info("Checking message-id: #{message_id}")
                                    if(uploaded_ids.include?(message_id))
                                        Logger.warn("Duplicate message identified: #{message_id}")
                                        skip_message = true
                                    end
                                end
                                unless(convert_header)
                                    if(line =~ /^x-converted-by: emailchemy/i)
                                        convert_header = true
                                        next
                                    end
                                end
                                message.push(line)
                            end
                        end
                        currentpos = @files[name].pos
                    end
                rescue EOFError
                    Logger.info("Reached end of file: #{name}")
                    @files[name].close
                rescue Object => boom
                    Logger.warn("Unknown error processing #{name}: #{boom}")
                end
            end
            if(skip_message)
                raise MessageDuplicate.new(message_id)
            else
                message.delete_at(message.size - 1)
                return message.join('')
            end
        end
    end
end