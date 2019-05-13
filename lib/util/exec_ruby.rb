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

require 'stringio'

#----------------------------------------------------------------------------------------
# Class RC is used only as a context for all ruby chunks in the rmarkdown file.
# This allows for chunks to access local variables defined in other chunks.
#----------------------------------------------------------------------------------------

class RC

  attr_reader :out_list

  def initialize
    @out_list = R.list
  end

  def outputs(obj)
    @out_list = R.c(@out_list, obj)
  end

  def reset_outputs
    @out_list = nil
  end

  def get_binding
    binding
  end
  
end

RChunk = RC.new
RCbinding = RChunk.get_binding

#----------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------

module GalaazUtil

  #----------------------------------------------------------------------------------------
  # Executes the ruby code with the given options.
  # @param options [R::List] An R list of options
  # @return [R::List] an R list with everything that needs to be outputed.
  # The options are:
  # * options.code: the ruby code
  # * options[["eval"]]: evaluate if true
  # * options.echo: if true, show the source code of the chunk in the output
  # * options.message: if true, show error message if any exception in the ruby code
  # * options.warning: if true, show stack trace from the ruby code
  # * options.include: if true, include the code output
  # Note that we need to access the 'eval' element of the list by indexing as
  # options[["eval"]], this is because eval is a Ruby function and doing options.eval
  # will call the eval method on options, which is not what we want
  #----------------------------------------------------------------------------------------

  def self.exec_ruby(options)

    # RubyChunk.init
    
    # read the chunk code
    code = R.paste(options.code, collapse: "\n") >> 0
    
    # the output should be a list with the proper structure to pass to
    # function engine_output.  We first add the souce code from the block to
    # the list
    out_list = R.list(R.structure(R.list(src: code), class: 'source')) if
      options.echo >> 0

    begin

      # set $stdout to a new StringIO object so that everything that is
      # output from instance_eval is captured and can be sent to the
      # report
      $stdout = StringIO.new

      # Execute the Ruby code in the scope of class RubyChunk. This is done
      # so that instance variables created in one chunk can be used again on
      # another chunk
      # RChunk.instance_eval(code) if (options[["eval"]] >> 0)
      eval(code, RCbinding, __FILE__, __LINE__ + 1) if (options[["eval"]] >> 0)
      
      # add the returned value to the list
      # this should have captured everything in the evaluation code
      # it is not working since at least RC10.
      out = $stdout.string
      
      out_list = R.c(out_list, out)
      
    rescue StandardError => e

      # print the error message
      if (options.message >> 0)
        message = R.list(R.structure(R.list(message: e.message), class: 'message'))
        out_list = R.c(out_list, message)
      end

      # Print the backtrace of the error message
      if (options.warning >> 0)
        bt = ""
        e.backtrace.each { |line| bt << line + "\n"}
        warning = R.list(R.structure(R.list(message: bt), class: 'message'))
        out_list = R.c(out_list, warning)
      end

    rescue SyntaxError => e
      STDERR.puts "A syntax error occured in ruby block '#{options.label >> 0}'"
      raise SyntaxError.new(e)
      
    ensure
      # return $stdout to standard output
      $stdout = STDOUT
    end
    
    (options.include >> 0)? out_list : R.list
    
  end
  
  #----------------------------------------------------------------------------------------
  # Used by old gknit.  Will eventually be replaced by exe_ruby
  #----------------------------------------------------------------------------------------

  def self.exec_ruby_tor(code)

    # the output should be a list with the proper structure to pass to
    # function engine_output.
    out_list = R.list(R.structure(R.list(src: code), class: 'source'))
    
    # Set up standard output as a StringIO object.
    $stdout = StringIO.new
    RubyChunk.instance_eval(code)

    # this should have captured everything in the evaluation code
    # it is not working since at least RC10.
    out = $stdout.string

    out_list = R.c(out_list, out)
    
    # return $stdout to standard output
    $stdout = STDOUT
    R::Support.parse_arg(out_list)

  end
  
end
