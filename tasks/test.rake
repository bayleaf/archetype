## TESTS
require 'rake/testtask'

debug = false

task :test do
  # make sure the gem is buildable
  puts "Testing the gem builds correctly..."
  Rake::Task['gem:build'].invoke
end
Rake::TestTask.new :test do |t|
  t.libs << 'lib'
  t.libs << 'test'
  test_files = FileList['test/**/*_test.rb']
  t.test_files = test_files
  t.verbose = true
end


namespace :test do
  debug = false
  desc "update test expectations if needed"
  task :update do
    Rake::Task['test:update:fixtures'].invoke
  end
  task :debug do
    debug = true
    Rake::Task['test:update:fixtures'].invoke
  end
  namespace :update do
    # paths
    EXPECTED  = 'expected'
    TMP       = 'tmp'
    FIXTURES  = '../test/fixtures/stylesheets/archetype'
    #desc "update fixture expectations for test cases if needed"
    task :fixtures do
      fixtures_path = File.join([File.dirname(__FILE__)] + FIXTURES.split('/'))
      # remove any existing temporary files
      FileUtils.rm_rf(File.join(fixtures_path, TMP))
      # compile the fixtures
      puts "checking test cases..."
      CHECKMARK = "\u2713 "
      filter = debug ? '--trace' : "| grep 'error.*#{FIXTURES}'"
      errors = %x[compass compile #{fixtures_path} #{filter}]
      # check for compilation errors
      if not errors.empty?
        puts "Please fix the following errors before proceeding:".colorize(:red) if not debug
        puts errors
      else
        # check to see what's changed
        diff = %x[diff -r #{File.join(fixtures_path, EXPECTED, '')} #{File.join(fixtures_path, TMP, '')}]
        # ignore non-CSS files in css/
        diff = diff.gsub(/^Only in .*\/css\/(.*)\:.*[^.css]/, '')
        if diff.empty?
          puts "#{CHECKMARK}Cool! Looks like all the tests are up to date".colorize(:green)
        else
          puts "The following changes were found:"
          puts "===================================="
          # check for new or removed expectations
          diff.scan(/^Only in .*\/(#{EXPECTED}|#{TMP})\/(.*)\: (.*).css/).each do |match|
            config = (match[0] == TMP) ? [:green, '>', 'NEW TEST'] : [:red, '<', 'DELETED']
            puts "[#{File.join(match[1], match[2])}] #{config[2].colorize(config[0])}".colorize(:cyan)
            new_file = File.join(fixtures_path, match[0], match[1], match[2]) + '.css'
            puts File.read(new_file).gsub(/^(.*)/, config[1] + ' \1').colorize(config[0])
          end
          diff = diff.gsub(/^diff\s\-r\s.*\/tmp\/(.*).css/, '[\1]'.colorize(:cyan))
          diff = diff.gsub(/^Only in .*\n?/, '')
          diff = diff.gsub(/^(\<.*)/, '\1'.colorize(:red))
          diff = diff.gsub(/^(\>.*)/, '\1'.colorize(:green))
          diff = diff.gsub(/^(\d+.*)/, '\1'.colorize(:cyan))
          puts diff
          puts "===================================="
          puts "Are all of these changes expected? [y/n]".colorize(:yellow)
          if (($stdin.gets.chomp)[0] == 'y')
            FileUtils.rm_rf(File.join(fixtures_path, EXPECTED, '.'))
            FileUtils.cp_r(File.join(fixtures_path, TMP, '.'), File.join(fixtures_path, EXPECTED))
            puts "#{CHECKMARK}Thanks! The test expectations have been updated".colorize(:green)
          else
            puts "Please manually update the test cases and expectations".colorize(:red)
          end
        end
      end
    end
  end
end
