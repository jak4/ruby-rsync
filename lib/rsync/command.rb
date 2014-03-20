module Rsync
  # An rsync command to be run
  class Command
    # Runs the rsync job and returns the results
    #
    # @param args {Array}
    # @return {Result}
    def self.run(options)
      if options[:ssh]
        rsync_cmd = rsync_remote(options)
      else
        rsync_cmd = rsync_local(options)
      end
      #puts "rsync: #{rsync_cmd}"
      output = run_command(rsync_cmd)
      Result.new(output, $?.exitstatus, rsync_cmd)
    end

    #ssh remote_host1_user@remote_host1 "rsync -ave ssh  source_sync_dir remote_host2_user@remote_host2:target_sync_dir"
    def self.rsync_remote(options)
      ssh = options.delete(:ssh)

      ssh + ' "' + rsync_local(options) + '"'
    end

    def self.rsync_local(options)
      source = options[:source]
      destination = options[:destination]
      args = options[:args]

      pre_rsync_cmnds = create_pre_rsync_cmnds(args, source, destination)
      post_rsync_cmnds = create_post_rsync_cmnds(args, source, destination)
      rsync = "rsync --itemize-changes #{source} #{destination} #{args.join(" ")}"

      rsync = pre_rsync_cmnds ? pre_rsync_cmnds + " && " + rsync : rsync
      rsync = post_rsync_cmnds ? rsync + " && " + post_rsync_cmnds : rsync

      rsync
    end

  private
    def self.run_command(cmd, &block)
      #puts "cmd: #{cmd}"
      if block_given?
        IO.popen("#{cmd} 2>&1", &block)
      else
        `#{cmd} 2>&1`
      end
    end

    def self.create_pre_rsync_cmnds(args, source, destination)
      pre_args = []
      pre_cmds = ''

      args.each{|a|pre_args << a if is_pre_arg?(a)}
      args.delete_if{|a|pre_args.include?(a)}

      pre_args.each do |pre_arg|
        case pre_arg
          when '---create-parent-folder' then create_parent_folders(destination)
          else
            raise "Unsupported pre_arg: #{pre_arg}"
        end
      end

      pre_cmds.length > 0 ? pre_cmds : nil
    end

    def self.is_pre_arg?(arg)
      ['---create-parent-folder'].include?(arg.strip)
    end

    def self.create_parent_folders(destination)
      splitted_destination = destination.split(':')

      # remote
      if splitted_destination.length > 1
        mkdir_parents = "ssh #{splitted_destination[0]}" + ' "' + mkdir_local_cmd(File.dirname(splitted_destination[1])) +'"'
      #local
      else
        mkdir_parents = mkdir_local_cmd(File.dirname(splitted_destination[0]))
      end

      run_command(mkdir_parents)
    end

    def self.mkdir_local_cmd(path)
      "mkdir -p #{path}"
    end

    def self.create_post_rsync_cmnds(args, source, destination)
      nil
    end
  end
end
