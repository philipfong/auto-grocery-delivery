### What is this? ###

Everyone's been having a tough time getting delivery slots for grocery delivery during the Covid-19 epidemic. This is intended to save folks some time refreshing their browser throughout the day.

So far, I've written scripts for Instacart and Amazon Whole Foods (not to be confused with Prime Now).

### How does this work? ###

1. The script will open a brand new browser session in Chrome
2. It will then visit the website in that Chrome window. From there you can shop around and add items to your cart.
3. It will wait for you to reach the checkout page (for Instacart) or your cart page (for Amazon). If there are no delivery windows available, the script will wait a random number of seconds and refresh the page.
4. If a timeslot becomes open, it will select it immediately and attempt the checkout process automatically.

### Some advantages over other tools ###

A lot of other scripts will add sleep/delays in order to wait for pages. This set of scripts waits for page elements with a timeout of 10 seconds. This is all credit to [team capybara](https://github.com/teamcapybara/capybara).

### Pre-requisites ###

The easiest part is to just fill your cart. Go to the checkout screen (Instacart) or cart screen (Amazon) when you're done. For Instacart, this will not work if you have items added from multiple stores, so please stick with just one.

The next easiest part is making sure you complete _all_ of the information in your account profiles. This includes address info, payment information, and your phone number. Why? Because this script has _zero_ knowledge of your personal information, so it will not try to enter these automatically.

The hardest part will be getting this script running in the first place. If you're not too tech-savvy, it can be a little bit of a challenge. I've really dumbed down the 'Install and Run' steps below, and will try to add a tutorial when I can.

### Install and Run ###

1. Install a Ruby version manager such as rbenv or rvm (on Windows, check out https://rubyinstaller.org/)
2. Clone the repo
3. `gem install bundler`
4. `bundle install`
5. Run scripts: `rspec spec/features/instacart.rb`
6. Profit
