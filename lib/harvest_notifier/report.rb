# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/keys"

module HarvestNotifier
  class Report
    attr_reader :harvest, :slack, :harvest_users, :slack_users, :emails_whitelist, :missing_hours_threshold, :missing_hours_daily_threshold

    def initialize(harvest, slack)
      @harvest = harvest
      @slack = slack

      @harvest_users = prepare_harvest_users(harvest.users_list)
      @slack_users = prepare_slack_users(slack.users_list)

      @emails_whitelist = ENV.fetch("EMAILS_WHITELIST", "").split(",").map(&:strip)
      @missing_hours_threshold = ENV.fetch("MISSING_HOURS_THRESHOLD", 1.0).to_f
      @missing_hours_daily_threshold = ENV.fetch("MISSING_HOURS_DAILY_THRESHOLD", 1.0).to_f
    end

    def daily(date = Date.yesterday)
      report = harvest.time_report_list(date)
      users = with_slack(with_reports(report))

      filter(users) do |user|
        not_notifiable?(user) || full_time_daily_reported?(user)
      end
    end

    def monday(date = prior_friday(Date.today))
      report = harvest.time_report_list(date)
      users = with_slack(with_reports(report))

      filter(users) do |user|
        not_notifiable?(user) || full_time_daily_reported?(user)
      end
    end

    def weekly(from = Date.today.last_week, to = Date.today.last_week + 4)
      report = harvest.time_report_list(from, to)
      users = with_slack(with_reports(report))

      filter(users) do |user|
        not_notifiable?(user) || full_time_reported?(user)
      end
    end

    def prior_friday(date)
      days_before = (date.wday + 1) % 7 + 1
      date.to_date - days_before
    end

    private

    def not_notifiable?(user)
      inactive?(user) || contractor?(user) || without_weekly_capacity?(user) || whitelisted_user?(user)
    end

    def prepare_harvest_users(users)
      users["users"]
        .group_by { |u| u["id"] }
        .transform_values { |u| harvest_user(u.first) }
    end

    def harvest_user(user)
      hours = user["weekly_capacity"].to_f / 3600
      full_name = user.values_at("first_name", "last_name").join(" ")

      user.slice("email", "is_contractor", "is_active").merge(
        {
          "full_name" => full_name,
          "weekly_capacity" => hours,
          "missing_hours" => hours,
          "missing_hours_daily" => 8,
          "total_hours" => 0
        }
      )
    end

    def prepare_slack_users(users)
      users["members"]
        .group_by { |u| u["profile"]["email"].downcase }
        .transform_values(&:first)
    end

    def with_reports(reports)
      reports["results"].each.with_object(harvest_users) do |report, users|
        id = report["user_id"]

        reported_hours = report["total_hours"].to_f

        users[id]["email"] = users[id]["email"].downcase
        users[id]["missing_hours_daily"] -= reported_hours
        users[id]["missing_hours"] -= reported_hours
        users[id]["total_hours"] += reported_hours
      end
    end

    def with_slack(users)
      users.transform_values do |user|
        user.merge("slack_id" => slack_id(user))
      end
    end

    def slack_id(user)
      return "" unless slack_users.include?(user["email"])

      slack_users[user["email"]]["id"]
    end

    def filter(users)
      users
        .reject { |_id, user| yield(user) }
        .values
        .map(&:symbolize_keys)
    end

    def whitelisted_user?(user)
      emails_whitelist.include?(user["email"])
    end

    def time_reported?(user)
      user["total_hours"].positive?
    end

    def full_time_daily_reported?(user)
      time_reported?(user) && missing_hours_daily_insignificant?(user)
    end

    def full_time_reported?(user)
      time_reported?(user) && missing_hours_insignificant?(user)
    end

    def without_weekly_capacity?(user)
      user["weekly_capacity"].zero?
    end

    def missing_hours_daily_insignificant?(user)
      user["missing_hours_daily"] <= missing_hours_daily_threshold
    end

    def missing_hours_insignificant?(user)
      user["missing_hours"] <= missing_hours_threshold
    end

    def contractor?(user)
      user["is_contractor"]
    end

    def inactive?(user)
      !user["is_active"]
    end
  end
end
