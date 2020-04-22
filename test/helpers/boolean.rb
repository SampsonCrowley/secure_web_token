# frozen_string_literal: true

class Boolean
  FALSE_VALUES = [
    false, 0,
    "0", :"0",
    "f", :f,
    "F", :F,
    "false", :false,
    "FALSE", :FALSE,
    "off", :off,
    "OFF", :OFF,
  ].to_set.freeze

  def self.parse(value)
    case value
    in nil | ""
      nil
    else
      !FALSE_VALUES.include?(value)
    end
  end

  def self.strict_parse(value)
    !!parse(value)
  end
end
