require 'logger'
module MailGrator

    class Logger

        def Logger.initialize(output=nil, level=:fatal)
            if(output.nil?)
                @@log = nil
            else
                levels = {:info => Object::Logger::INFO, :warn => Object::Logger::WARN, :fatal => Object::Logger::FATAL}
                @@log = Object::Logger.new(output)
                @@log.level = levels.has_key?(level) ? levels[level] : Object::Logger::WARN
            end
        end

        def Logger.warn(s)
            unless @@log.nil?
                @@log.warn(s)
            end
        end

        def Logger.info(s)
            unless @@log.nil?
                @@log.info(s)
            end
        end

        def Logger.fatal(s)
            unless @@log.nil?
                @@log.fatal(s)
            end
        end

    end
end