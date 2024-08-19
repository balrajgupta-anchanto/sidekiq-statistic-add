# frozen_string_literal: true

module Sidekiq
  module Statistic
    class Runtime
      def initialize(redis_statistic, worker, values = nil)
        @redis_statistic = redis_statistic
        @worker = worker
        @values = values
      end

      def values_hash
        {
          last: last_runtime,
          max: max_runtime.round(3),
          min: min_runtime.round(3),
          average: average_runtime.round(3),
          ninety_fifth_percentile: ninety_fifth_percentile.round(3),
          total: total_runtime.round(3)
        }
      end

      def max_runtime
        values(:max_time).map(&:to_f).max || 0.0
      end

      def min_runtime
        values(:min_time).map(&:to_f).min || 0.0
      end

      def last_runtime
        @redis_statistic.statistic_for(@worker).last[:last_time]
      end

      def total_runtime
        values(:total_time).map(&:to_f).inject(:+) || 0.0
      end

      def average_runtime
        averages = values(:average_time).map(&:to_f)
        count = averages.count
        return 0.0 if count == 0
        averages.inject(:+) / count
      end
      def ninety_fifth_percentile
        ninety_fifth_percentile_values = values(:ninety_fifth_percentile).map(&:to_f)
        size = ninety_fifth_percentile_values.count
        ninety_fifth_percentile_values.sort[((size * 0.95).ceil) - 1] || 0.0
      end
        

    private

      def values(key)
        @values ||= @redis_statistic.statistic_for(@worker)
        @values = @values.is_a?(Array) ? @values : [@values]
        @values.map{ |s| s[key] }.compact
      end
    end
  end
end
