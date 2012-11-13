require 'biscotti/version'
require 'biscotti/process'
require 'values'

module Biscotti

  Passwd = Value.new(:username, :x1, :uid, :gid, :x2, :dir, :shell)
  Group = Value.new(:groupname, :x1, :gid, :members)
  CLEAN_ENVIRONMENT = {'PATH' => '/usr/bin:/usr/local/bin:/usr/sbin',
                       'SHELL' => '/bin/false'}

  def self.drop_priv user
    Process.initgroups(user.username, user.gid)
    Process::Sys.setegid(user.gid)
    Process::Sys.setgid(user.gid)
    Process::Sys.setuid(user.uid)
  end

  def self.do_as_user user, *options, &block
    opts = { chroot: false, env: false }
    opts.merge!(options.last) if options.last.is_a?(Hash)
    pid = fork
    execute_in_child_process(user, opts, &block) unless pid
    Process.wait(pid)
  end

  def self.system_users &block
    return enum_for(:each_passwd_enum) unless block
    each_passwd_enum(&block)
  end

  def self.system_groups &block
    return enum_for(:each_group_enum) unless block
    each_passwd_enum(&block)
  end

  private

  def self.each_passwd_enum &block
    parse_user_file('/etc/passwd', Passwd, [nil, nil, :to_i, :to_i, nil, nil, nil], &block)
  end

  def self.each_group_enum &block
    parse_user_file('/etc/group', Group, [nil, nil, :to_i, ->(e){e.split(',')}], &block)
  end

  def self.parse_user_file filename, klass, operations_array
    IO.readlines(filename).each do |line|
      raw_fields = line.strip.split(':')
      f = transform_line(raw_fields, operations_array)
      yield klass.new(*f)
    end
  end

  def self.transform_line raw_array, operation_array
    (0...operation_array.length).map do |i|
      raw_value = raw_array[i].to_s
      operation = operation_array[i]
      if operation.nil?
        raw_value
      elsif operation.respond_to?(:call)
        operation.call(raw_value)
      else
        raw_value.send(operation.to_sym)
      end
    end
  end

  def self.execute_in_child_process user, options, &block
    set_environment_vars(options[:env]) if options[:env]
    do_chroot(options[:chroot]) if options[:chroot]
    drop_priv(user)
    block.call
    exit! 0
  end

  def self.do_chroot dir
    ENV['HOME'] = '/'
    Dir.chroot(dir)
    Dir.chdir('/')
  end

  def self.set_environment_variables var_hash
    ENV.clear
    var_set = CLEAN_ENVIRONMENT.merge(var_hash)
    var_set.each { |k,v| ENV[k] = v }
  end

end

module Biscotti
  
  class SubProcess
  
    def initialize &block
      @cmd = []
      instance_eval &block
    end
    
    def command
    end


  end


  private

  def fd_path io
    "/proc/#{Process.pid}/fd/#{io.fileno}"
  end

end
