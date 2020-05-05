### What is this? ###

Everyone's been having a tough time getting delivery slots for grocery delivery during the Covid-19 pandemic. This is intended to save folks some time refreshing their browser throughout the day.

So far, I've written scripts for Instacart and Amazon Whole Foods (not to be confused with Prime Now).

### How does this work? ###

1. The script will open a brand new browser session in Chrome
2. It will then visit the website in that Chrome window. From there you can shop around and add items to your cart, but it's recommended that you have your cart already filled prior to running this.
3. It will wait for you to reach the checkout page (for Instacart) or your cart page (for Amazon). If there are no delivery windows available, the script will wait a random number of seconds and refresh the page.
4. If a timeslot becomes open, it will select it immediately and attempt the checkout process automatically.

### Some advantages over other tools ###

A lot of other scripts will add sleep/delays in order to wait for pages. This set of scripts waits for page elements with a timeout of 5 seconds. This is all credit to [team capybara](https://github.com/teamcapybara/capybara).

Other than the tech stack behind it, a lot of effort was made to work around some of the flakiness that some of these sites present due to the traffic they're getting. The scripts here are also designed to step all the way from cart to successful checkout on its own, not simply alert users to an open delivery window. In my testing, these time windows are gone quickly (usually in less than a minute) rendering these type of "refresh and alert" scripts less-than-useful.

### Pre-requisites ###

The easiest part is to just fill your cart. Go to the checkout screen (Instacart) or cart screen (Amazon) when you're done. For Instacart, this will not work if you have items added from multiple stores, so please stick with just one.

The next easiest part is making sure you complete _all_ of the information in your account profiles. This includes address info, payment information, and your phone number. Why? Because this script has _zero_ knowledge of your personal information, so it will not try to enter these automatically.

The hardest part will be getting this script running in the first place. If you're not too tech-savvy, it can be a little bit of a challenge. I've really dumbed down the 'Install and Run' steps below, and will try to add a tutorial when I can.

### Installation ###

1. Install a Ruby version manager such as rbenv or rvm (on Windows, check out https://rubyinstaller.org/)
2. Clone the repo
3. `gem install bundler`
4. `bundle install`

### Running ###

1. `rspec spec/features/wholefoods.rb` or `rspec spec/features/instacart.rb`
2. (For Whole Foods) This works better if you set your password in your terminal first (but is absolutely not required). This is because Amazon has prompted for the account password again during the checkout process. This will set an environmental variable that only the local computer has any knowledge of. Pretending that your password is `password123`:
* For Windows, type in `SET PW=password123`, hit `ENTER`, then run the commands in step 1
* For Mac, prepend `PW=password123 ` to the commands in step 1
3. If you're having trouble on Mac, try to prepend `bundle exec ` to your command

New option (for Whole Foods): Just set `SAMEDAY=yes`. Looks for same-day delivery for up to 4 hours. After that time, will expand search to all dates.
