# encoding: utf-8
# frozen_string_literal: true

require 'jwt'
require 'jwe'

class SecureWebToken
  CHARACTERS = [
    *('a'..'z'),
    *('A'..'Z'),
    *(0..9).map(&:to_s),
    *'!@#$%^&*()'.split('')
  ].freeze

  DEFAULT_OPTIONS = { enc:  'A256GCM', alg: 'dir', zip: 'DEF' }.freeze

  class << self
    def decode(payload, sig_key = nil, enc_key = nil)
      sig_key ||= signing_key
      enc_key ||= encryption_key
      decrypted = ::JWE.decrypt(payload, enc_key)

      ::JWT.decode(decrypted, sig_key, true, algorithm: 'HS512')[0]
    end
    alias_method :read, :decode
    alias_method :decrypt, :decode
    alias_method :deflate, :decode

    def default_encryption_key
      if defined?(@default_enc_key) && is_present?(@default_enc_key)
        if @default_enc_key.respond_to? :call then
          get_presence(@default_enc_key.call) || gen_encryption_key
        else
          @default_enc_key
        end
      else
        gen_encryption_key
      end
    end

    def default_encryption_key=(value_or_callable)
      @default_enc_key = value_or_callable
    end

    def default_signing_key
      if defined?(@default_sig_key) && is_present?(@default_sig_key)
        if @default_sig_key.respond_to? :call then
          get_presence(@default_sig_key.call) || gen_signing_key
        else
          @default_sig_key
        end
      else
        gen_signing_key
      end
    end

    def default_signing_key=(value_or_callable)
      @default_sig_key = value_or_callable
    end

    def encode(payload, sig_key = nil, enc_key = nil, options = nil)
      sig_key ||= signing_key
      enc_key ||= encryption_key
      options ||= encrypt_options
      encoded = ::JWT.encode(payload, sig_key, 'HS512')

      ::JWE.encrypt(encoded, enc_key, **options)
    end
    alias_method :create, :encode
    alias_method :encrypt, :encode
    alias_method :inflate, :encode

    def encrypt_options
      @encrypt_options ||= DEFAULT_OPTIONS
    end

    def encrypt_options=(options)
      @encrypt_options = (options || DEFAULT_OPTIONS)
    end

    def encryption_key
      @encryption_key ||= default_encryption_key
    end

    def encryption_key=(key)
      @encryption_key = (key || gen_encryption_key)
    end

    def gen_encryption_key
      SecureRandom.random_bytes(32)
    end

    def gen_signing_key(length = 50)
      (0...length).map { CHARACTERS[rand(CHARACTERS.length)] }.join
    end

    def signing_key
      @signing_key ||= default_signing_key
    end

    def signing_key=(key)
      @signing_key = (key || gen_signing_key)
    end

    private
      def is_blank?(object)
        object.respond_to?(:blank?) ?
          object.blank? :
          is_empty?(object)
      end

      def is_empty?(object)
        object.respond_to?(:empty?) ? !!object.empty? : !object
      end

      def is_present?(object)
        object.respond_to?(:present?) ? object.present? : !blank?(object)
      end

      def get_presence(object)
        if object.respond_to?(:presence)
          object.presence
        elsif is_present?(object)
          object
        end
      end
  end
end
