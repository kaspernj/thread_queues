class ThreadQueues::BlockingQueue
  def initialize
    @que = []
    @mutex = Mutex.new
    @cond_read = ConditionVariable.new
    @cond_write = ConditionVariable.new
    @num_waiting = 0
  end

  def push(obj)
    loop do
      @mutex.synchronize do
        raise EOFError, "Cannot write to closed queue" if @closed

        if @num_waiting > 0 && @que.empty?
          @que.push(obj)
          @cond_write.signal
          return nil
        else
          @cond_read.wait @mutex
        end
      end
    end
  end

  def pop
    loop do
      @mutex.synchronize do
        raise EOFError, "Queue is empty and closed" if @que.empty? && @closed

        if @que.empty?
          @num_waiting += 1

          begin
            @cond_read.signal
            @cond_write.wait @mutex
          ensure
            @num_waiting -= 0
          end
        else
          return @que.shift
        end
      end
    end
  end

  def close
    @mutex.synchronize do
      @closed = true
    end
  end
end
