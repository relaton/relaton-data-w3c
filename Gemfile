# frozen_string_literal: true
source "https://rubygems.org"

gem 'relaton-w3c', "~> 2.1"

# TEMP: until lutaml/lutaml-model#681 is merged & released, pin to the
# branch that loosens the `liquid ~> 5.0` runtime requirement so Jekyll
# (which transitively requires `liquid ~> 4.0`) can coexist in the
# deploy bundle.
gem 'lutaml-model', github: 'lutaml/lutaml-model', branch: 'loosen-liquid-pin'

eval File.read("Gemfile.deploy"), nil, "Gemfile.deploy" # rubocop:disable Security/Eval
