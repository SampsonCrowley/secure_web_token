require 'test_environment'

class SecureWebTokenTest < ActiveSupport::TestCase
  class TestCallError < StandardError
  end

  def setup
    SecureWebToken.signing_key = nil
    SecureWebToken.encryption_key = nil
    SecureWebToken.encrypt_options = nil
    @unique_tries = (ENV['FULL'] == "") ? 100000 : 100
  end

  def with_rails
    inject_rails
    yield
  ensure
    remove_rails
  end

  def inject_rails
    Object.const_set :Rails, FakeRails unless defined? ::Rails
  end

  def remove_rails
    FakeRails.dig = nil
    Object.__send__ :remove_const, :Rails if defined? ::Rails
  end

  def assert_is_getter(mthd, inst_v = nil)
    inst_v ||= :"@#{mthd}"
    refute_nil SecureWebToken.__send__(mthd)
    refute_nil SecureWebToken.instance_variable_get(inst_v)
    assert_equal SecureWebToken.instance_variable_get(inst_v), SecureWebToken.__send__(mthd)
  end

  def assert_is_setter(mthd, inst_v = nil, &block)
    inst_v ||= :"@#{mthd.sub("=", '')}"

    10.times do
      val = block.call

      refute_equal val, SecureWebToken.instance_variable_get(inst_v)

      SecureWebToken.__send__(mthd, val)

      assert_equal val, SecureWebToken.instance_variable_get(inst_v)
    end
  end

  def sample_data
    { data: 'stuff' }
  end


  test '.gen_encryption_key creates a random 32 byte string' do
    key = SecureWebToken.gen_encryption_key
    keys = { "#{key}" => true }

    assert_instance_of String, SecureWebToken.gen_encryption_key
    assert_equal 32, SecureWebToken.gen_encryption_key.size

    @unique_tries.times do
      k = SecureWebToken.gen_encryption_key
      refute_equal key, k
      assert_equal 32, k.size
      refute keys[k]
      keys[k] = true
      key = k
    end
    keys = nil
  end

  test ".default_encryption_key= sets @default_enc_key" do
    generated_key = SecureWebToken.gen_encryption_key
    refute_equal generated_key, SecureWebToken.instance_variable_get(:@default_enc_key)

    SecureWebToken.default_encryption_key = generated_key
    assert_equal generated_key, SecureWebToken.instance_variable_get(:@default_enc_key)
  end

  test ".default_encryption_key generates a new key if @default_enc_key is empty" do
    generated_key = SecureWebToken.gen_encryption_key
    SecureWebToken.default_encryption_key = nil

    SecureWebToken.stub(:gen_encryption_key, generated_key) do
      assert_equal generated_key, SecureWebToken.default_encryption_key
    end

    refute_equal \
      SecureWebToken.default_encryption_key,
      SecureWebToken.default_encryption_key
  end

  test ".default_encryption_key returns @default_enc_key if not empty" do
    generated_key = SecureWebToken.gen_encryption_key
    SecureWebToken.default_encryption_key = generated_key

    SecureWebToken.stub(:gen_encryption_key, ->() { raise ".gen_encryption_key was called" }) do
      assert_equal generated_key, SecureWebToken.default_encryption_key
    end

    assert_equal \
      SecureWebToken.default_encryption_key,
      SecureWebToken.default_encryption_key
  end

  test ".default_encryption_key runs 'call' if @default_enc_key is callable" do
    rand_message = "was called #{rand}"

    breaking_callable = ->() { raise TestCallError.new(rand_message) }
    SecureWebToken.default_encryption_key = breaking_callable

    err = assert_raises(TestCallError) do
      SecureWebToken.default_encryption_key
    end

    assert_equal rand_message, err.message

    called_key = SecureWebToken.gen_signing_key
    present_callable = ->() { called_key }
    SecureWebToken.default_encryption_key = present_callable

    assert_equal called_key, SecureWebToken.default_encryption_key
  ensure
    SecureWebToken.default_encryption_key = nil
  end

  test ".default_encryption_key generates a new key if @default_enc_key.call is empty" do
    rand_message = "was called #{rand}"
    [
      nil,
      "",
      []
    ].each do |blank_val|
      callable = ->() { blank_val }
      SecureWebToken.default_encryption_key = callable
      refute_equal blank_val, SecureWebToken.default_encryption_key
      assert_instance_of String, SecureWebToken.default_encryption_key
      SecureWebToken.stub(:gen_encryption_key, ->() { raise TestCallError.new(rand_message) }) do
        err = assert_raises(TestCallError) do
          SecureWebToken.default_encryption_key
        end
        assert_equal rand_message, err.message
      end
    end
  ensure
    SecureWebToken.default_encryption_key = nil
  end

  test '.gen_signing_key creates a random string' do
    key = SecureWebToken.gen_signing_key
    keys = { key => true }

    assert_instance_of String, SecureWebToken.gen_signing_key

    @unique_tries.times do
      k = SecureWebToken.gen_signing_key
      refute_equal key, k
      refute keys[k]
      keys[k] = true
      key = k
    end
    keys = nil
  end

  test '.gen_signing_key defaults to 50 characters' do
    assert_equal 50, SecureWebToken.gen_signing_key.size
  end

  test '.gen_signing_key accepts a param to set a string length' do
    100.times do
      len = rand(1000)
      assert_equal len, SecureWebToken.gen_signing_key(len).size
    end
  end

  test ".default_signing_key gets a value from credentials if available" do
    Rails.application.credentials.stub(:dig, "tmp_value") do
      assert_equal "tmp_value", SecureWebToken.default_signing_key
    end
  end

  test ".default_signing_key generates a new key if credentials empty" do
    SecureWebToken.stub(:gen_signing_key, "tmp_value") do
      Rails.application.credentials.stub(:dig, nil) do
        assert_equal "tmp_value", SecureWebToken.default_signing_key
      end
    end
  end

  [
    'encryption_key',
    'signing_key'
  ].each do |mthd|
    inst_v = :"@#{mthd}"
    test ".#{mthd} is a getter for @#{mthd}" do
      assert_is_getter mthd, inst_v
    end

    test ".#{mthd} sets a new key if empty" do
      old_key = SecureWebToken.__send__(mthd)
      SecureWebToken.instance_variable_set(inst_v, nil)

      assert_nil SecureWebToken.instance_variable_get(inst_v)

      new_key = SecureWebToken.__send__(mthd)

      refute_equal old_key, new_key
      refute_nil SecureWebToken.instance_variable_get(inst_v)
      assert_equal new_key, SecureWebToken.instance_variable_get(inst_v)
    end

    test ".#{mthd} uses .default_#{mthd} to set empty values" do
      SecureWebToken.instance_variable_set(inst_v, nil)
      assert_nil SecureWebToken.instance_variable_get(inst_v)
      SecureWebToken.stub(:"default_#{mthd}", "tmp_value") do
        assert_equal "tmp_value", SecureWebToken.__send__(mthd)
      end
    end

    test ".#{mthd}= is an setter for @#{mthd}" do
      assert_is_setter("#{mthd}=", inst_v) do
        SecureWebToken.__send__("gen_#{mthd}")
      end
    end

    test ".#{mthd}= generates a new key if nil" do
      old_key = SecureWebToken.__send__(mthd)

      SecureWebToken.__send__("#{mthd}=", nil)

      new_key = SecureWebToken.instance_variable_get(inst_v)

      refute_nil new_key
      refute_equal old_key, new_key
    end
  end

  test ".encrypt_options is a getter for @encrypt_options" do
    assert_is_getter :encrypt_options
  end

  test ".encrypt_options reverts to default if empty" do
    SecureWebToken.instance_variable_set(:@encrypt_options, nil)

    assert_nil SecureWebToken.instance_variable_get(:@encrypt_options)
    refute_nil SecureWebToken.encrypt_options
    assert_equal SecureWebToken::DEFAULT_OPTIONS, SecureWebToken.encrypt_options
    assert_equal SecureWebToken.encrypt_options, SecureWebToken.instance_variable_get(:@encrypt_options)
  end

  test ".encrypt_options= is a setter for @encrypt_options" do
    assert_is_setter("encrypt_options=") do
      SecureWebToken::CHARACTERS.map do
        SecureWebToken::CHARACTERS[rand(SecureWebToken::CHARACTERS.size)]
      end
    end
  end

  test ".encrypt_options= reverts to default if empty" do
    SecureWebToken.encrypt_options = nil
    refute_nil SecureWebToken.instance_variable_get(:@encrypt_options)
    assert_equal SecureWebToken::DEFAULT_OPTIONS, SecureWebToken.encrypt_options
  end

  test ".encode encrypts a JWE with .encryption_key and a JWT payload signed by .signing_key" do
    encoded = SecureWebToken.encode(sample_data)
    assert_equal 5, encoded.split('.').size
    assert_match (/[^\.]+\.[^\.]*(\.[^\.]+){3}/), encoded
    assert_nothing_raised do
      ::JWE.decrypt(
        SecureWebToken.encode(sample_data),
        SecureWebToken.encryption_key
      )
    end
    assert_raises(::JWE::InvalidData) do
      ::JWE.decrypt(
        SecureWebToken.encode(sample_data),
        SecureWebToken.gen_encryption_key
      )
    end
  end

  test ".encode uses direct encryption" do
    assert_equal 0, SecureWebToken.encode(sample_data).split('.')[1].size
  end

  test ".encode is decodable" do
    assert_nothing_raised do
      SecureWebToken.decode(SecureWebToken.encode(sample_data))
    end

    assert_raises(::JWE::InvalidData) do
      SecureWebToken.decode(
        SecureWebToken.encode(
          sample_data,
          nil,
          SecureWebToken.gen_encryption_key
        )
      )
    end

    assert_raises(::JWT::VerificationError) do
      SecureWebToken.decode(
        SecureWebToken.encode(
          sample_data,
          SecureWebToken.gen_signing_key
        )
      )
    end


    decoded = SecureWebToken.decode(SecureWebToken.encode(sample_data))
    assert decoded
    assert_instance_of Hash, decoded
    decoded.keys.each do |k|
      assert_instance_of String, k
    end
    assert_equal sample_data.keys.map(&:to_s), decoded.keys
  end



  test ".decode retrieves a JWT payload signed by .signing_key from a JWE encrypted with .encryption_key" do
    signing_key = SecureWebToken.gen_signing_key
    encryption_key = SecureWebToken.gen_encryption_key
    encoded_sample_data =
      SecureWebToken.encode(
        {data: 'stuff'},
        signing_key,
        encryption_key
      )

    decoded = nil

    assert_nothing_raised do
      decoded = SecureWebToken.decode(encoded_sample_data, signing_key, encryption_key)
    end

    assert_raises(::JWE::InvalidData) do
      SecureWebToken.decode(
        encoded_sample_data,
        signing_key,
        SecureWebToken.gen_encryption_key
      )
    end

    force_decoded =
      ::JWT.decode(
        ::JWE.decrypt(
          encoded_sample_data,
          encryption_key
        ),
        signing_key,
        true,
        algorithm: 'HS512'
      ).first
    assert_equal force_decoded, decoded
  end

  [
    :create,
    :encrypt,
    :inflate
  ].each do |mthd|
    test ".#{mthd} is an alias for encode" do
      assert_equal SecureWebToken.method(:encode), SecureWebToken.method(mthd)
    end
  end

  [
    :read,
    :decrypt,
    :deflate
  ].each do |mthd|
    test ".#{mthd} is an alias for decode" do
      assert_equal SecureWebToken.method(:decode), SecureWebToken.method(mthd)
    end
  end
end
