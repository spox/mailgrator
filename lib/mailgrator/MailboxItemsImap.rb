['Exceptions', 'Logger'].each{|f| require "mailgrator/#{f}"}
require 'net/imap'
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
            @skip_messages = []
            @last_message = 0
            Logger.info("Checking mailbox #{mailbox}")
            unless(@connection.current_mailbox == @mailbox.gsub('/', @delim))
                @connection.change_mailbox(@mailbox.gsub('/', @delim))
            end
            fetch_IDs
        end

        def skip_messages(msg_ids)
            @skip_messages = msg_ids
        end
        
        def fetch_next_message
            raise EOFolder.new if @message_ids.empty? || @last_message >= @message_ids.size
            begin
                msg_id = @message_ids[@last_message]
                @last_message += 1
                raise DuplicateMessage.new(msg_id) if @skip_messages.include?(msg_id)
                return fetch_msgid(msg_id)
            rescue MessageDuplicate => boom
                Logger.warn("Duplicate message found: #{boom.message_id}. Skipping")
                retry
            end
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
            Logger.info("Message id to fetch: #{id}")
            raise InvalidMessageID.new(id) unless @message_ids.include?(id)
            return fetch_message_seqno(@message_ids.index(id) + 1)
        end

        # num:: index message is located at
        # Fetch message at given index
        def fetch_message_seqno(num)
            Logger.info("Message sequence number: #{num}")
            @connection.change_mailbox(@mailbox.gsub('/', @delim))
            return @connection.imap.fetch(num, 'RFC822')[0][1]['RFC822']
        end

        # message:: full email message
        # Adds email message to mailbox
        def add_message(message)
            @connection.append_message(@mailbox.gsub('/', @delim), message)
        end

        private

        def fetch_IDs
            Logger.info("Fetching message-ids for #{@mailbox}")
            @ID_thread = Thread.new do
                begin
                    msgs = @connection.imap.fetch(1..-1, 'ENVELOPE')
                    unless(msgs.nil?)
                        msgs.each do |id|
                            @message_ids << id.attr['ENVELOPE'][:message_id]
                            Logger.info("Fetched message: #{id.attr['ENVELOPE'][:message_id]}")
                        end
                        Logger.info("Fetched #{@message_ids.size} message UIDs from #{@mailbox}")
                    end
                    @ID_complete = true
                rescue Net::IMAP::ResponseParseError => boom
                    Logger.fatal("Failed to fetch mailbox list (#{@mailbox}). #{boom}")
                end
            end
        end
    end
end