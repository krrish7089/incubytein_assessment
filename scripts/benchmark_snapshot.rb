require "benchmark"

elapsed = Benchmark.realtime { Compensation::Snapshot.new.to_h }
directory = Benchmark.realtime { Employees::Directory.new(page: 1, per_page: 25).call }

puts format("employees=%d salaries=%d", Employee.count, SalaryRecord.count)
puts format("snapshot_ms=%.1f", elapsed * 1000)
puts format("directory_ms=%.1f", directory * 1000)
