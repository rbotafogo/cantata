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

require_relative 'r_methods'

module R

  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------

  class Object
    
    attr_reader :r_interop
    attr_accessor :statement
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def initialize(r_interop)
      @r_interop = r_interop
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def as__data__frame
      R.as__data__frame.call(@r_interop)
    end

    #--------------------------------------------------------------------------------------
    # @param r_interop [Interop] pointer to an R object
    # @return the R object wrapped in a Ruby class
    #--------------------------------------------------------------------------------------

    def self.build(r_interop)

      # if the value is actually not an r_interop, then just return it: native Ruby
      # object
      if (!Truffle::Interop.foreign?(r_interop))
        return r_interop
      # a matrix is also a vector... test should come before
      elsif (R::Support.eval("is.matrix").call(r_interop) == true)
        Matrix.new(r_interop)
      elsif (R::Support.eval("is.atomic").call(r_interop) == true)
        Vector.new(r_interop)
      elsif (R::Support.eval("is.function").call(r_interop) == true)
        Closure.new(r_interop)
      elsif (R::Support.eval("is.data.frame").call(r_interop) == true)
        DataFrame.new(r_interop)
      elsif (R::Support.eval("is.list").call(r_interop) == true)
        List.new(r_interop)
      elsif (R::Support.eval("typeof").call(r_interop) == "language")
        Language.new(r_interop)
      elsif (R::Support.eval("typeof").call(r_interop) == "expression")
        RExpression.new(r_interop)
      elsif (R::Support.eval("typeof").call(r_interop) == "name")
        p "i'm of type name"
        Name.new(r_interop)
      elsif (R::Support.eval("typeof").call(r_interop) == "symbol")
        RSymbol.new(r_interop)
      elsif (R::Support.eval("typeof").call(r_interop) == "environment")
        Environment.new(r_interop)
      else # Generic type
        p "Generic type: #{R::Support.eval("typeof").call(r_interop).to_s}"
        r_interop
      end

    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def method_missing_assign(column_name, arg)
      return setR_name("`[<-`", R.empty_symbol, column_name, arg)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def method_missing(symbol, *args, &block)

      name = R::Support.convert_symbol2r(symbol)

      case
      when block_given?
        R::Support.new_scope(symbol, self, *args, &block)
      when name =~ /(.*)=$/
        method_missing_assign($1, args[0])
      when name == "eval"
        # R function 'eval' needs to be called in a special way, since it expects
        # the second argument to be an environment.  If the arguments are packed
        # into a list, then there is no second argument and the function fails to
        # use the second argument as environment
        R::Support.r_evaluate(r_interop, *args)
      when args.length == 0
        # no arguments: 2 options: either a named item of the object or apply the function
        # to the object
        # if name is a named item of the object, then return the named item
        named = R::Support.eval("`%in%`").
                  call(name, R::Support.eval("names").call(@r_interop))
        (false === named || !(true === named || named[0])) ?
          R::Support.exec_function_name(name, @r_interop) :
          R::Support.exec_function_name("`[[`", @r_interop, name)
      else
        args.unshift(@r_interop)
        R::Support.exec_function_name(name, *args)
      end
        
    end
    
    #----------------------------------------------------------------------------------------
    # We use the following notation to access binary R functions such as %in%:
    # R.vec_ "in", list.
    # @param args [Array] The first element of the array is an R infix function, the other
    # arguments are the list of arguments for the function.
    #----------------------------------------------------------------------------------------

    def _(*args)
      name = "`%#{args.shift.to_s}%`"
      args.unshift(@r_interop)
      R::Support.exec_function_name(name, *args)
    end
        
    #--------------------------------------------------------------------------------------
    # Sets the current object self interop pointer to the returned value of the execution
    # of the given method with arguments. This method should be called when R will copy
    # the parameter, but in Ruby we want to hide the copying.
    # @param [Interop] Interop pointer to R function
    # @param [Array] Array of arguments 
    #--------------------------------------------------------------------------------------

    def setR(method, *args)
      @r_interop = R::Support.exec_function_i(method, @r_interop, *args)
      self
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def setR_name(method_name, *args)
      method = R::Support.eval(method_name)
      setR(method, *args)
      self
    end

    #--------------------------------------------------------------------------------------
    # Sets the names attribute of the object
    # @param [R::Object] names_vector is an RVector with the list of names.
    #--------------------------------------------------------------------------------------

    def names=(names_vector)
      setR_name("`names<-`", names_vector)
    end

    def names(*args)
      return R::Support.exec_function_name("names", @r_interop) if (args.length == 0)
      setR_name("`names<-`", *args)
      self
    end
        
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def rclass=(class_name)
      setR_name("`class<-`", class_name)
    end

    def rclass
      R::Support.exec_function_name("class", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def comment=(comment_text)
      setR_name("`comment<-`", comment_text)
    end
    
    def comment
      R::Support.exec_function_name("comment", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dim=(numeric_vector)
      setR_name("`dim<-`", numeric_vector)
    end

    def dim
      R::Support.exec_function_name("dim", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dimnames=(names_vector)
      setR_name("`dimnames<-`", names_vector)
    end

    def dimnames
      R::Support.exec_function_name("dimnames", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    # @bug Needed to create method R.row__names because dispatch is not working properly
    #--------------------------------------------------------------------------------------

    def row__names
      R::Support.exec_function(R::Support.get_row_names, @r_interop)
    end

    # since we need to call a method and the method changes the object, then we need to
    # change our internal pointer also @r_interop.  Ideally, just setting the row.names
    # should work.
    def row__names=(names_vector)
      @r_interop = R::Support.set_row_names.call(@r_interop, names_vector.r_interop)
      self
    end
      
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def tsp=(numeric_vector)
      setR_name("`tsp<-`", numeric_vector)
    end

    def tsp
      R::Support.exec_function_name("tsp", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def attr=(which: w, value: v)
      value = (R::Support.interop(value) ? value.r_interop : value)
      # setR(@@set_attr, which, value)
      setR_name("`attr<-`", which, value)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def pp
      R.print(r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def to_s

      cap = nil
      # dev = R::Device.new('png', width: 5, height: 7, dpi: 300, record: true) {
      cap = R::Support.capture.call(r_interop)
      # cap = R::Support.capture_output.call(r_interop)
      # }
      str = String.new
      (0...(cap.size - 1)).each do |i|
        str << cap[i] << "\n"
      end
      str << cap[cap.size - 1] if cap.size >= 1
      str
    end

  end
  
end