[![Build Status](https://api.shippable.com/projects/54842b6dd46935d5fbbf8e53/badge?branchName=master)](https://app.shippable.com/projects/54842b6dd46935d5fbbf8e53/builds/latest)
[![Code Climate](https://codeclimate.com/github/kaspernj/thread_queues/badges/gpa.svg)](https://codeclimate.com/github/kaspernj/thread_queues)
[![Test Coverage](https://codeclimate.com/github/kaspernj/thread_queues/badges/coverage.svg)](https://codeclimate.com/github/kaspernj/thread_queues)

# ThreadQueues

## Installation

```ruby
gem "thread_queues"
```

## Usage

### BlockingQueue

```ruby
queue = ThreadQueues::BlockingQueue.new

Thread.new do
  3.times do |count|
    queue.push(count)
  end

  queue.close
end

3.times do |count|
  queue.pop #=> 0|1|2
end

queue.pop #=> EOFError
```

### BufferedQueue

Example buffered 5 results before blocking and waiting for results to be read.

```ruby
queue = ThreadQueues::BufferedQueue.new(5)

Thread.new do
  10.times do |count|
    queue.push(count)
  end

  queue.close
end

10.times do |count|
  queue.pop #=> 0|1|2|3|4|5|6|7|8|9
end

queue.pop #=> EOFError
```

## Contributing to thread_queues

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 kaspernj. See LICENSE.txt for
further details.

