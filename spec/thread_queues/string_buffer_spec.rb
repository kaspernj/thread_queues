require "spec_helper"

describe ThreadQueues::StringBuffer do
  let(:queue) { ThreadQueues::BlockingQueue.new }
  let(:lines) { lines = ["hello\n", "my\r\n", "name\n", "is kasper\n"] }
  let(:whole_string) { lines.join("") }
  let(:string_buffer) {
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

    string_buffer
  }

  describe "#gets" do
    it "returns lines as default" do
      string_buffer.gets.should eq "hello\n"
      string_buffer.gets.should eq "my\r\n"
      string_buffer.gets.should eq "name\n"
      string_buffer.gets.should eq "is kasper\n"

      expect { string_buffer.gets }.to raise_error(EOFError)
    end

    it "accepts custom seperators" do
      string_buffer.gets("\r").should eq "hello\nmy\r"
      string_buffer.gets("\r").should eq "\nname\nis kasper\n"
      expect { string_buffer.gets }.to raise_error(EOFError)
    end

    it "accepts a limit" do
      string_buffer.gets(3).should eq "hel"
      string_buffer.gets(10).should eq "lo\n"
      string_buffer.gets(10).should eq "my\r\n"
    end

    it "accepts both a limit and a custom seperator" do
      string_buffer.gets("\r", 3).should eq "hel"
      string_buffer.gets("\r", 999).should eq "lo\nmy\r"
      string_buffer.gets("\r", 999).should eq "\nname\nis kasper\n"
    end
  end

  describe "#read" do
    it "with a given length" do
      string_buffer.read(6).should eq "hello\n"
      string_buffer.read(4).should eq "my\r\n"
      string_buffer.read(5).should eq "name\n"
      string_buffer.read(10).should eq "is kasper\n"

      expect { string_buffer.gets }.to raise_error(EOFError)
    end

    it "reads the whole thing when length is nil" do
      string_buffer.read.should eq whole_string
    end

    it "supports outbuf argument" do
      outbuf = "kasper"
      string_buffer.read(6, outbuf).should eq "hello\n"
      outbuf.should eq "hello\n"
    end

    it "should return the correct values when it has reaches eof" do
      string_buffer.read.should eq whole_string
      string_buffer.read.should eq ""
      string_buffer.read(5).should eq nil
    end
  end

  it "#each_line" do
    count = 0
    string_buffer.each_line do |line|
      line.should eq lines[count]
      count += 1
    end
  end

  it "#each_char" do
    count = 0
    string_buffer.each_char do |char|
      char.should eq whole_string.slice(count, 1)
      count += 1
    end

    string_buffer.pos.should eq 25
  end

  it "#each_byte" do
    count = 0
    string_buffer.each_byte do |byte|
      byte.should eq whole_string.bytes[count]
      count += 1
    end

    string_buffer.pos.should eq 25
  end

  it "#lineno" do
    string_buffer.lineno.should eq 0

    string_buffer.gets
    string_buffer.lineno.should eq 1

    string_buffer.gets
    string_buffer.lineno.should eq 2

    string_buffer.gets
    string_buffer.lineno.should eq 3

    string_buffer.gets
    string_buffer.lineno.should eq 4

    expect { string_buffer.gets }.to raise_error(EOFError)
    string_buffer.lineno.should eq 4
  end

  it "#pos" do
    string_buffer.pos.should eq 0
    string_buffer.gets
    string_buffer.pos.should eq 6
    string_buffer.read(4)
    string_buffer.pos.should eq 10
    string_buffer.read(999)
    string_buffer.pos.should eq 25
  end

  describe "#empty?" do
    it "returns false when empty" do
      string_buffer.empty?.should eq false
    end

    it "returns true when not empty" do
      queue = ThreadQueues::BlockingQueue.new
      sbuffer = ThreadQueues::StringBuffer.new(queue)
      queue.close
      sbuffer.empty?.should eq true
    end
  end
end
