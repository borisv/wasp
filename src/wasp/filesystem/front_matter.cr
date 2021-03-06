class Wasp::FileSystem
  struct FrontMatter
    WASP_DATE_FORMAT = "%Y-%m-%dT%H:%M:%S%:z"

    @inner : Totem::Config

    def self.parse(text : String, timezone : String)
      self.new(text, timezone)
    end

    def initialize(text : String, @timezone : String)
      @inner = if text.empty?
                 Totem.new
               else
                 begin
                   Totem.from_yaml(text)
                 rescue TypeCastError
                   raise FrontMatterParseError.new("can not parse front matter from yaml string")
                 end
               end
    end

    def title
      @inner["title"]?.to_s
    end

    def date
      Time.parse(@inner.fetch("date", "1970-01-01T00:00:00+00:00").to_s, WASP_DATE_FORMAT, Time::Location.load(@timezone))
    end

    def slug
      @inner["slug"]?.to_s
    end

    def tags
      find_array_value("tags")
    end

    def categories
      find_array_value("categories")
    end

    def draft?
      @inner.fetch("draft", "false").as_bool
    end

    def to_h
      @inner.set_defaults({
        "date"       => date,
        "tags"       => tags,
        "categories" => categories,
      })

      @inner.to_h
    end

    def dup
    end

    forward_missing_to @inner

    macro method_missing(call)
      @inner.fetch({{ call.name.id.stringify }}, "")

      # TODO: i don't know why this not works
      # case object = @inner.fetch({{ call.name.id.stringify }}, "")
      # when Nil
      #   object.to_s
      # when String
      #   object.as(YAML::Any)
      # when Array
      #   puts {{ call.name.id.stringify }}
      #   puts object.class
      #   object.as(Array(YAML::Any))
      # when Hash
      #   object.as(Hash(YAML::Any, YAML::Any))
      # else
      #   object
      # end
    end

    private def find_array_value(key : String)
      empty_array = Array(String).new
      return empty_array unless object = @inner[key]?

      case object
      when .as_s?
        [object.as_s]
      when .as_a?
        object.as_a.map(&.as_s)
      else
        empty_array
      end
    end
  end
end
