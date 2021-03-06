module RubyLint
  module Token
    ##
    # Generic token class used for data that doesn't require its own specific
    # token.
    #
    # @since 2012-07-29
    #
    class Token
      ##
      # Hash containing various Ripper types and the RubyLint types to use
      # instead.
      #
      # @since  2012-07-29
      # @return [Hash]
      #
      TYPE_MAPPING = {
        :ident           => :identifier,
        :gvar            => :global_variable,
        :ivar            => :instance_variable,
        :cvar            => :class_variable,
        :const           => :constant,
        :int             => :integer,
        :float           => :float,
        :tstring_content => :string,
        :label           => :symbol,
        :kw              => :keyword
      }

      ##
      # The name of the token. For example, when the token is an identifier
      # this value is set to `:ident`.
      #
      # @since  2012-07-29
      # @return [String]
      #
      attr_accessor :name

      ##
      # The value of the token. For example, if the token is a variable this
      # attribute is set to the token for the variable's value.
      #
      # @since  2012-07-29
      # @return [RubyLint::Token::Token]
      #
      attr_accessor :value

      ##
      # The type of token. For example, if the token is a local variable then
      # this value is set to `:local_variable`.
      #
      # @since  2012-07-29
      # @return [Symbol]
      #
      attr_accessor :type

      ##
      # The line number on which the token was defined.
      #
      # @since  2012-07-29
      # @return [Fixnum|Bignum]
      #
      attr_accessor :line

      ##
      # The column number on which the token was defined.
      #
      # @since  2012-07-29
      # @return [Fixnum|Bignum]
      #
      attr_accessor :column

      ##
      # The code of the current line.
      #
      # @return [String]
      #
      attr_accessor :code

      ##
      # The key, index or object member that was accessed from the token.
      #
      # @since  2012-08-24
      # @return [Array]
      #
      attr_accessor :key

      ##
      # The name of the event to call when iterating over an AST. Set to the
      # value of {RubyLint::Token::Token#type} unless specified otherwise.
      #
      # @return [Symbol]
      #
      attr_accessor :event

      ##
      # Set to `true` when a token's values should be expanded. Example:
      #
      #   def foo(*args)
      #     return *args
      #   end
      #
      # @return [TrueClass|FalseClass]
      #
      attr_accessor :expand

      ##
      # Creates a new instance of the token and sets various instance variables
      # based on the specified hash.
      #
      # @since 2012-07-29
      # @param [Hash] options A hash containing various instance variables to
      #  set and their values. For a variable to be set it requires a
      #  corresponding public getter mehtod to be set.
      #
      def initialize(options = {})
        @line, @column = 0, 0
        @expand        = false

        options.each do |key, value|
          if respond_to?(key)
            instance_variable_set("@#{key}", value)
          end
        end

        if TYPE_MAPPING[@type]
          @type = TYPE_MAPPING[@type]
        end

        @event = @type

        # Remove NilClass instances from the `value` array, these serve no
        # useful purpose.
        @value.select! { |t| !t.nil? } if @value.is_a?(Array)
      end

      ##
      # Sets the type of the token and updates the event name accordingly.
      #
      # @param [Symbol] type The new type of the token.
      #
      def type=(type)
        if TYPE_MAPPING[type]
          type = TYPE_MAPPING[type]
        end

        @type  = type
        @event = type
      end

      ##
      # Returns an array containing all the child nodes that can be iterated by
      # {RubyLint::Iterator}.
      #
      # @return [Array]
      #
      def child_nodes
        nodes = []

        if @value
          if @value.is_a?(Array)
            nodes << @value
          else
            nodes << [@value]
          end
        end

        if @key
          nodes << @key
        end

        return nodes
      end
    end # Token
  end # Token
end # RubyLint
