['MailboxItemsMbox', 'Exceptions', 'Logger'].each{|f|require "mailgrator/#{f}"}

module MailGrator
    class MailboxListMbox
        # path:: path to directory containing mboxs
        # delim:: path delimiter
        # Creates a list of found mbox files
        def initialize(path, delim = '/')
            @path = path
            @dir = Dir.new(path)
            @list = Hash.new
            @delim = delim
            @files = MboxFiles.new
            build_list
        end

        # returns list of found mboxs
        def list
            return @list.keys
        end

        # mailbox:: name of mailbox (full path)
        # returns MailboxItemsMbox for given mailbox
        def items(mailbox)
            raise UnknownMailbox.new(mailbox) unless @list[mailbox]
            return @list[mailbox]
        end

        private

        def build_list
            add_items(@path)
        end

        def add_items(spath, base="INBOX")
            path = Dir.new(spath)
            path.each do |item|
                next if item == '.' || item == '..'
                if(File.directory?(spath + @delim + item))
                    add_items("#{spath}#{@delim}#{item}", "#{base}#{@delim}#{item}")
                end
                item.gsub!(/\.[^.]+$/, '')
                @list[base + @delim + item] = MailboxItemsMbox.new(spath + @delim + item, base + @delim + item, @files)
            end
        end
    end
end