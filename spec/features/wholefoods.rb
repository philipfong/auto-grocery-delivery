require 'spec_helper'

feature "Check time slots for Whole Foods" do

  scenario "Amazon Whole Foods" do
    open_amazon
    wait_for_cart
    goto_time_windows
    get_timeslot
    complete_checkout
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

def get_timeslot
  @timeslot_found = false
  while !@timeslot_found
    begin
      page.should have_text('Schedule your order', :wait => 30) # This page can show up so embarassingly slow for Amazon. Pls.
    rescue RSpec::Expectations::ExpectationNotMetError
      Log.info 'Maybe got kicked out to some other page? Going to try to checkout for you again.'
      restart_checkout
      next
    end
    check_availability
    retry_if_no_availability
  end
end

def check_availability
  begin
    date_buttons = all('button[name*="2020"]', :minimum => 1)
    date_buttons.each.with_index do |button, index|
      name = date_buttons[index][:name]
      if button.has_text?('Not available')
        Log.info 'Found no availability on %s' % name
      else
        Log.info 'Oooh-weee, we found availability on %s!' % name
        @timeslot_found = true
        date_buttons[index].click # Select the date
        Log.info 'We have clicked on the date where availability was found.'
        page.should_not have_text('No delivery windows available')
        all('.a-button-normal', :text => 'FREE', :minimum => 1)[0].click
        sleep 1 # I'm not sure how the page responds after clicking the timeslot, so I'm doing this just in case
        find('.a-button-primary', :text => 'Continue').click
        # page.should have_css('#loading-spinner-img') # TO_DO Add another method for a throbber check
        page.should_not have_text('Schedule your order', :wait => 1800) # This can take an incredibly long time with the loading spinner showing up
      end
    end
  rescue RSpec::Expectations::ExpectationNotMetError => e
    Log.error 'Something went wrong finding and selecting an available timeslot. Restarting checkout. Error was %s' % e
    page.save_page # Save some information for troubleshooting if something goes wrong here
    page.save_screenshot
    restart_checkout
  end
end

def retry_if_no_availability
  if @timeslot_found == false
    random_seconds = rand(3..10)
    Log.info 'Bummer, nothing is available. Trying again after waiting for %s seconds.' % random_seconds
    find('.a-button-primary', :text => 'Continue').click # Do this so Capybara can detect change in page refresh
    page.should have_text('Select a window to continue')
    # sleep random_seconds
    visit current_url
    page.should_not have_text('Select a window to continue')
  end
end

def restart_checkout
  visit 'https://www.amazon.com/gp/cart/view.html?ref_=nav_cart'
  wait_for_cart
  goto_time_windows
end

def complete_checkout
  all('.a-button-primary', :text => 'Continue', :minimum => 1)[0].click # I don't remember how many of these there were
  page.should have_text('Place your order', :wait => 1800)
  find('#placeYourOrder', :text => 'Place your order').click
end
