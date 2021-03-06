require File.expand_path('../../../helper', __FILE__)

describe 'RubyLint::Parser' do
  it 'Parse a method definition' do
    token = RubyLint::Parser.new('def number; return 10; end').parse[0]

    token.class.should      == RubyLint::Token::MethodDefinitionToken
    token.line.should       == 1
    token.column.should     == 4
    token.name.should       == 'number'
    token.visibility.should == :public
    token.type.should       == :method_definition

    token.parameters.class.should == RubyLint::Token::ParametersToken

    token.value.class.should  == Array
    token.value.length.should == 1

    token.value[0].class.should == RubyLint::Token::StatementToken
    token.value[0].type.should  == :return

    token.value[0].value.class.should  == Array
    token.value[0].value.length.should == 1

    value = token.value[0].value[0]

    value.class.should == RubyLint::Token::Token
    value.type.should  == :integer
    value.value.should == '10'
  end

  it 'Parse a method definition with parameters' do
    code = <<-CODE
def number(a, b = 10, *args, more, &block)
  return num
end
    CODE

    token = RubyLint::Parser.new(code).parse[0]

    token.class.should  == RubyLint::Token::MethodDefinitionToken
    token.name.should   == 'number'
    token.line.should   == 1
    token.column.should == 4

    params = token.parameters

    params.class.should       == RubyLint::Token::ParametersToken
    params.value.class.should == Array

    # Required parameters
    params.value.length.should    == 1
    params.value[0].class.should  == RubyLint::Token::VariableToken
    params.value[0].name.should   == 'a'

    # Optional parameters
    params.optional.class.should  == Array
    params.optional.length.should == 1

    optional = params.optional[0]

    optional.class.should  == RubyLint::Token::VariableToken
    optional.name.should   == 'b'

    optional.value.class.should == RubyLint::Token::Token
    optional.value.type.should  == :integer
    optional.value.value.should == '10'

    # Rest parameters
    params.rest.name.should  == 'args'
    params.rest.class.should == RubyLint::Token::VariableToken

    # More parameters
    params.more.class.should   == Array
    params.more.length.should  == 1
    params.more[0].name.should == 'more'

    # Block parameters
    params.block.class.should == RubyLint::Token::VariableToken
    params.block.name.should  == 'block'
  end

  it 'Parse a class method definition' do
    code = <<-CODE
def self.example(number = 10)
  return number
end
    CODE

    token = RubyLint::Parser.new(code).parse[0]

    token.class.should == RubyLint::Token::MethodDefinitionToken
    token.name.should  == 'example'

    token.receiver.class.should == RubyLint::Token::VariableToken
    token.receiver.name.should  == 'self'
    token.receiver.type.should  == :keyword

    token.operator.class.should == RubyLint::Token::Token
    token.operator.value.should == '.'
    token.operator.type.should  == :period

    token.parameters.class.should           == RubyLint::Token::ParametersToken
    token.parameters.optional.class.should  == Array
    token.parameters.optional.length.should == 1
  end

  it 'Parse a private method definition' do
    code = <<-CODE
private

def example
  return 10
end
    CODE

    token = RubyLint::Parser.new(code).parse[1]

    token.class.should      == RubyLint::Token::MethodDefinitionToken
    token.name.should       == 'example'
    token.visibility.should == :private

    token.value.class.should  == Array
    token.value.length.should == 1
  end

  it 'Parse a method call' do
    token = RubyLint::Parser.new('puts').parse[0]

    token.class.should == RubyLint::Token::MethodToken
    token.name.should  == 'puts'
  end

  it 'Parse a method call with parenthesis' do
    token = RubyLint::Parser.new('puts()').parse[0]

    token.class.should == RubyLint::Token::MethodToken
    token.name.should  == 'puts'
  end

  it 'Parse a method call with parenthesis and parameters' do
    token = RubyLint::Parser.new('puts(10)').parse[0]

    token.class.should == RubyLint::Token::MethodToken
    token.name.should  == 'puts'

    token.parameters.class.should  == Array
    token.parameters.length.should == 1

    param = token.parameters[0]

    param.class.should == RubyLint::Token::Token
    param.type.should  == :integer
    param.value.should == '10'
  end

  it 'Parse a method call with parameters but without parenthesis' do
    token = RubyLint::Parser.new('puts 10').parse[0]

    token.class.should == RubyLint::Token::MethodToken
    token.name.should  == 'puts'

    token.parameters.class.should  == Array
    token.parameters.length.should == 1

    param = token.parameters[0]

    param.class.should == RubyLint::Token::Token
    param.type.should  == :integer
    param.value.should == '10'
  end

  it 'Parse a method called on an object with parenthesis' do
    token = RubyLint::Parser.new('Struct.new(:name)').parse[0]

    token.class.should == RubyLint::Token::MethodToken
    token.name.should  == 'new'

    token.receiver.class.should == RubyLint::Token::VariableToken
    token.receiver.type.should  == :constant
    token.receiver.name.should  == 'Struct'

    token.parameters.class.should  == Array
    token.parameters.length.should == 1

    token.parameters[0].class.should == RubyLint::Token::Token
    token.parameters[0].type.should  == :symbol
    token.parameters[0].value.should == 'name'
  end

  it 'Parse a method called on an object without parenthesis' do
    token = RubyLint::Parser.new('Struct.new :name').parse[0]

    token.class.should == RubyLint::Token::MethodToken
    token.name.should  == 'new'

    token.receiver.class.should == RubyLint::Token::VariableToken
    token.receiver.type.should  == :constant
    token.receiver.name.should  == 'Struct'

    token.parameters.class.should  == Array
    token.parameters.length.should == 1

    token.parameters[0].class.should == RubyLint::Token::Token
    token.parameters[0].type.should  == :symbol
    token.parameters[0].value.should == 'name'
  end

  it 'Parse a method called on an object with a block passed' do
    token = RubyLint::Parser.new('Foo.bar { |example| example }').parse[0]

    token.class.should == RubyLint::Token::MethodToken
    token.name.should  == 'bar'

    token.receiver.class.should == RubyLint::Token::VariableToken
    token.receiver.type.should  == :constant
    token.receiver.name.should  == 'Foo'

    token.block.class.should            == RubyLint::Token::BlockToken
    token.block.parameters.class.should == RubyLint::Token::ParametersToken

    token.block.parameters.value.class.should  == Array
    token.block.parameters.value.length.should == 1
  end

  it 'Parse a method call with a bare Hash as a parameter' do
    token = RubyLint::Parser.new('language(:name => "Ruby")').parse[0]

    token.class.should == RubyLint::Token::MethodToken

    token.parameters.class.should  == Array
    token.parameters.length.should == 1

    token.parameters[0].class.should == RubyLint::Token::Token
    token.parameters[0].type.should  == :hash
  end

  it 'Parse a method call with a bare JSON style Hash as a parameter' do
    token = RubyLint::Parser.new('language(name: "Ruby")').parse[0]

    token.class.should == RubyLint::Token::MethodToken

    token.parameters.class.should  == Array
    token.parameters.length.should == 1

    token.parameters[0].class.should == RubyLint::Token::Token
    token.parameters[0].type.should  == :hash
  end
end
