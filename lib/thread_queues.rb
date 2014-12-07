require "string-cases"

class ThreadQueues
  def self.const_missing(name)
    require_relative "thread_queues/#{::StringCases.camel_to_snake(name)}"

    if ::ThreadQueues.const_defined?(name)
      return ::ThreadQueues.const_get(name)
    end

    super
  end
end
