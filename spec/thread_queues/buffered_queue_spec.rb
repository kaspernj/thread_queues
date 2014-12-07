require "spec_helper"

describe ThreadQueues::BufferedQueue do
  it "should work when slow reading" do
    queue = ThreadQueues::BufferedQueue.new(5)

    $thread_finished = false
    $thread_work = Thread.new do
      10.times do |count|
        queue.push count
      end
      $thread_finished = true
    end

    sleep 0.01

    4.times do |count|
      queue.pop.should eq count
      $thread_finished.should eq false
      sleep 0.01
    end

    queue.pop.should eq 4
    sleep 0.01
    $thread_finished.should eq true
  end

  it "should work when slow writing" do
    queue = ThreadQueues::BufferedQueue.new(5)

    $thread_finished = false
    $thread_work = Thread.new do
      10.times do |count|
        queue.push count
        sleep 0.01
      end
      $thread_finished = true
    end

    sleep 0.01

    4.times do |count|
      queue.pop.should eq count
      $thread_finished.should eq false
    end

    queue.pop.should eq 4
    sleep 0.07
    queue.length.should eq 5
    $thread_finished.should eq true
  end
end
