# Slack Harvest Reminder

[![Build Status](https://flatstack.semaphoreci.com/badges/harvest-notifier.svg)](https://flatstack.semaphoreci.com/projects/harvest-notifier)
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/beintelligent/harvest-notifier)

Slack Harvest Reminder is an integration between Harvest and Slack which automatically reminds users who forget to mark their working hours in Harvest.

This is a Ruby 2.6.5 library for installation on Daily Heroku Scheduler.
Notification is determined from Harvest API V2.

## Features

There are 3 types of reports: Daily, Monday and Weekly.

- Daily Report is generated on weekdays (except Monday) and shows those users who did not fill the minimum quantity of hours in their timesheet for the previous day.

- Monday Report is generated on Mondays and shows those users who did not fill the minimum quantity of hours in their timesheet for the previous Friday.

- Weekly Report is generated every Monday and shows those users who still need to report the required working hours for last week.

This integration allows to:
- mention users in the Slack
- refresh report result
- quickly report the working hours from the link
- set up custom report schedule
- configure a whitelist which consists of users, who don't need to be notified in Slack
- set up a threshold for daily hours and another for weekly hours
- select the slack channel to use

![Example](https://user-images.githubusercontent.com/30506741/95692380-ca57d380-0c81-11eb-9e77-d68b866b29c9.png)

## Quick Start

1. Prepare access tokens
  * Create Personal Access Tokens on [Harvest](https://id.getharvest.com/developers).

  * Create [Slack app](https://api.slack.com/apps). You can find official guide [here](https://slack.com/intl/en-ru/resources/using-slack/app-launch).
  * Create Bot User OAuth Access Token
  * Add following scopes to Bot:
      ```bash
      chat:write
      users:read
      users:read.email
      ```
  * Add app to Slack channel.

2. [Deploy to Heroku](https://heroku.com/deploy?template=https://github.com/beintelligent/harvest-notifier)

3. Configure following ENV variables
    ```bash
    heroku config:set HARVEST_TOKEN=harvest-token
    heroku config:set HARVEST_ACCOUNT_ID=harvest-account-id
    heroku config:set SLACK_TOKEN=slack-bot-token
    heroku config:set SLACK_CHANNEL=slack-channel
    heroku config:set EMAILS_WHITELIST=user1@example.com, user2@example.com, user3@example.com
    # EMAILS_WHITELIST is a variable that lists emails separated by commas, which don't need to be notified in Slack.
    # For example, administrators or managers.
    heroku config:set MISSING_HOURS_THRESHOLD=1.0
    # MISSING_HOURS_THRESHOLD is a variable that indicates the weekly minimum threshold of hours at which the employee will not be notified in Slack.
    # For example, 2.5 or 4. The default threshold is 1 hour. Leave empty if satisfied with the default value.
    heroku config:set MISSING_HOURS_DAILY_THRESHOLD=1.0
    # MISSING_HOURS_DAILY_THRESHOLD is a variable that indicates the daily minimum threshold of hours at which the employee will not be notified in Slack.
    # For example, 2.5 or 4. The default threshold is 1 hour. Leave empty if satisfied with the default value.
    heroku config:set TZ=Pacific/Auckland
    # TZ is the timezone to use for getting the hours and setting messages
    ```

4. Add job in Heroku Scheduler

  * ```bin/rake reports:daily``` for daily report
  * ```bin/rake reports:monday``` for monday report
  * ```bin/rake reports:weekly``` for weekly report


## Support

  If you have any questions or suggestions, send an issue, we will try to help you

## Quality tools

* `bin/quality` based on [RuboCop](https://github.com/bbatsov/rubocop)
* `.rubocop.yml` describes active checks

## Develop

1. Сlone repo
```bash
git clone https://github.com/beintelligent/harvest-notifier.git
cd harvest-notifier
```

2. Setup project
```bash
bin/setup
```

3. Check specs and run quality tools
```bash
bin/build
```

## Credits

This repository is a FORK from [Harvest Notifier](https://github.com/fs/harvest-notifier).

All the credits goes to that team.

Our team, added a monday report and added small improvements (e.g. adding a daily threshold).