# frozen_string_literal: true

require "jbuilder"

module HarvestNotifier
  module Templates
    class Base
      attr_reader :assigns, :channel, :url, :missing_hours_threshold, :missing_hours_daily_threshold

      def self.generate(assigns = {})
        new(assigns).generate
      end

      def initialize(assigns)
        @channel = ENV.fetch("SLACK_CHANNEL", "general")
        @url = ENV.fetch("HARVEST_URL", "https://harvestapp.com/")
        @missing_hours_threshold = ENV.fetch("MISSING_HOURS_THRESHOLD", 1.0).to_f
        @missing_hours_daily_threshold = ENV.fetch("MISSING_HOURS_DAILY_THRESHOLD", 1.0).to_f

        @assigns = assigns
      end

      def generate; end
    end
  end
end
