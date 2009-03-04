module MailGrator
    class GratorException < Exception
    end
    
    class MessageDuplicate < GratorException
        attr_reader :message_id
        def initialize(m_id)
            @message_id = m_id
        end
    end

    class IsDirectory < GratorException
        attr_reader :path
        def initialize(path)
            @path = path
        end
    end

    class UnknownMbox < GratorException
        attr_reader :name
        def initialize(name)
            @name = name
        end
    end

    class UnknownMboxFile < GratorException
        attr_reader :mailbox
        def initialize(m)
            @mailbox = m
        end
    end

    class UnknownMailbox < GratorException
        attr_reader :mailbox
        def initialize(m)
            @mailbox = m
        end
    end

    class InvalidType < GratorException
        attr_reader :expected
        attr_reader :provided
        def initialize(expected, provided)
            @expected = expected
            @provided = provided
        end
    end

    class InvalidMessageID < GratorException
        attr_reader :message_id
        def initialize(m_id)
            @message_id = m_id
        end
    end

    class MailboxCreationFailure < GratorException
        attr_reader :boxes
        def initialize(b)
            @boxes = b
        end
    end

    class ReadOnlyMailbox < GratorException
        attr_reader :mailbox
        def initialize(m)
            @mailbox = m
        end
    end

    class EmptyAccounts < GratorException
        def initialize(s,d)
            @src = s.nil?
            @dest = d.nil?
        end

        def source_emtpy?
            @src
        end

        def dest_empty?
            @dest
        end
    end

    class ConnectionFailed < GratorException
        attr_reader :mail_exception
        def initialize(e)
            @mail_exception = e
        end
    end
end