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
    rescue *EXCEPTIONS
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
  rescue *EXCEPTIONS
    Log.error 'I ran into some problems moving across pages. I\'ll start over.'
    restart_checkout
  end
end

def get_timeslot
  @timeslot_found = false
  while !@timeslot_found
    begin
      page.should have_text('Schedule your order', :wait => 30) # This page can show up so embarassingly slow for Amazon. Pls.
    rescue *EXCEPTIONS
      Log.info 'Maybe got kicked out to some other page? Going to try to checkout for you again.'
      restart_checkout
      next
    end
    select_day
    select_time if @timeslot_found
    retry_if_no_availability
  end
end

def select_day
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
      end
    end
  rescue *EXCEPTIONS => e
    Log.error 'Something went wrong selecting a day where availability was found. Error was %s' % e
    page.save_page # Save some information for troubleshooting if something goes wrong here
    restart_checkout
  end
end

def select_time
  begin
    all('.a-button-normal', :text => 'FREE', :minimum => 1)[0].click # Click on first timeslot available
    sleep 1 # I hate this with a passion, but things seem to work better with this until I can figure a way without it
    find('.a-button-primary', :text => 'Continue').click
    Log.info 'We have selected a timeslot and am attempting to leave the timeslot page now.'
    page.should_not have_text('Schedule your order', :wait => 120) # Use this expectation to ensure we have left the page. Wait a maximum of two minutes.
  rescue *EXCEPTIONS => e
    Log.error 'Something went wrong selecting a free timeslot. Error was %s' % e
    page.save_page
    restart_checkout
  end
end

def retry_if_no_availability
  if @timeslot_found == false
    begin
      random_seconds = rand(1..5)
      Log.info 'Bummer, nothing is available. Trying again after waiting for %s seconds.' % random_seconds
      find('.a-button-primary', :text => 'Continue').click # Do this so Capybara can detect change in page refresh
      page.should have_text('Select a window to continue')
      sleep random_seconds
      visit current_url
      page.should_not have_text('Select a window to continue')
    rescue *EXCEPTIONS => e
      Log.error 'Something went wrong trying to refresh the page, but we\'ll try to continue anyway.'
    end
  end
end

def restart_checkout
  Log.info 'Restarting checkout. Something must\'ve went wrong just before this.'
  visit 'https://www.amazon.com/gp/cart/view.html?ref_=nav_cart'
  wait_for_cart
  goto_time_windows
end

def complete_checkout
  Log.info 'Attempting to complete checkout now.'
  using_wait_time 60 do # This becomes a critical path in our workflow, so extend the maximum wait time before we consider it a failure. Obviously if elements show up in a shorter time, fantastic.
    page.should have_text('Select a payment method')
    find('#continue-top').click
    page.should have_text('Review your Whole Foods Market order')
    find('#placeYourOrder').click
    if page.has_text?('Thank you, your Whole Foods Market order has been placed')
      Log.info 'Checkout completed! We are so done!'
    elsif page.has_text?('No delivery windows available')
      Log.info 'Amazon just took a dump on our order and kicked us all the way out. Gonna have to start all over.'
      restart_checkout
    else
      Log.error 'I didn\'t see the confirmation page or get kicked out to the timeslot delivery page. Just gonna fail then.'
      page.save_page
      fail 'We got like 99 percent there but something messed up. Please send html captures to Github.'
    end
  end
end
