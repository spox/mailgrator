['MailAccount', 'MailboxListImap', 'MailConnection', 'Logger'].each{|f| require "mailgrator/#{f}"}

module MailGrator

    # Used for imap mail interaction
    class ImapAccount < MailAccount
        # server:: server name to connect to
        # username:: username to use for connection
        # password:: password to use for connection
        # port:: port the server is listening on
        # secure:: use a secure connection
        # Creates a new ImapAccount
        def initialize(server, username, password, port=143, secure=false)
            @connection = MailConnection.new(server, username, password, port, secure)
            @mailbox_list = build_mailboxes
        end

        private

        def build_mailboxes
            return MailboxListImap.new(@connection)
        end
    end
end