#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8

require 'uri'
require 'rexml/document'
require 'net/http'

class LanguagetoolCorrector
  # @@baseuri = "https://languagetool.org:8081/?language=en-US&text="
  @@baseuri = "http://localhost:8000/?language=en-US&text="

  def correct(text, screen_name)
    text = URI.escape(text.strip, /[^\w\s]/).gsub(/\s+/, '+')
    query_uri = @@baseuri + text
    uri = URI.parse(query_uri)
    response = Net::HTTP.get_response(uri)
    if response.code == "200"
      xml_text = response.body
      doc = REXML::Document.new(xml_text)
      messages = []
      doc.elements.each('matches/error') do |e|
        attr = e.attributes
        message = "@ymdsmn_bot #{attr['category']}: #{attr['locqualityissuetype']}: #{attr['msg']} (x:#{attr['fromx']}-#{attr['tox']}, y:#{attr['fromy']}-#{attr['toy']}) replacement: #{attr['replacements']}"
        puts ">> #{message}"
        messages << message.slice(0, 140)
      end
    else
      # API実行に失敗
      raise "API execution failed"
    end
    messages
  end
end
