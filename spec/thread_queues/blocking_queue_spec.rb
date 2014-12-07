require "spec_helper"

describe ThreadQueues::BlockingQueue do
  it "can read and write when writing is slow" do
    queue = ThreadQueues::BlockingQueue.new

    Thread.new do
      3.times do |count|
        sleep 0.01
        queue.push(count)
      end

      queue.close
    end

    3.times do |count|
      read = queue.pop
      read.should eq count
    end

    expect { queue.pop }.to raise_error(EOFError)
  end

  it "can read and write when reading is slow" do
    queue = ThreadQueues::BlockingQueue.new

    Thread.new do
      3.times do |count|
        queue.push(count)
      end

      queue.close
    end

    3.times do |count|
      sleep 0.01
      read = queue.pop
      read.should eq count
    end

    expect { queue.pop }.to raise_error(EOFError)
  end
end
