# == Annotate Routes
#
# Based on:
#
#
#
# Prepends the output of "rake routes" to the top of your routes.rb file.
# Yes, it's simple but I'm thick and often need a reminder of what my routes
# mean.
#
# Running this task will replace any exising route comment generated by the
# task. Best to back up your routes file before running:
#
# Author:
#  Gavin Montague
#  gavin@leftbrained.co.uk
#
# Released under the same license as Ruby. No Support. No Warranty.
#
module AnnotateRoutes
  PREFIX = "# == Route Map"

  def self.do_annotate(options={})
    return unless(routes_exists?)

    position_after = options[:position_in_routes] == 'after'

    routes_map = `rake routes`.split(/\n/, -1)

    # In old versions of Rake, the first line of output was the cwd.  Not so
    # much in newer ones.  We ditch that line if it exists, and if not, we
    # keep the line around.
    routes_map.shift if(routes_map.first =~ /^\(in \//)

    header = [
      "#{PREFIX} (Updated #{Time.now.strftime("%Y-%m-%d %H:%M")})",
      "#"
    ] + routes_map.map { |line| "# #{line}".rstrip }

    (content, where_header_found) = strip_annotations(File.read(routes_file))
    changed = where_header_found != 0 # This will either be :before, :after, or
                                      # a number.  If the number is > 0, the
                                      # annotation was found somewhere in the
                                      # middle of the file.  If the number is
                                      # zero, no annotation was found.

    if(position_after)
      # Ensure we have adequate trailing newlines at the end of the file to
      # ensure a blank line separating the content from the annotation.
      content << '' if(content.last != '')

      # We're moving something from the top of the file to the bottom, so ditch
      # the spacer we put in the first time around.
      if(changed && where_header_found == :before)
        content.shift if(content.first == '')
      end
    else
      header = header << '' if(content.first != '' || changed)
    end

    content = position_after ? (content + header) : header + content

    write_contents(content)

    puts "Route file annotated."
  end

  def self.remove_annotations(options={})
    return unless(routes_exists?)

    (content, where_header_found) = strip_annotations(File.read(routes_file))

    content = strip_on_removal(content, where_header_found)

    write_contents(content)

    puts "Removed annotations from routes file."
  end

protected

  def self.routes_file
    @routes_rb ||= File.join("config", "routes.rb")
  end

  def self.routes_exists?
    routes_exists = File.exists?(routes_file)
    puts "Can`t find routes.rb" if(!routes_exists)
    return routes_exists
  end

  def self.write_contents(content)
    content << '' unless(content.last == '') # Make sure we end on a trailing
                                             # newline.

    File.open(routes_file, "wb") { |f| f.puts(content.join("\n")) }
  end

  def self.strip_annotations(content)
    real_content = []
    mode = :content
    line_number = 0
    header_found_at = 0
    content.split(/\n/, -1).each do |line|
      line_number += 1
      begin
        if(mode == :header)
          if(line !~ /\s*#/)
            mode = :content
            raise unless (line == '')
          end
        elsif(mode == :content)
          if(line =~ /^\s*#\s*== Route.*$/)
            header_found_at = line_number
            mode = :header
          else
            real_content << line
          end
        end
      rescue
        retry
      end
    end
    content_lines = real_content.count

    # By default assume the annotation was found in the middle of the file...
    where_header_found = header_found_at
    # ... unless we have evidence it was at the beginning ...
    where_header_found = :before if(header_found_at == 1)
    # ... or that it was at the end.
    where_header_found = :after if(header_found_at >= content_lines)

    return real_content, where_header_found
  end

  def self.strip_on_removal(content, where_header_found)
    if(where_header_found == :before)
      content.shift while(content.first == '')
    elsif(where_header_found == :after)
      content.pop while(content.last == '')
    end
    # TODO: If the user buried it in the middle, we should probably see about
    # TODO: preserving a single line of space between the content above and
    # TODO: below...
    return content
  end
end
