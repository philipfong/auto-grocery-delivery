### What is this? ###

Everyone's been having a tough time getting delivery slots for grocery delivery during the Covid-19 epidemic. This is intended to save folks some time refreshing their browser throughout the day.

So far, I've written a script for Instacart only.

### How does this work? ###

1. The script will open a brand new browser session in Chrome
2. It will then visit the Instacart page. From there you can shop around and add items to your cart.
3. It will wait for you to reach the checkout page. Assuming that there are no delivery windows, the script will wait a random number of seconds and refresh the page.
4. If a timeslot becomes open, it will select it immediately and attempt the checkout process automatically.

### Prequisites ###

The easiest part is to just select your store and fill your cart. Go to the checkout screen when you're done. This will not work if you have items added from multiple stores, so please stick with just one.

The next easiest part is making sure you complete _all_ of the information in your Instacart account profile. This includes adding one address, one piece of payment information, and your phone number. Why? Because this script has _zero_ knowledge of your personal information, so it will not try to enter these automatically.

The hardest part will be getting this script running in the first place. If you're not too tech-savvy, it can be a little bit of a challenge. I've really dumbed down the 'Install and Run' steps below, and will try to add a tutorial when I can.

### Install and Run ###

1. Install a Ruby version manager such as rbenv or rvm
2. Clone the repo
3. `gem install bundler`
4. `bundle install`
5. Run scripts: `rspec spec/features/instacart.rb`
6. Profit