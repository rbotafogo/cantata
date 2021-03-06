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

module GKnit

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------
  
  Polyglot.eval("R", <<-R)
    ruby_template = function(gem, family, template, type, ...) {
    print(gem)
    print(family)
    print(template)
    print(type)
    data_dir = eval.polyglot("ruby", "GKnit")$template_path(gem, family, template)
    print(data_dir)
    invoke(type, list(template = "template.tex", pandoc_args = paste0("--data-dir=", data_dir), ...))
  }
  R

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.template_path(gem, family, template)
    full_filename = Dir.glob("gknit-templates*", base: "#{Gem.default_dir}/gems")
    template_path = "#{Gem.default_dir}/gems/#{full_filename[0]}/#{family}/#{template}"
  end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.draft(file:, template:, package: nil,
                 create_dir: 'default', is_package: true, edit: true)
    
    # ignore the file extension if given. It should always be an .Rmd file
    file_basename = File.basename(file, File.extname(file))
    file = "#{file_basename}.Rmd"
    
    # resolve package file
    # TODO: if package is a rubygem, then look there somehow
    if (is_package)
      template_path =
        R.system__file("rmarkdown", "templates", template, package: package) >> 0
      raise "The template '#{template}' was not found in the package '#{package}'" if
        !(R.nzchar(template_path) >> 0)
    else
      full_filename = Dir.glob("gknit-templates*", base: "#{Gem.default_dir}/gems")
      template_path = "#{Gem.default_dir}/gems/#{full_filename[0]}/#{template}"
      puts template_path
      # raise "this is not an R package"
    end

    # read the template.yaml and confirm it has the right fields
    template_yaml = File.expand_path("template.yaml", template_path)
    raise "No 'template.yaml' file found for template '#{template}" if
      !File.file?(template_yaml)

    template_meta = R::Yaml::yaml__load(R.read_utf8(template_yaml))
    raise "template.yaml must contain 'name' and 'description' fields" if
      (template_meta.name.is__null || template_meta.description.is__null) >> 0
    puts "Creating template:"
    puts "Template name: #{template_meta.name >> 0}"
    puts "Description: #{template_meta.description >> 0}"

    if (create_dir == 'default')
      # check if template asks for new directory
      create_dir = template_meta.create_dir.isTRUE >> 0

      if (create_dir)
        raise "The directory '#{file_basename}' already exists" if Dir.exist?(file_basename)
      end
      
    end

    raise "File #{file} already exists" if File.file?("#{file_basename}/#{file}")
    FileUtils.cp_r("#{template_path}/skeleton", "#{file_basename}")
    # FileUtils.cp("#{template_path}/resources/template.tex", "#{file_basename}")
    File.rename("#{file_basename}/skeleton.Rmd", "#{file_basename}/#{file}")
  end
  
end

