require File.expand_path('../../../helper', __FILE__)

describe 'RubyLint::Parser' do
  it 'Parse an Array' do
    token = RubyLint::Parser.new('[10, 20]').parse[0]

    token.class.should == RubyLint::Token::Token
    token.type.should  == :array

    token.value.class.should  == Array
    token.value.length.should == 2

    token.line.should   == 1
    token.column.should == 8
    token.code.should   == '[10, 20]'

    token.value[0].class.should == RubyLint::Token::Token
    token.value[0].type.should  == :integer
    token.value[0].value.should == '10'

    token.value[1].class.should == RubyLint::Token::Token
    token.value[1].type.should  == :integer
    token.value[1].value.should == '20'
  end

  it 'Parse an Array using %w{}' do
    token = RubyLint::Parser.new('%w{10 20}').parse[0]

    token.class.should == RubyLint::Token::Token
    token.type.should  == :array

    token.value.class.should  == Array
    token.value.length.should == 2

    token.line.should   == 1
    token.column.should == 9
    token.code.should   == '%w{10 20}'

    token.value[0].class.should == RubyLint::Token::Token
    token.value[0].type.should  == :string
    token.value[0].value.should == '10'

    token.value[1].class.should == RubyLint::Token::Token
    token.value[1].type.should  == :string
    token.value[1].value.should == '20'
  end

  it 'Parse an Array using %W{}' do
    token = RubyLint::Parser.new('%W{10 20}').parse[0]

    token.class.should == RubyLint::Token::Token
    token.type.should  == :array

    token.value.class.should  == Array
    token.value.length.should == 2

    token.line.should   == 1
    token.column.should == 9
    token.code.should   == '%W{10 20}'

    token.value[0].class.should == RubyLint::Token::Token
    token.value[0].type.should  == :string
    token.value[0].value.should == '10'

    token.value[1].class.should == RubyLint::Token::Token
    token.value[1].type.should  == :string
    token.value[1].value.should == '20'
  end

  it 'Parse an Array index reference' do
    token = RubyLint::Parser.new("[10][0]").parse[0]

    token.class.should  == RubyLint::Token::Token
    token.line.should   == 1
    token.column.should == 4
    token.code.should   == '[10][0]'

    token.key.class.should  == Array
    token.key.length.should == 1

    token.key[0].class.should == RubyLint::Token::Token
    token.key[0].type.should  == :integer
    token.key[0].value.should == '0'
  end

  it 'Parse an Array index reference using a variable' do
    token = RubyLint::Parser.new("numbers = [10]\nnumbers[0]").parse[1]

    token.class.should  == RubyLint::Token::VariableToken
    token.line.should   == 2
    token.column.should == 0
    token.name.should   == 'numbers'
    token.code.should   == 'numbers[0]'

    token.key.class.should  == Array
    token.key.length.should == 1

    token.key[0].class.should == RubyLint::Token::Token
    token.key[0].type.should  == :integer
    token.key[0].value.should == '0'
  end

  it 'Parse multiple Array index references' do
    token = RubyLint::Parser.new("numbers = [10]\nnumbers[0,1]").parse[1]

    token.class.should  == RubyLint::Token::VariableToken
    token.line.should   == 2
    token.column.should == 0
    token.name.should   == 'numbers'
    token.code.should   == 'numbers[0,1]'

    token.key.class.should  == Array
    token.key.length.should == 2

    token.key[0].class.should == RubyLint::Token::Token
    token.key[0].type.should  == :integer
    token.key[0].value.should == '0'

    token.key[1].class.should == RubyLint::Token::Token
    token.key[1].type.should  == :integer
    token.key[1].value.should == '1'
  end

  it 'Parse the assignment of a value to an array index' do
    token = RubyLint::Parser.new("numbers = []\nnumbers[0] = 10").parse[1]

    token.class.should == RubyLint::Token::AssignmentToken

    token.line.should   == 2
    token.column.should == 12
    token.code.should   == 'numbers[0] = 10'

    token.value.class.should == RubyLint::Token::Token
    token.value.type.should  == :integer
    token.value.value.should == '10'

    token.receiver.class.should == RubyLint::Token::VariableToken
    token.receiver.name.should  == 'numbers'

    token.receiver.key.class.should  == Array
    token.receiver.key.length.should == 1

    token.receiver.key[0].class.should == RubyLint::Token::Token
    token.receiver.key[0].type.should  == :integer
    token.receiver.key[0].value.should == '0'
  end
end
