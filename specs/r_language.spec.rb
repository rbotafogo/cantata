# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2018 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
# and distribute this software and its documentation, without fee and without a signed 
# licensing agreement, is hereby granted, provided that the above copyright notice, this 
# paragraph and the following two paragraphs appear in all copies, modifications, and 
# distributions.
#
# IN NO EVENT SHALL RODRIGO BOTAFOGO BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF 
# THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RODRIGO BOTAFOGO HAS BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# RODRIGO BOTAFOGO SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE 
# SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS". 
# RODRIGO BOTAFOGO HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
# OR MODIFICATIONS.
##########################################################################################

require 'galaaz'

describe R::Language do

  #========================================================================================
  context "Working with symbols"  do

    it "should convert a Ruby Symbol to an R Symbol with '+'" do
      a = +:cyl
      expect(a.is_a? R::RSymbol).to eq true
      expect(a.to_s).to eq "cyl"
    end
    
    it "should assign to an R symbol and retrieve from it" do
      R.cyl = 10
      expect(~:cyl).to eq 10
    end

    it "should allow calling evaluate on the symbol" do
      R.cyl = 10
      expect(R.eval(~:cyl)).to eq 10
    end

  end
  
  #========================================================================================

  context "Executing R expressions" do

    it "should eval an R expression in the context of a list" do
      ct = R.list(a: 10, b: 20, c: 30)
      exp = :a + :b * :c
      expect(R.eval(exp, ct)).to eq 610
    end

    it "should eval an R function in the context of a list" do
      R.x = 5
      expect(R.eval(:x + 10)).to eq 15
      ct = R.list(x: 20)
      expect(R.eval(:x + 10, ct)).to eq 30
    end
    
  end


  #========================================================================================
  context "When working with Formulas" do
    # When working with formulas, Ruby symbols such be preceded by the '+' function.
    # If you want to make a formula such as 'a ~ b' in R, then this should be written
    # as '+:a =~ +:b'.  When, in an binary operation, the Ruby symbol will be converted
    # to an R symbol.  The formula '+:a =~ +:b', can also be written as '+:a =~ :b'.  Be
    # careful, however, when using the Ruby symbol without the '+' since in a more complex
    # formula, Ruby's precedence rules might not result in what is expected.  As an example
    # '+:a =~ :b * +:c' crashes with the error 'b' not found, since '*' has precedence over
    # '=~' and this is equivalent to '+:a =~ (:b * +:c)' and there is no sense in
    # multiplying a Ruby symbol. The recomendation is to always use the '+' function
    # before the Ruby symbol.
    
    it "should create a RSymbol from a Ruby Symbol using +" do
      sym = +:sym
      expect(sym.to_s).to eq "sym"
    end

=begin
    
    it "should create a formula without the lhs" do
      pending "formulas need to be reimplemented"
      formula = ~(:cyl + :exp)
      expect formula.to_s == '~.Primitive("+")(cyl, exp)'
      expect formula.typeof == 'language'
      expect formula.rclass == 'formula'
    end
    
    it "should create formulas with the '=~' operator" do
      formula = (:cyl =~ :exp)
      expect(formula.to_s) == '.Primitive("~")(cyl, exp)'
      expect formula.typeof == 'language'
      expect formula.rclass == 'formula'
      
      formula2 = (:cyl =~ :exp + :exp2 - :exp3)
      expect formula2.to_s == 'cyl ~ .Primitive("-")(.Primitive("+")(exp, exp2), exp3)'
      expect formula.typeof == 'language'
      expect formula.rclass == 'formula'
    end
=end
    
  end

end
