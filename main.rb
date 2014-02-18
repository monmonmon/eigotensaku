#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8

require './eigotensaku'
require './languagetool_corrector'

if ARGV.size < 4
  STDERR.puts('')
  exit 1
end

consumer_key        = ARGV[0]
consumer_secret     = ARGV[1]
access_token        = ARGV[2]
access_token_secret = ARGV[3]

corrector = LanguagetoolCorrector.new
tensaku = EigoTensaku.new(
        corrector,
        consumer_key,
        consumer_secret,
        access_token,
        access_token_secret,
        )
tensaku.run('@eigotensaku')
