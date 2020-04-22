class FakeRails
  class Credentials
    @dig_value = nil

    class << self
      def dig(...)
        @dig_value
      end

      def dig=(value)
        @dig_value = value
      end
    end
  end

  class Application < FakeRails
  end

  def self.application
    FakeRails::Application
  end

  def self.credentials
    FakeRails::Credentials
  end

  def self.dig=(value)
    credentials.dig = value
  end
end
