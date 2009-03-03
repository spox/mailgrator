['MailAccount', 'MailboxListMbox'].each{|f| require "mailgrator/#{f}"}

module MailGrator
    # Used for mbox mail interaction
    class MboxAccount < MailAccount
        # path:: Path to mbox file
        # Creates a new MboxAccount
        def initialize(path)
            @path = path
            @mailbox_list = build_mailboxes
        end

        private

        def build_mailboxes
            return MailboxListMbox.new(@path)
        end
        
    end
end