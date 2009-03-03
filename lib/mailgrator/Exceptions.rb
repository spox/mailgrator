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
end