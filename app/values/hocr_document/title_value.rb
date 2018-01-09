# frozen_string_literal: true
class HOCRDocument
  class TitleValue
    def initialize(title_value)
      @title_attrs = title_value.to_s.split(";").map(&:strip)
    end

    def to_h
      @title_attrs.each_with_object({}) do |combined_string, hsh|
        split = combined_string.split(" ").map(&:strip)
        hsh[split.first] = split[1..-1]
      end
    end
  end
end
