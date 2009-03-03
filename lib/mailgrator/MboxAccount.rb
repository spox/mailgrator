['MailAccount', 'MailboxListMbox'].each{|f| require "mailgrator/#{f}"}

module MailGrator
    class MboxAccount < MailAccount

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