['Exceptions', 'MailConnection', 'MailboxItemsImap', 'Logger'].each{|f| require "mailgrator/#{f}"}
module MailGrator
    class MailboxListImap
        # connection:: IMAP MailConnection
        # Creates new MailboxListImap
        def initialize(connection)
            raise InvalidType.new(MailConnection, connection.class) unless connection.is_a?(MailConnection)
            @connection = connection
            @list = Hash.new
            @delim = nil
            build_list
        end

        # returns mailbox list
        def list
            build_list if @list.nil?
            return @list.keys
        end

        # mailbox:: mailbox
        # returns MailboxItemsImap
        def items(mailbox)
            unless(@list.has_key?(mailbox))
                trimmed = mailbox.gsub(/ \//, '/').strip
                if(@list.has_key?(trimmed))
                    Logger.info("Mailbox found after trimming. (#{trimmed})")
                    return @list[trimmed]
                else
                    Logger.info("Found new mailbox: #{trimmed}")
                    add_mailboxes([trimmed])
                    @list[trimmed] = MailboxItemsImap.new(@connection, trimmed, @delim) if !@list.has_key?(trimmed) || !@list[trimmed].is_a?(MailboxItemsImap)
                    @list[trimmed].id_wait_complete
                    return @list[trimmed]
                end
            else
                return @list[mailbox]
            end
            raise UnknownMailbox.new(mailbox)
        end

        # delimiter server is using
        def server_delimiter
            return @delim
        end

        # clist:: mailbox list
        # will remove duplicate mailboxes and return list
        # of mailboxes currently missing
        def missing(clist)
            raise InvalidType.new(Array, clist.class) unless clist.is_a?(Array)
            @list.each do |item|
                clist.delete(item) if clist.include?(item)
            end
            return clist
        end

        # list:: mailbox list
        # adds list of mailboxes
        def add_mailboxes(list)
            raise InvalidType.new(Array, list.class) unless clist.is_a?(Array)
            list.uniq!
            list.sort!
            failures = Array.new
            list.each do |box|
                begin
                    @connection.imap.create(box.gsub('/', @delim))
                    Logger.info("Created new mailbox: #{box}")
                rescue Net::IMAP::NoResponseError => boom
                    Logger.warn("Create mailbox received a no response header: #{boom}")
                rescue Object => boom
                    failures << box
                    Logger.warn("Failed to create mailbox #{box}: #{boom}")
                end
            end
            raise MailboxCreationFailure.new(failures) if failures.size > 0
            build_list if list.size > 0
        end

        private

        def build_list
            list = @connection.imap.list('', '*')
            list.each do |item|
                @delim = item[:delim]
                if !@list.has_key?(item[:name].gsub(item[:delim], '/')) || !@list[item[:name].gsub(item[:delim], '/')].is_a?(MailboxItemsImap)
                    @list[item[:name].gsub(item[:delim], '/')] = MailboxItemsImap.new(@connection, item[:name].gsub(item[:delim], '/'), item[:delim])
                    @list[item[:name].gsub(item[:delim], '/')].id_wait_complete
                end
            end
        end
    end
end