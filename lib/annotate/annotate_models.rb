module AnnotateModels
  OPTIONS = proc do |opts|
    opts.on('-m', '--show-migration',
            "Include the migration version number in the annotation") do
      ENV['include_version'] = "yes"
    end

    opts.on('-i', '--show-indexes',
            "List the table's database indexes in the annotation") do
      ENV['show_indexes'] = "yes"
    end

    opts.on('-s', '--simple-indexes',
            "Concat the column's related indexes in the annotation") do
      ENV['simple_indexes'] = "yes"
    end

    opts.on('-D', '--model-dir dir',
            "Annotate model files stored in dir rather than app/models, may be used multiple times") do |dir|
      if !ENV['model_dir'].blank?
        ENV['model_dir'] = ENV['model_dir'] + ",#{dir}"
      else
        ENV['model_dir'] = dir
      end
    end

    opts.on('-I', '--ignore-model-subdirs',
            "Ignore subdirectories of the models directory") do |dir|
      ENV['ignore_model_sub_dir'] = "yes"
    end

    opts.on('-S', '--sort',
            "Sort columns in creation order rather than alphabetically") do |dir|
      ENV['sort'] = "yes"
    end

    opts.on('-e', '--exclude [tests,fixtures,factories]', ['tests','fixtures','factories'], "Do not annotate fixtures, test files, and/or factories") do |exclusions|
      exclusions.each { |exclusion| ENV["exclude_#{exclusion}"] = "yes" }
    end

    opts.on('-f', '--format [bare|rdoc|markdown]', ['bare', 'rdoc', 'markdown'], 'Render Schema Infomation as plain/RDoc/Markdown') do |fmt|
      [:bare, :rdoc, :markdown].each { |fmt| ENV["format_#{fmt}"] = 'no' }
      ENV["format_#{fmt}"] = 'yes'
    end

    opts.on('-F', '--force', 'Force new annotations even if there are no changes.') do |force|
      ENV['force'] = 'yes'
    end

    opts.on('-t', '--trace', 'If unable to annotate a file, print the full stack trace, not just the exception message.') do |value|
      ENV['trace'] = 'yes'
    end
  end

  # Annotate Models plugin use this header
  COMPAT_PREFIX    = "== Schema Info"
  COMPAT_PREFIX_MD = "## Schema Info"
  PREFIX           = "== Schema Information"
  PREFIX_MD        = "## Schema Information"
  END_MARK         = "== Schema Information End"
  PATTERN          = /^\n?# (?:#{COMPAT_PREFIX}|#{COMPAT_PREFIX_MD}).*?\n(#.*\n)*\n/

  # File.join for windows reverse bar compat?
  # I dont use windows, can`t test
  UNIT_TEST_DIR         = File.join("test", "unit")
  SPEC_MODEL_DIR        = File.join("spec", "models")
  FIXTURE_TEST_DIR      = File.join("test", "fixtures")
  FIXTURE_SPEC_DIR      = File.join("spec", "fixtures")

  # Object Daddy http://github.com/flogic/object_daddy/tree/master
  EXEMPLARS_TEST_DIR    = File.join("test", "exemplars")
  EXEMPLARS_SPEC_DIR    = File.join("spec", "exemplars")

  # Machinist http://github.com/notahat/machinist
  BLUEPRINTS_TEST_DIR   = File.join("test", "blueprints")
  BLUEPRINTS_SPEC_DIR   = File.join("spec", "blueprints")

  # Factory Girl http://github.com/thoughtbot/factory_girl
  FACTORY_GIRL_TEST_DIR = File.join("test", "factories")
  FACTORY_GIRL_SPEC_DIR = File.join("spec", "factories")

  # Fabrication https://github.com/paulelliott/fabrication.git
  FABRICATORS_TEST_DIR  = File.join("test", "fabricators")
  FABRICATORS_SPEC_DIR  = File.join("spec", "fabricators")

  TEST_PATTERNS = [
    [UNIT_TEST_DIR,  "%MODEL_NAME%_test.rb"],
    [SPEC_MODEL_DIR, "%MODEL_NAME%_spec.rb"],
  ]

  FIXTURE_PATTERNS = [
    File.join(FIXTURE_TEST_DIR, "%TABLE_NAME%.yml"),
    File.join(FIXTURE_SPEC_DIR, "%TABLE_NAME%.yml"),
  ]

  FACTORY_PATTERNS = [
    File.join(EXEMPLARS_TEST_DIR,     "%MODEL_NAME%_exemplar.rb"),
    File.join(EXEMPLARS_SPEC_DIR,     "%MODEL_NAME%_exemplar.rb"),
    File.join(BLUEPRINTS_TEST_DIR,    "%MODEL_NAME%_blueprint.rb"),
    File.join(BLUEPRINTS_SPEC_DIR,    "%MODEL_NAME%_blueprint.rb"),
    File.join(FACTORY_GIRL_TEST_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
    File.join(FACTORY_GIRL_SPEC_DIR,  "%MODEL_NAME%_factory.rb"),    # (old style)
    File.join(FACTORY_GIRL_TEST_DIR,  "%TABLE_NAME%.rb"),            # (new style)
    File.join(FACTORY_GIRL_SPEC_DIR,  "%TABLE_NAME%.rb"),            # (new style)
    File.join(FABRICATORS_TEST_DIR,   "%MODEL_NAME%_fabricator.rb"),
    File.join(FABRICATORS_SPEC_DIR,   "%MODEL_NAME%_fabricator.rb"),
  ]

  # Don't show limit (#) on these column types
  # Example: show "integer" instead of "integer(4)"
  NO_LIMIT_COL_TYPES = ["integer", "boolean"]

  class << self
    def model_dir
      @model_dir || ["app/models"]
    end

    def model_dir=(dir)
      @model_dir = dir
    end

    # Simple quoting for the default column value
    def quote(value)
      case value
      when NilClass                 then "NULL"
      when TrueClass                then "TRUE"
      when FalseClass               then "FALSE"
      when Float, Fixnum, Bignum    then value.to_s
        # BigDecimals need to be output in a non-normalized form and quoted.
      when BigDecimal               then value.to_s('F')
      else
        value.inspect
      end
    end

    # Use the column information in an ActiveRecord class
    # to create a comment block containing a line for
    # each column. The line contains the column name,
    # the type (and length), and any optional attributes
    def get_schema_info(klass, header, options = {})
      info = "# #{header}\n"
      info<< "#\n"
      if(options[:format_markdown])
        info<< "# Table name: `#{klass.table_name}`\n"
        info<< "#\n"
        info<< "# ### Columns\n"
      else
        info<< "# Table name: #{klass.table_name}\n"
      end
      info<< "#\n"

      max_size = klass.column_names.map{|name| name.size}.max || 0
      max_size += options[:format_rdoc] ? 5 : 1
      md_names_overhead = 6
      md_type_allowance = 18
      bare_type_allowance = 16

      if(options[:format_markdown])
        info<< sprintf( "# %-#{max_size + md_names_overhead}.#{max_size + md_names_overhead}s | %-#{md_type_allowance}.#{md_type_allowance}s | %s\n", 'Name', 'Type', 'Attributes' )
        info<< "# #{ '-' * ( max_size + md_names_overhead ) } | #{'-' * md_type_allowance} | #{ '-' * 27 }\n"
      end

      cols = klass.columns
      cols = cols.sort_by(&:name) if(options[:sort])
      cols.each do |col|
        attrs = []
        attrs << "default(#{quote(col.default)})" unless col.default.nil?
        attrs << "not null" unless col.null
        attrs << "primary key" if klass.primary_key && col.name.to_sym == klass.primary_key.to_sym

        col_type = (col.type || col.sql_type).to_s
        if col_type == "decimal"
          col_type << "(#{col.precision}, #{col.scale})"
        else
          if (col.limit)
            col_type << "(#{col.limit})" unless NO_LIMIT_COL_TYPES.include?(col_type)
          end
        end

        # Check out if we got a geometric column
        # and print the type and SRID
        if col.respond_to?(:geometry_type)
          attrs << "#{col.geometry_type}, #{col.srid}"
        end

        # Check if the column has indices and print "indexed" if true
        # If the index includes another column, print it too.
        if options[:simple_indexes] && klass.table_exists?# Check out if this column is indexed
          indices = klass.connection.indexes(klass.table_name)
          if indices = indices.select { |ind| ind.columns.include? col.name }
            indices.each do |ind|
              ind = ind.columns.reject! { |i| i == col.name }
              attrs << (ind.length == 0 ? "indexed" : "indexed => [#{ind.join(", ")}]")
            end
          end
        end

        if options[:format_rdoc]
          info << sprintf("# %-#{max_size}.#{max_size}s<tt>%s</tt>", "*#{col.name}*::", attrs.unshift(col_type).join(", ")).rstrip + "\n"
        elsif options[:format_markdown]
          name_remainder = max_size - col.name.length
          type_remainder = (md_type_allowance - 2) - col_type.length
          info << (sprintf("# **`%s`**%#{name_remainder}s | `%s`%#{type_remainder}s | `%s`", col.name, " ", col_type, " ", attrs.join(", ").rstrip)).gsub('``', '  ').rstrip + "\n"
        else
          info << sprintf("#  %-#{max_size}.#{max_size}s:%-#{bare_type_allowance}.#{bare_type_allowance}s %s", col.name, col_type, attrs.join(", ")).rstrip + "\n"
        end
      end

      if options[:show_indexes] && klass.table_exists?
        info << get_index_info(klass, options)
      end

      if options[:format_rdoc]
        info << "#--\n"
        info << "# #{END_MARK}\n"
        info << "#++\n\n"
      else
        info << "#\n\n"
      end
    end

    def get_index_info(klass, options={})
      if(options[:format_markdown])
        index_info = "#\n# ### Indexes\n#\n"
      else
        index_info = "#\n# Indexes\n#\n"
      end

      indexes = klass.connection.indexes(klass.table_name)
      return "" if indexes.empty?

      max_size = indexes.collect{|index| index.name.size}.max + 1
      indexes.sort_by{|index| index.name}.each do |index|
        if(options[:format_markdown])
          index_info << sprintf("# * `%s`%s:\n#     * **`%s`**\n", index.name, index.unique ? " (_unique_)" : "", index.columns.join("`**\n#     * **`"))
        else
          index_info << sprintf("#  %-#{max_size}.#{max_size}s %s %s", index.name, "(#{index.columns.join(",")})", index.unique ? "UNIQUE" : "").rstrip + "\n"
        end
      end
      return index_info
    end

    # Add a schema block to a file. If the file already contains
    # a schema info block (a comment starting with "== Schema Information"), check if it
    # matches the block that is already there. If so, leave it be. If not, remove the old
    # info block and write a new one.
    # Returns true or false depending on whether the file was modified.
    #
    # === Options (opts)
    #  :force<Symbol>:: whether to update the file even if it doesn't seem to need it.
    #  :position_in_*<Symbol>:: where to place the annotated section in fixture or model file,
    #                           :before or :after. Default is :before.
    #
    def annotate_one_file(file_name, info_block, position, options={})
      if File.exist?(file_name)
        old_content = File.read(file_name)
        return false if(old_content =~ /# -\*- SkipSchemaAnnotations.*\n/)

        # Ignore the Schema version line because it changes with each migration
        header_pattern = /(^# Table name:.*?\n(#.*[\r]?\n)*[\r]?\n)/
        old_header = old_content.match(header_pattern).to_s
        new_header = info_block.match(header_pattern).to_s

        column_pattern = /^#[\t ]+\w+[\t ]+.+$/
        old_columns = old_header && old_header.scan(column_pattern).sort
        new_columns = new_header && new_header.scan(column_pattern).sort

        encoding = Regexp.new(/(^#\s*encoding:.*\n)|(^# coding:.*\n)|(^# -\*- coding:.*\n)/)
        encoding_header = old_content.match(encoding).to_s

        if old_columns == new_columns && !options[:force]
          return false
        else

# todo: figure out if we need to extract any logic from this merge chunk
# <<<<<<< HEAD
#           # Replace the old schema info with the new schema info
#           new_content = old_content.sub(/^# #{COMPAT_PREFIX}.*?\n(#.*\n)*\n*/, info_block)
#           # But, if there *was* no old schema info, we simply need to insert it
#           if new_content == old_content
#             old_content.sub!(encoding, '')
#             new_content = options[:position] == 'after' ?
#               (encoding_header + (old_content =~ /\n$/ ? old_content : old_content + "\n") + info_block) :
#               (encoding_header + info_block + old_content)
#           end
# =======

          # Strip the old schema info, and insert new schema info.
          old_content.sub!(encoding, '')
          old_content.sub!(PATTERN, '')

          new_content = options[position].to_s == 'after' ?
            (encoding_header + (old_content.rstrip + "\n\n" + info_block)) :
            (encoding_header + info_block + old_content)

          File.open(file_name, "wb") { |f| f.puts new_content }
          return true
        end
      else
        return false
      end
    end

    def remove_annotation_of_file(file_name)
      if File.exist?(file_name)
        content = File.read(file_name)

        content.sub!(PATTERN, '')

        File.open(file_name, "wb") { |f| f.puts content }

        return true
      else
        return false
      end
    end

    # Given the name of an ActiveRecord class, create a schema
    # info block (basically a comment containing information
    # on the columns and their types) and put it at the front
    # of the model and fixture source files.
    # Returns true or false depending on whether the source
    # files were modified.
    #
    # === Options (opts)
    #  :position_in_class<Symbol>:: where to place the annotated section in model file
    #  :position_in_test<Symbol>:: where to place the annotated section in test/spec file(s)
    #  :position_in_fixture<Symbol>:: where to place the annotated section in fixture file
    #  :position_in_factory<Symbol>:: where to place the annotated section in factory file
    #  :exclude_tests<Symbol>:: whether to skip modification of test/spec files
    #  :exclude_fixtures<Symbol>:: whether to skip modification of fixture files
    #  :exclude_factories<Symbol>:: whether to skip modification of factory files
    #
    def annotate(klass, file, header, annotated, options={})
      begin
        info = get_schema_info(klass, header, options)
        did_annotate = false
        model_name = klass.name.underscore
        table_name = klass.table_name
        self.model_dir = options[:model_dir] if options[:model_dir].length > 0

        # A model could be defined in multiple files...
        did_annotate = self.model_dir.
          map { |dir| File.join(dir, file) }.
          select { |fname| fname && File.exist?(fname) }.
          map { |file| annotate_one_file(file, info, :position_in_class, options) }.
          detect { |result| result } || did_annotate

        unless options[:exclude_tests]
          did_annotate = TEST_PATTERNS.
            map { |pat| [pat[0], resolve_filename(pat[1], model_name, table_name)] }.
            map { |pat| find_test_file(*pat) }.
            map { |file| annotate_one_file(file, info, :position_in_test, options) }.
            detect { |result| result } || did_annotate
        end

        unless options[:exclude_fixtures]
          did_annotate = FIXTURE_PATTERNS.
            map { |file| resolve_filename(file, model_name, table_name) }.
            map { |file| annotate_one_file(file, info, :position_in_fixture, options) }.
            detect { |result| result } || did_annotate
        end

        unless options[:exclude_factories]
          did_annotate = FACTORY_PATTERNS.
            map { |file| resolve_filename(file, model_name, table_name) }.
            map { |file| annotate_one_file(file, info, :position_in_factory, options) }.
            detect { |result| result } || did_annotate
        end

        annotated << klass if(did_annotate)
      rescue Exception => e
        puts "Unable to annotate #{file}: #{e.message}"
        puts "\t" + e.backtrace.join("\n\t") if options[:trace]
      end
    end

    def get_subclasses_recursively(klass)
      subs = klass.send(:subclasses)
      subs += subs.map { |c| get_subclasses_recursively(c) }.flatten
      return subs
    end

    # We're passed a name of things that might be
    # ActiveRecord models. If we can find the class, and
    # if its a subclass of ActiveRecord::Base,
    # then pass it to the associated block
    def do_annotations(options={})
      header = options[:format_markdown] ? PREFIX_MD.dup : PREFIX.dup

      if options[:include_version]
        version = ActiveRecord::Migrator.current_version rescue 0
        if version > 0
          header << "\n# Schema version: #{version}"
        end
      end

      self.model_dir = options[:model_dir] if options[:model_dir].length > 0

      annotated = []

      models = []
      if(!options[:is_rake])
        models = ARGV.map { |arg| ActiveSupport::Inflector.safe_constantize(arg) }.reject { |klass| klass.nil? }
      end
      if(models.length == 0)
        models = get_subclasses_recursively(ActiveRecord::Base)
      end

      models.each do |klass|
        file = "#{ActiveSupport::Inflector.underscore(klass)}.rb"
        found_file = false
        self.model_dir.each do |dir|
          if(File.exist?(File.join(dir, file)))
            annotate(klass, file, header, annotated, options)
            found_file = true
          end
        end

        if(!found_file && options[:trace])
          puts "Skipping #{klass}, as it seems to be provided by a gem/engine, or otherwise isn't in a path where we expect to find it."
        end
      end

      if annotated.empty?
        puts "Nothing annotated."
      else
        puts "Annotated (#{annotated.length}): #{annotated.join(', ')}"
      end
    end

    def remove_annotations(options={})
      self.model_dir = options[:model_dir] if options[:model_dir].length > 0

      deannotated = []

      models = []
      if(!options[:is_rake])
        models = ARGV.map { |arg| ActiveSupport::Inflector.safe_constantize(arg) }.reject { |klass| klass.nil? }
      end
      if(models.length == 0)
        models = get_subclasses_recursively(ActiveRecord::Base)
      end

      models.each do |klass|
        begin
          file = "#{ActiveSupport::Inflector.underscore(klass)}.rb"
          deannotated_klass = false
          model_name = klass.name.underscore
          table_name = klass.table_name
          self.model_dir.each do |dir|
            model_file_name = File.join(dir, file)
            if(File.exist?(model_file_name))
              remove_annotation_of_file(model_file_name)
              deannotated_klass = true
            end
          end

          TEST_PATTERNS.
            map { |pat| [pat[0], resolve_filename(pat[1], model_name, table_name)]}.
            map { |pat| find_test_file(*pat) }.each do |file|
              if(File.exist?(file))
                remove_annotation_of_file(file)
                deannotated_klass = true
              end
            end

          (FIXTURE_PATTERNS + FACTORY_PATTERNS).
            map { |file| resolve_filename(file, model_name, table_name) }.
            each do |file|
              if File.exist?(file)
                remove_annotation_of_file(file)
                deannotated_klass = true
              end
            end

          deannotated << klass if(deannotated_klass)
        rescue Exception => e
          puts "Unable to deannotate #{file}: #{e.message}"
          puts "\t" + e.backtrace.join("\n\t") if options[:trace]
        end
      end
      puts "Removed annotations from: #{deannotated.join(', ')}"
    end

    def find_test_file(dir, file_name)
      Dir.glob(File.join(dir, "**", file_name)).first || File.join(dir, file_name)
    end

    def resolve_filename(filename_template, model_name, table_name)
      return filename_template.
        gsub('%MODEL_NAME%', model_name).
        gsub('%TABLE_NAME%', table_name || model_name.pluralize)
    end
  end
end
