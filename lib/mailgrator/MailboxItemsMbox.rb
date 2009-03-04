['Exceptions', 'Logger'].each{|f| require "mailgrator/#{f}"}
module MailGrator
    class MailboxItemsMbox
        # path:: path to mbox
        # mailbox:: mailbox to open
        # files:: MboxFiles to use
        # delimiter:: system path delimiter
        # Creates new MailboxItemsMbox
        def initialize(path, mailbox, files, delimiter='/')
            @files = files
            @path = path
            @mailbox = mailbox
            @delim = delimiter
            @full_path = path
            @EOFhit = false
            @uploaded_ids = Array.new
            @message_ids = Array.new
            @ID_complete = false
            @ID_thread = nil
            @current_location = 0
            @is_dir = false
            @true_file = nil
            locate_file
        end

        # Waits for thread to complete
        def id_wait_complete
            @ID_thread.join unless @ID_thread.nil?
            @ID_thread = nil
        end

        # return message ids for given box
        def message_ids
            return @message_ids
        end

        # msg_ids:: array of IDs
        # IDs to skip
        def skip_messages(msg_ids)
            raise InvalidType.new(Array, msg_ids.class) unless msg_ids.is_a?(Array)
            @uploaded_ids = msg_ids
        end

        # Fetches next message
        def fetch_next_message
            raise IsDirectory.new(@full_path) if @is_dir
            @files.read_message(@true_file, @uploaded_ids)
        end

        # fetches all IDs
        def fetch_IDs
            @ID_thread = Thread.new do
                if(File.directory?(@full_path))
                    Logger.info("Fetch IDs requestd on directory instead of file. Returning empty set. (#{@full_path})"
                else
                    begin
                        while(line = @file.readline) do
                            if(line =~ /^message-id: (.+)$/i)
                                @message_ids.push($1.strip)
                            end
                        end
                    rescue EOFError
                        @file.rewind
                        Logger.info("Reached end of file for fetching IDs at: #{@full_path}")
                    rescue Object => boom
                        Logger.warn("Encountered error reading file for fetching IDs at: #{@full_path}: #{boom}")
                    end
                end
                @ID_complete = true
            end
        end

        private

        def locate_file
            if(File.directory?(@full_path))
                @is_dir = true
            else
                dir = @full_path.gsub(/\/[^\/]+$/, '')
                Logger.info("Full path: #{@full_path} reduced to: #{dir}")
                name = nil
                if(@full_path =~ /^.+\/([^\/]+)$/)
                    name = $1
                else
                    name = @full_path
                end
                Logger.info("Name to match against: #{name}")
                directroy = Dir.new(dir)
                match = nil
                directory.each do |item|
                    match = item if item =~ /^#{name}\..+$/
                end
                raise UnknownMboxFile(mailbox) if match.nil?
                @true_file = dir+@delim+match
                Logger.info("Found file #{match} for mailbox: #{mailbox}")
            end
        end
    end
end