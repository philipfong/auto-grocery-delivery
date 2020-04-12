require 'spec_helper'

feature "Check time slots for Whole Foods" do

  scenario "Amazon Whole Foods" do
    open_amazon
    wait_for_cart
    goto_time_windows
    check_availability
  end

end

def open_amazon
  begin
    visit 'https://www.amazon.com/'
    page.should have_text 'Whole Foods'
  rescue Exception => e
    Log.error 'You might be having problems getting this running in the first place, or Amazon changed their homepage content. Please reach out to me on Github for help.'
  end
end

def wait_for_cart
  cart_found = false
  while !cart_found
    begin
      page.should have_css('.a-button-primary', :text => 'Checkout Whole Foods Market Cart')
      cart_found = true
      Log.info 'Hi there! Looks like you are at your Amazon cart. Proceeding with checkout...'
    rescue RSpec::Expectations::ExpectationNotMetError
      Log.info 'I am waiting for you to get to your cart. Take your time!'
      sleep 60
      retry
    end
  end
end

def goto_time_windows
  begin
    find('.a-button-primary', :text => 'Checkout Whole Foods Market Cart').click
    page.should have_text('Before you checkout')
    all('.a-button-primary', :text => 'Continue', :count => 2)[0].click
    page.should have_text('Substitution preferences')
    all('.a-button-primary', :text => 'Continue', :count => 2)[0].click
  rescue RSpec::Expectations::ExpectationNotMetError
    Log.error 'I ran into some problems moving across pages. I\'ll start over.'
    restart_checkout
  end
end

def check_availability
  @timeslot_found = false
  while !@timeslot_found
    begin
      page.should have_text('Schedule your order')
    rescue RSpec::Expectations::ExpectationNotMetError
      Log.info 'Maybe got kicked out to some other page? Going to try to checkout for you again.'
      restart_checkout
      next # I can't seem to break out this begin-rescue block into its own method because of this call to next
    end
    check_dates
    retry_if_nodelivery
  end
end

def check_dates
  begin
    date_buttons = all('button[name*="2020"]', :minimum => 1)
    date_buttons.each.with_index do |button, index|
      if button.has_text?('Not available')
        Log.info 'Found no slots on button number %s' % (index + 1)
      else
        date_found = date_buttons[index][:name]
        Log.info 'Oooh-weee, we found a timeslot for %s!' % date_found
        timeslot_found = true
        # I have no idea what to do here yet, since I don't really know what a valid timeslot actually looks like.
        page.save_screenshot # Save screenshot as proof, at least.
        page.save_page
        visit 'https://html5zombo.com/' # Play a sound. Lol.
      end
    end
  rescue RSpec::Expectations::ExpectationNotMetError
    Log.error 'Ehh, something went wrong checking the text in the date buttons. Let\'s start over?'
    restart_checkout
  end
end

def retry_if_nodelivery
  if @timeslot_found == false
    random_seconds = rand(10..60)
    Log.info 'Bummer, nothing is available. Trying again after waiting for %s seconds.' % random_seconds
    find('.a-button-primary', :text => 'Continue').click # Do this so Capybara can detect change in page refresh
    page.should have_text('Select a window to continue')
    sleep random_seconds
    visit current_url
    page.should_not have_text('Select a window to continue')
  end
end

def restart_checkout
  visit 'https://www.amazon.com/gp/cart/view.html?ref_=nav_cart'
  wait_for_cart
  goto_time_windows
end