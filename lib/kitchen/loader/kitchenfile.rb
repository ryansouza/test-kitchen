# -*- encoding: utf-8 -*-
#
# Author:: Ryan Souza (<rydsouza@gmail.com>)
#
# Copyright (C) 2013, Ryan Souza
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'hashie'

module Kitchen

  module Loader

    # YAML file loader for Test Kitchen configuration. This class is
    # responisble for parsing the main YAML file and the local YAML if it
    # exists. Local file configuration will win over the default configuration.
    # The client of this class should not require any YAML loading or parsing
    # logic.
    #
    class Kitchenfile

      attr_reader :config_file

      # Creates a new loader that can parse and load YAML files.
      #
      # @param config_file [String] path to Kitchen config YAML file
      # @param options [Hash] configuration for a new loader
      # @option options [String] :process_erb whether or not to process YAML
      #   through an ERB processor (default: `true`)
      # @option options [String] :process_local whether or not to process a
      #   local kitchen YAML file, if it exists (default: `true`)
      def initialize(config_file = nil, options = {})
        @config_file = File.expand_path(config_file || default_config_file)
      end

      # Reads, parses, and merges YAML configuration files and returns a Hash
      # of tne merged data.
      #
      # @return [Hash] merged configuration data
      def read
        if ! File.exists?(config_file)
          raise UserError, "Kitchenfile #{config_file} does not exist."
        end

        config_hash
      end

      protected

      def default_config_file
        File.join(Dir.pwd, 'Kitchenfile')
      end

      def config_hash
        dsl = Object.new

        def dsl.config
          @_config ||= Hashie::Mash.new
        end

        dsl.instance_eval read_file(config_file), config_file, 1

        process_dsl_hash Util.symbolized_hash(dsl.config.to_hash)
      end

      def process_dsl_hash(hash)
        hash[:platforms] = hash[:platforms].map {|name,opts| opts.merge! name: name.to_s }
        hash[:suites] = hash[:suites].map {|name,opts| opts.merge! name: name.to_s }

        hash
      end

      def read_file(file)
        File.exists?(file.to_s) ? IO.read(file) : ""
      end
    end
  end
end
