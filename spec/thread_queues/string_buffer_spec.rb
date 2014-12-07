require "spec_helper"

describe ThreadQueues::StringBuffer do
  it "works with gets" do
    queue = ThreadQueues::BlockingQueue.new
    string_buffer = ThreadQueues::StringBuffer.new(queue)

    Thread.new do
      Thread.current.abort_on_exception = true

      queue.push("hel")
      queue.push("lo\n")
      queue.push("my\r\n")
      queue.push("nam")
      queue.push("e\n")
      queue.push("is kasper\n")
      queue.close
    end

    string_buffer.gets.should eq "hello\n"
    string_buffer.gets.should eq "my\r\n"
    string_buffer.gets.should eq "name\n"
    string_buffer.gets.should eq "is kasper\n"

    expect { string_buffer.gets }.to raise_error(EOFError)
  end

  it "should read the right lengths" do
    queue = ThreadQueues::BufferedQueue.new(5)
    string_buffer = ThreadQueues::StringBuffer.new(queue)

    Thread.new do
      Thread.current.abort_on_exception = true

      queue.push("hel")
      queue.push("lo\n")
      queue.push("my\r\n")
      queue.push("nam")
      queue.push("e\n")
      queue.push("is kasper\n")
      queue.close
    end

    string_buffer.read(6).should eq "hello\n"
    string_buffer.read(4).should eq "my\r\n"
    string_buffer.read(5).should eq "name\n"
    string_buffer.read(10).should eq "is kasper\n"

    expect { string_buffer.gets }.to raise_error(EOFError)
  end
end
