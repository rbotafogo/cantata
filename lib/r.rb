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

require_relative 'robject'
require_relative 'ruby_extensions'

module R

  RCONSTANTS = ["LETTERS", "letters", "month.abb", "month.name", "pi"]
    
  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.eval(string)
    Polyglot.eval("R", string)
  end
    
  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.parse2list(*args)
    
    dbk_assign = Polyglot.eval("R", "`[[<-`")
    
    params = Polyglot.eval("R", "list()")
    
    args.each_with_index do |arg, i|
      if (Truffle::Interop.foreign?(arg) == true)
        params = dbk_assign.call(params, i+1, arg)
      elsif (arg.is_a? R::Object)
        params = dbk_assign.call(params, i+1, arg.r_interop)
      elsif (arg.is_a? Hash)
        arg.each_pair do |key, value|
          k = key.to_s.gsub(/__/,".")
          value = value.r_interop if value.is_a? R::Object
          params = dbk_assign.call(params, k, value) 
        end
      else
        params = dbk_assign.call(params, i+1, arg)
      end
    end

    params
    
  end
    
  #----------------------------------------------------------------------------------------
  # @param function_name [String] Name of the R function to execute
  # @param internal [Boolean] true if returning to an internal object, i.e., does not
  # wrap the return object in a Ruby object
  # @args [Array] Array of arguments for the function
  #----------------------------------------------------------------------------------------

  def self.exec_missing(function_name, internal, *args)
    pl = parse2list(*args)
    
    # p pl
    # p "list argument is: "
    # Polyglot.eval("R", "print.default").call(pl)
    # build an RObject from the returned value
    
    internal ? eval("do.call").call(eval(function_name), pl) :
      R::Object.build(eval("do.call").call(eval(function_name), pl))
  end
  
  #----------------------------------------------------------------------------------------
  # Process the missing method
  # @param symbol [Symbol]
  # @param internal [Boolean] true if the method will return to an internal method, i.e.,
  # it should not wrap the return value inside an R::Object
  # @param object [Ruby Object] the ruby object to which the method is applied, false if
  # it is not applied to an object
  #----------------------------------------------------------------------------------------
  
  def self.process_missing(symbol, internal, *args)

    name = symbol.to_s
    # convert '__' to '.'
    name.gsub!(/__/,".")
    # Method 'rclass' is a substitute for R method 'class'.  Needed, as 'class' is also
    # a Ruby method on an object
    name.gsub!("rclass", "class")

    if name =~ /(.*)=$/
    else
      # check to see if the given name is either a constant or a variable in the
      # global environment
      return R.eval("name") if (args.length == 0 &&
                                (RCONSTANTS.include? name || R.eval("#{name} %in% ls()")))
      exec_missing(name, internal, *args)
    end
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.method_missing(symbol, *args)
    process_missing(symbol, false, *args)
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.internal_eval(symbol, *args)
    process_missing(symbol, true, *args)
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.interop(object)
    Truffle::Interop.foreign?(object)
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  private
  
  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------
  
  def self.parse(*args)

    params = Array.new
    keys = []
    values = []
    
    args.each do |arg|
      if (Truffle::Interop.foreign?(arg) == true)
        params << arg
      elsif (arg.is_a? R::Object)
        params << arg.r_interop
#=begin        
      elsif (arg.is_a? Hash)
        arg.each_pair do |key, value|
          keys << key.to_s.gsub(/__/,".")
          pa = parse(value)[0]
          values << pa
        end
#=end
      else
        params << arg
      end
    end
    
    # return [params, keys, values.flatten]
    return params

  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.pm(symbol, internal, *args)

    name = symbol.to_s
    # convert '__' to '.'
    name.gsub!(/__/,".")
    # Method 'rclass' is a substitute for R method 'class'.  Needed, as 'class' is also
    # a Ruby method on an object
    name.gsub!("rclass", "class")

    # params, keys, values = R.parse(*args)
    params = parse(*args)
    # pl = parse2list(*args)

    # p name
    # p pl
    # Polyglot.eval("R", "print.default").call(pl)

    # build an RObject from the returned value
    internal ? eval(name).call(*params) : R::Object.build(eval(name).call(*params))
    # internal ? eval(name).call(pl) : R::Object.build(eval(name).call(pl))
    
  end

end

require_relative 'rvector'

=begin   
process_missing:
    if (keys.size > 0)
      list_names = Array.new(params.size) {""}
      parameters = params.concat(values)
      list_names.concat(keys)
      params_list = R.eval("list").call(*parameters)
      @@make_params.call(params_list, list_names)
      return R::Object.build(eval("do.call").call(name, params_list))
    end
=end

=begin
parse Array:
      # Needs to consider what should be done with a Ruby Array sent to R as
      # a parameter.  Should it be converted to an R vector or be a foreign
      # pointer?        
      elsif (arg.is_a? Array)
        if (arg.size == 1)
          params << arg[0]
        else
          # convert the Ruby array to an R vector.  Does not work recursively
          # i.e., [1, 2, 3, [4, 5, 6]] will only convert the first level
          # array and [4, 5, 6] will be a foreign pointer in R.  Should be
          # fixed in future version.
          params << R.c(*arg).r_interop
        end
=end
