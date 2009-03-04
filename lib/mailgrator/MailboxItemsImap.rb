['Exceptions', 'Logger'].each{|f| require "mailgrator/#{f}"}
module MailGrator
    class MailboxItemsImap

        # connection:: MailConnection to IMAP server
        # mailbox:: mailbox
        # delimiter:: delimiter to use
        # Creates new MailboxItemsImap
        def initialize(connection, mailbox, delimiter)
            @connection = connection
            @mailbox = mailbox
            @delim = delimiter
            @message_ids = Array.new
            @ID_complete = false
            @ID_thread = nil
            Logger.info("Checking mailbox #{mailbox}")
            unless(@connection.current_mailbox == @mailbox.gsub('/', @delim))
                @connection.change_mailbox(@mailbox.gsub('/', @delim), true)
            end
            fetch_IDs
        end

        # Wait for ID fetcher thread to complete
        def id_wait_complete
            @ID_thread.join unless @ID_thread.nil?
            @ID_thread = nil
        end

        # Message IDs in this mailbox
        def message_ids
            return @message_ids
        end

        # id:: message ID
        # Fetch message with given ID
        def fetch_msgid(id)
            raise InvalidMessageID.new(id) unless @message_ids.include?(id)
            return fetch_message_seqno(@message_ids.index(id))
        end

        # num:: index message is located at
        # Fetch message at given index
        def fetch_message_seqno(num)
            return @connection.imap.fetch(num, 'BODY')
        end

        # message:: full email message
        # Adds email message to mailbox
        def add_message(message)
            @connection.append_message(@mailbox.gsub('/', @delim), message)
        end

        private

        def fetch_IDs
            Logger.info("Fetching message-ids for #{mailbox}")
            @ID_thread = Thread.new do
                @connection.imap.fetch(1..-1, 'ENVELOPE').each do |id|
                    @message_ids << id.attr['ENVELOPE'][:message_id]
                    Logger.info("Fetched message: #{id.attr['ENVELOPE'][:message_id]}")
                end
                Logger.info("Fetched #{@message_ids.size} message UIDs from #{@mailbox}")
                @ID_complete = true
            end
        end
    end
end