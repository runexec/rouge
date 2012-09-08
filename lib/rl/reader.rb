# encoding: utf-8
require 'rl/core'

class RL::Reader
  class UnexpectedCharacterError < StandardError; end
  class TrailingDataError < StandardError; end
  class EndOfDataError < StandardError; end

  def self.read(input)
    new(input).lex
  end

  def initialize(input)
    @src = input
    @n = 0
  end

  def lex sub=false
    while peek =~ /[\s,]/
      consume
    end

    r = 
      case peek
      when NUMBER
        number
      when SYMBOL
        symbol
      when /:/
        keyword
      when /"/
        string
      when /\(/
        list
      when /'/
        quotation
      when /{/
        map
      else
        raise UnexpectedCharacterError, "#{peek} in #lex"
      end

    if not sub
      while peek =~ /[\s,]/
        consume
      end
      if @n < @src.length
        raise TrailingDataError, "remaining in #lex: #{@src[@n..-1]}"
      end
    end

    r
  end

  private

  def number
    slurp(NUMBER).gsub(/\D+/, '').to_i
  end

  def symbol
    slurp(SYMBOL).intern
  end

  def keyword
    begin
      slurp /:"/
      @n -= 1
      s = string
      RL::Keyword[s.intern]
    rescue UnexpectedCharacterError
      RL::Keyword[slurp(/^:[a-zA-Z0-9\-_!\?\*\/]+/)[1..-1].intern]
    end
  end

  def string
    s = ""
    t = consume
    while true
      c = consume

      if c.nil?
        raise EndOfDataError, "in string, got: #{s}"
      end

      if c == t
        break
      end

      if c == ?\\
        c = consume

        case c
        when nil
          raise EndOfDataError, "in escaped string, got: #{s}"
        when /[abefnrstv]/
          c = {?a => ?\a,
               ?b => ?\b,
               ?e => ?\e,
               ?f => ?\f,
               ?n => ?\n,
               ?r => ?\r,
               ?s => ?\s,
               ?t => ?\t,
               ?v => ?\v}[c]
        else
          # Just leave it be.
        end
      end

      s += c
    end
    s
  end

  def list
    consume
    r = []

    while true
      if peek == ')'
        break
      end
      r << lex(true)
    end

    consume
    r
  end

  def quotation
    consume
    [:quote, lex(true)]
  end

  def map
    consume
    r = {}

    while true
      if peek == '}'
        break
      end
      k = lex(true)
      v = lex(true)
      r[k] = v
    end

    consume
    r
  end

  def slurp re
    @src[@n..-1] =~ re
    raise UnexpectedCharacterError, "#{@src[@n]} in #slurp #{re}" if !$&
    @n += $&.length
    $&
  end

  def peek
    @src[@n]
  end

  def consume
    c = peek
    @n += 1
    c
  end

  NUMBER = /^[0-9][0-9_]*/
  SYMBOL = /^[a-zA-Z0-9\-_!\?\*\/]+/
end

# vim: set sw=2 et cc=80: