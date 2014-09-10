module Aquarium
  # Abstract class to store information about tag
  class Tag
    @@registered_tags = { }

    # Return registered tags
    def self.registered_tags
      @@registered_tags
    end

    # Find subclass for particular tag
    def self.find_tag(tag,parameters,file_name,change_collection)
      klass = @@registered_tags[tag]
      if klass
        return klass.new(parameters,file_name,change_collection)
      else
        raise "Unknow tag: #{tag}"
      end
    end

    # Subclasses will call this to register tag that they can handle
    def self.register_tag(tag)

      @@registered_tags[tag] = self
      self.class_eval <<-END
        def tag_type 
        "#{tag}".to_sym
        end
      END
    end

    # Match file line to a particular tag
    def self.match(line,file_name,change_collection)
      if line =~ /--\#(\w+)\s+(.*)/
        tag = $1.downcase.to_sym
        parameters = $2        
        self.find_tag(tag,parameters,file_name,change_collection)
      else
        return nil
      end
    end

  end

end

# Load all files in tags directory
Dir[File.dirname(__FILE__) + '/tags/*.rb'].each {|file| require file }