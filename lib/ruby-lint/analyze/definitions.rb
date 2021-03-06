module RubyLint
  module Analyze
    ##
    # {RubyLint::Analyze::Definitions} is a callback class that is used for
    # building a list of all the definitions (variables, methods, etc) of a
    # block of Ruby code.
    #
    # The resulting instance of {RubyLint::Definition} is stored in the `@storage`
    # instance variable under the key `:scope`. This makes it possible for
    # other callback classes to access this data easily.
    #
    class Definitions < RubyLint::Callback
      include Helper::Scoping

      ##
      # A short description of this class.
      #
      # @return [String]
      #
      DESCRIPTION = 'Builds a list of definitions, always enabled.'

      ##
      # Array containing the key names of the variables that should be exported
      # out of a method definition.
      #
      # @return [Array]
      #
      EXPORT_VARIABLES = [:instance_variable, :class_variable, :constant]

      ##
      # Hash containing the scoping data to copy over when extending a class
      # using a module.
      #
      # @return [Hash]
      #
      INCLUDE_SYMBOLS = {
        'include' => {
          :constant        => :constant,
          :instance_method => :instance_method
        },
        'extend' => {
          :constant        => :constant,
          :instance_method => :method
        }
      }

      ##
      # Called when a value is assigned to a variable.
      #
      # @param [RubyLint::Token::AssignmentToken] token
      #
      def on_assignment(token)
        if token.type == :global_variable
          variable_scope = @storage[:scope]
        else
          variable_scope = scope
        end

        # Assignment using a constant path. In this case each path segment
        # should exist (with the exception of the last one) for the assignment
        # to take place.
        if token.name.is_a?(Array)
          name_scope = scope

          token.name[0..-2].each do |segment|
            name_scope = name_scope.lookup(:constant, segment)
          end

          if name_scope
            variable_scope = name_scope
          else
            return
          end

          name = token.name[-1]
          type = :constant
        else
          name = token.name
          type = token.type
        end

        variable_scope.add(
          type,
          name,
          Definition.new(nil, :token => token, :reset => false)
        )
      end

      ##
      # Called when a new method is defined.
      #
      # @param [RubyLint::Token::MethodDefinitionToken] token
      #
      def on_method_definition(token)
        type      = :instance_method
        new_scope = Definition.new(scope, :token => token)
        target    = scope

        token.parameters.each do |param|
          new_scope.add(
            param.type,
            param.name,
            Definition.new(nil, :token => param, :reset => false)
          )
        end

        # The method is a class method.
        if token.receiver
          type = :method

          if token.receiver.name != 'self' \
          and token.receiver.name != @namespace[-1]
            found  = target.lookup(token.receiver.type, token.receiver.name)
            target = found if found
          end
        end

        target.add(type, token.name, new_scope)

        @scopes << new_scope
      end

      ##
      # Called after a method definition has been processed.
      #
      # @see RubyLint::Analyze::Definitions#on_method_definition
      #
      def after_method_definition(token)
        # TODO: exporting these variables should only be done if the method is
        # actually called.
        last_scope = @scopes.pop

        EXPORT_VARIABLES.each do |key|
          scope.symbols[key] = scope.symbols[key].merge(
            last_scope.symbols[key]
          )
        end
      end

      ##
      # Called when a class definition is found.
      #
      # @param [RubyLint::Token::ClassToken] token
      #
      def on_class(token)
        name       = token.name.join('::')
        @namespace << name
        existing   = scope.lookup(:constant, name)

        # If a class has already been defined the scope should not be
        # overwritten.
        if existing
          existing.parent << scope
          @scopes         << existing

          return
        end

        parent    = scope.lookup(:constant, token.parent.join('::'))
        new_scope = Definition.new([parent, scope], :token => token)

        scope.add(:constant, name, new_scope)

        @scopes << new_scope
      end

      ##
      # Called after a class definition was found and processed.
      #
      # @see RubyLint::Analyze::Definitions#on_class
      #
      def after_class(token)
        @scopes.pop
        @namespace.pop
      end

      ##
      # Called when a module is defined.
      #
      # @param [RubyLint::Token::Token] token
      #
      def on_module(token)
        name       = token.name.join('::')
        @namespace << name
        existing   = scope.lookup(:constant, name)

        # If a module has already been defined the scope should not be
        # overwritten.
        if existing
          existing.parent << scope
          @scopes         << existing

          return
        end

        new_scope = Definition.new(scope, :token => token)

        scope.add(:constant, name, new_scope)

        @scopes << new_scope
      end

      ##
      # Called after a module definition has been processed.
      #
      # @see RubyLint::Analyze::Definitions#on_module
      #
      def after_module(token)
        @scopes.pop
        @namespace.pop
      end

      ##
      # Called when a method call is found. This callback is used to extend
      # classes using modules.
      #
      # @param [RubyLint::Token::MethodToken] token
      #
      def on_method(token)
        if INCLUDE_SYMBOLS.key?(token.name)
          token.parameters.each do |param|
            found = nil

            # Extract the definition and scope to include.
            if param.type == :constant_path
              found = resolve_definition(param.name)
            elsif param.type == :constant
              found = scope.lookup(:constant, param.name)
            end

            next unless found

            # Copy over all the constants and methods.
            INCLUDE_SYMBOLS[token.name].each do |source, target|
              found.symbols[source].each do |name, data|
                scope.add(target, name, data)
              end
            end
          end
        end
      end
    end # Definitions
  end # Analyze
end # RubyLint
