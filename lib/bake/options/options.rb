require 'bake/toolchain/colorizing_formatter'
require 'common/options/parser'
require 'bake/options/showToolchains'
require 'bake/options/showConfigNames'
require 'bake/options/showLicense'
require 'bake/options/showDoc'
require 'bake/options/usage'
require 'bake/options/create'
require 'common/options/option'

module Bake

  def self.options
    @@options
  end
  def self.options=(options)
    @@options = options
  end
    
  class Options < Parser
    attr_accessor :build_config, :nocache, :analyze, :eclipseOrder, :envToolchain
    attr_reader :main_dir, :project, :filename, :main_project_name, :cc2j_filename # String
    attr_reader :roots, :include_filter, :exclude_filter # String List
    attr_reader :conversion_info, :stopOnFirstError, :clean, :rebuild, :show_includes, :show_includes_and_defines, :linkOnly, :no_autodir, :clobber, :lint, :docu, :debug, :prepro # Boolean
    attr_reader :threads, :socket, :lint_min, :lint_max # Fixnum
    attr_reader :vars # map
    attr_reader :verbose
    attr_reader :consoleOutput_fullnames, :consoleOutput_visualStudio
    

    def initialize(argv)
      super(argv)

      @conversion_info = false
      @envToolchain = false
      @analyze = false
      @eclipseOrder = false
      @showConfigs = false
      @consoleOutput_fullnames = false
      @consoleOutput_visualStudio = false           
      @prepro = false
      @stopOnFirstError = false
      @verbose = 1
      @vars = {}
      @build_config = ""
      @main_dir = nil
      @project = nil      
      @filename = nil
      @cc2j_filename = nil
      @clean = false
      @clobber = false
      @lint = false
      @docu = false
      @debug = false
      @rebuild = false
      @nocache = false
      @show_includes = false
      @show_includes_and_defines = false
      @linkOnly = false
      @no_autodir = false
      @threads = 8
      @lint_min = 0
      @lint_max = -1
      @roots = []
      @socket = 0
      @include_filter = []
      @exclude_filter = []
      @def_roots = []
      @main_project_name = ""
      
      add_default(Proc.new{ |x| set_build_config_default(x) })
      
      add_option(Option.new("-m",true)                     { |x| set_main_dir(x)            })
      add_option(Option.new("-b",true)                     { |x| set_build_config(x)        })
      add_option(Option.new("-p",true)                     { |x| @project = x;})
      add_option(Option.new("-f",true)                     { |x| @filename = x.gsub(/[\\]/,'/')            })
      add_option(Option.new("-c",false)                    {     @clean = true              })
      add_option(Option.new("-a",true)                     { |x| Bake.formatter.setColorScheme(x.to_sym)              })
      add_option(Option.new("-w",true)                     { |x| set_root(x)                })
      add_option(Option.new("-r",false)                    {     @stopOnFirstError = true                  })
      add_option(Option.new("--rebuild",false)             {     @rebuild = true                })
      add_option(Option.new("--prepro",false)              {     @prepro = true                 })
      add_option(Option.new("--link_only",false)           {     @linkOnly = true;              })
      add_option(Option.new("--no_autodir",false)          {     @no_autodir = true         })
      add_option(Option.new("--lint",false)                {     @lint = true               })
      add_option(Option.new("--lint_min",true)             { |x| @lint_min = String === x ? x.to_i : x            })
      add_option(Option.new("--lint_max",true)             { |x| @lint_max = String === x ? x.to_i : x            })
      
      add_option(Option.new("--create",true)               { |x| Bake::Create.proj(x) })     
      add_option(Option.new("--conversion_info",false)        { @conversion_info = true  }) 
        
      add_option(Option.new("--docu",false)                {     @docu = true               })

      add_option(Option.new("-v0",false)                   {     @verbose = 0      })
      add_option(Option.new("-v1",false)                   {     @verbose = 1      })
      add_option(Option.new("-v2",false)                   {     @verbose = 2      })
      add_option(Option.new("-v3",false)                   {     @verbose = 3      })
        
      add_option(Option.new("--debug",false)               {     @debug = true              })
      add_option(Option.new("--set",true)                  { |x| set_set(x)                 })
        
      add_option(Option.new("--clobber",false)             {     @clobber = true; @clean = true                })
      add_option(Option.new("--ignore_cache",false)        {     @nocache = true                })
      add_option(Option.new("--threads",true)              { |x| set_threads(x)             })
      add_option(Option.new("--socket",true)               { |x| @socket = String === x ? x.to_i : x              })
      add_option(Option.new("--toolchain_info",true)       { |x| ToolchainInfo.showToolchain(x)         })
      add_option(Option.new("--toolchain_names",false)     {     ToolchainInfo.showToolchainList           })
      add_option(Option.new("--include_filter",true)       { |x| @include_filter << x       })
      add_option(Option.new("--exclude_filter",true)       { |x| @exclude_filter << x       })
      add_option(Option.new("--show_abs_paths",false)      {     @consoleOutput_fullnames = true         })
      add_option(Option.new("--visualStudio",false)        {     @consoleOutput_visualStudio = true           })
      add_option(Option.new("-h",false)                    {     Bake::Usage.show                 })
      add_option(Option.new("--help",false)                {     Bake::Usage.show                 })
      add_option(Option.new("--show_include_paths",false)  {     @show_includes = true      })
      add_option(Option.new("--show_incs_and_defs",false)  {     @show_includes_and_defines = true  })
      add_option(Option.new("--show_license",false)        {     License.show              })
      add_option(Option.new("--show_doc",false)                 {     Doc.show              })
      add_option(Option.new("--doc",false)                 {     Doc.deprecated              })
      add_option(Option.new("--version",false)             {     ExitHelper.exit(0)         })
      add_option(Option.new("--show_configs",false)        {     @showConfigs = true    })
      add_option(Option.new("--writeCC2J",true)            { |x| @cc2j_filename = x.gsub(/[\\]/,'/')            })

    end

    def parse_options()
      parse_internal(false)
      set_main_dir(Dir.pwd) if @main_dir.nil?
      @roots = @def_roots if @roots.length == 0
      
      if @project
        if @project.split(',').length > 2
          Bake.formatter.printError("Error: only one comma allowed for -p")
          ExitHelper.exit(1)
        end
      end
      
      if @conversion_info
        if @rebuild
          Bake.formatter.printError("Error: --conversion_info and --rebuild not allowed at the same time")
          ExitHelper.exit(1)
        end 
        if @clean
          Bake.formatter.printError("Error: --conversion_info and -c not allowed at the same time")
          ExitHelper.exit(1)
        end
        if @prepro
          Bake.formatter.printError("Error: --conversion_info and --prepro not allowed at the same time")
          ExitHelper.exit(1)
        end
        if @linkOnly
          Bake.formatter.printError("Error: --conversion_info and --linkOnly not allowed at the same time")
          ExitHelper.exit(1)
        end
        if @lint
          Bake.formatter.printError("Error: --conversion_info and --lint not allowed at the same time")
          ExitHelper.exit(1)
        end
        if @docu
          Bake.formatter.printError("Error: --conversion_info and --docu not allowed at the same time")
          ExitHelper.exit(1)
        end
        if not @project
          Bake.formatter.printError("Error: --conversion_info must be used with -p")
          ExitHelper.exit(1)
        end
      end
      
      if @linkOnly
        if @rebuild
          Bake.formatter.printError("Error: --link_only and --rebuild not allowed at the same time")
          ExitHelper.exit(1)
        end
        if @clean
          Bake.formatter.printError("Error: --link_only and -c not allowed at the same time")
          ExitHelper.exit(1)
        end
        if @prepro
          Bake.formatter.printError("Error: --link_only and --prepro not allowed at the same time")
          ExitHelper.exit(1)
        end
      end

      if @prepro
        if @rebuild
          Bake.formatter.printError("Error: --prepro and --rebuild not allowed at the same time")
          ExitHelper.exit(1)
        end
        if @clean
          Bake.formatter.printError("Error: --prepro and -c not allowed at the same time")
          ExitHelper.exit(1)
        end
      end
           
      if @lint and @docu
        Bake.formatter.printError("Error: --lint and --docu not allowed at the same time")
        ExitHelper.exit(1)
      end

      ConfigNames.show if @showConfigs
    end
    
    def check_valid_dir(dir)
     if not File.exists?(dir)
        Bake.formatter.printError("Error: Directory #{dir} does not exist")
        ExitHelper.exit(1)
      end
      if not File.directory?(dir)
        Bake.formatter.printError("Error: #{dir} is not a directory")
        ExitHelper.exit(1)
      end      
    end    

    def set_build_config_default(config)
      index = config.index('-')
      return false if (index != nil and index == 0) 
      set_build_config(config)
      return true
    end

    def set_build_config(config)
      if not @build_config.empty?
        Bake.formatter.printError("Error: Cannot set build config '#{config}', because build config is already set to '#{@build_config}'")
        ExitHelper.exit(1)
      end
      @build_config = config
    end
    
    def set_main_dir(dir)
      check_valid_dir(dir)
      @main_dir = File.expand_path(dir.gsub(/[\\]/,'/'))
      @main_project_name = File::basename(@main_dir)
      @def_roots = calc_def_roots(@main_dir)
    end
    
    def set_root(dir)
      check_valid_dir(dir)
      r = File.expand_path(dir.gsub(/[\\]/,'/'))
      @roots << r if not @roots.include?r
    end
        
    def set_threads(num)
      @threads = String === num ? num.to_i : num
      if @threads <= 0
        Bake.formatter.printError("Error: number of threads must be > 0")
        ExitHelper.exit(1)
      end
    end
    
    def set_set(str)
      ar = str.split("=")
      if not str.include?"=" or ar[0].length == 0
        Bake.formatter.printError("Error: --set must be followed by key=value")
        ExitHelper.exit(1)
      end
      @vars[ar[0]] = ar[1..-1].join("=")
    end
    
  end

end


