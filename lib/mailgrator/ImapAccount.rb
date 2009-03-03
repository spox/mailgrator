['MailAccount', 'MailboxListImap', 'MailConnection'].each{|f| require "mailgrator/#{f}"}

module MailGrator
    class ImapAccount < MailAccount
        def initialize(server, username, password, port=143, secure=false)
            @connection = MailConnection.new(server, username, password, port, secure)
            @mailbox_list build_mailboxes
        end

        private

        def build_mailboxes
            return MailboxListImap.new(@connection)
        end
    end
end