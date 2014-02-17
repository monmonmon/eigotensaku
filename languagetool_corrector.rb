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
# XMLの属性例
#         category='Possible Typo'
#         contextoffset='0'
#         errorlength='6'
#         fromx='0'
#         fromy='0'
#         tox='6'
#         toy='0'
#         offset='0'
#         locqualityissuetype='misspelling'
#         msg='Possible spelling mistake found'
#         replacements='hello'
#         ruleId='MORFOLOGIK_RULE_EN_US'
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

# <?xml version="1.0" encoding="UTF-8"?>
# <matches buildDate="2014-01-13 11:46" software="LanguageTool" version="2.5-SNAPSHOT">
#   <language name="English (US)" shortname="en-US"/>
#   <error category="Possible Typo" context="@hello this is a pen?!!#$%&amp;&apos;()" contextoffset="0" errorlength="6" fromx="0" fromy="0" locqualityissuetype="misspelling" msg="Possible spelling mistake found" offset="0" replacements="hello" ruleId="MORFOLOGIK_RULE_EN_US" tox="6" toy="0"/>
#   <error category="Miscellaneous" context="@hello this is a pen?!!#$%&amp;&apos;()" contextoffset="27" errorlength="1" fromx="27" fromy="0" locqualityissuetype="typographical" msg="Unpaired bracket or similar symbol" offset="27" replacements="" ruleId="EN_UNPAIRED_BRACKETS" tox="28" toy="0"/>
# </matches>

# before: [Music Video] Tech N9ne ft. Kendrick Lamar, MAYDAY &amp; Kendall Morgan – Fragile |  http://t.co/ESqLJLbiXU
# after:  [Music Video] Tech N9ne ft. Kendrick Lamar, MAYDAY &amp; Kendall Morgan – Fragile |
# [Music Video] Tech N9ne ft. Kendrick Lamar, MAYDAY &amp; Kendall Morgan – Fragile |
#   Possible Typo: misspelling: Possible spelling mistake found (x:51-55, y:0-0) replacement: amp#camp#damp#lamp#ramp#tamp#vamp
# before: Ukraine's Fragile Cease-Fire Is Met With Reports of Brutality http://t.co/gI6jVqpXuO
# after:  Ukraine's Fragile Cease-Fire Is Met With Reports of Brutality
# Ukraine's Fragile Cease-Fire Is Met With Reports of Brutality
# before: A fragile silver line emerges as if a distant memory traced from the unconscious  http://t.co/69kduqYCgv
# after:  A fragile silver line emerges as if a distant memory traced from the unconscious
# A fragile silver line emerges as if a distant memory traced from the unconscious
# before: #WorldNews Ukraine's Fragile Cease-Fire Is Met With Reports of Brutality via New York Times http://t.co/7UgNTaLjVT
# after:  Ukraine's Fragile Cease-Fire Is Met With Reports of Brutality via New York Times
# Ukraine's Fragile Cease-Fire Is Met With Reports of Brutality via New York Times
# before: it just goes to show how fragile this heart can be
# after:  it just goes to show how fragile this heart can be
# it just goes to show how fragile this heart can be
#   Capitalization: typographical: This sentence does not start with an uppercase letter (x:0-2, y:0-0) replacement: It
