require 'spec_helper'

feature "Check time slots for Whole Foods" do

  before(:all) do
    if ENV["PW"] == nil
      Log.info 'Password was not passed to the script, which is totally fine. We will have to fail if Amazon signs us out.'
    end
    if ENV["SAMEDAY"] == nil
      Log.info 'You have not opted into same-day delivery, which means we will look for the first available date Amazon offers.'
    else
      Log.info 'You have selected same-day delivery. We will look for a delivery window for TODAY for 4 hours. If we can\'t find something in that time, then we will look for something across all days.'
    end
    if ENV["FULLCART"] == nil
      Log.info 'We will complete checkout even if some things fall out of your cart, as Amazon does on occasion.'
    else
      Log.info 'You have decided that all items in your cart are essential. We will stop checkout if some things fall out of your cart.'
    end
    @script_start = Time.now
    @today = @script_start.strftime("%Y%m%d")
  end

  scenario "Amazon Whole Foods" do
    open_amazon
    wait_for_cart
    begin
      goto_time_windows
      get_timeslot
      complete_checkout
    rescue Exception => e
      Log.error 'Something wrong happened during checkout. We will start over. Error was: %s' % e
      revisit_cart
      retry
    end
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
      visit 'https://www.amazon.com/cart/localmarket'
      sleep 1 # Wait a very brief moment, since we want the list of items to fully load and the number of items is unknown
      cart_found = true
      Log.info 'Found cart. Looking for grocery list now.'
      grocery_list = all('.sc-list-item-content', :minimum => 1)
      @num_items_in_cart = grocery_list.size
      puts '=====Grocery List Below====='
      grocery_list.each do |item|
        puts item.find('.sc-product-title').text
      end
      puts '=====Grocery List Ends Here====='
      Log.info 'Hi there! Looks like you are at your Amazon cart. We found %s unique items. Proceeding with checkout...' % @num_items_in_cart
    rescue Exception
      Log.info 'I am waiting for you to get to your cart. Take your time!'
      sleep 30
      retry
    end
  end
end

def revisit_cart
  begin
    visit 'https://www.amazon.com/gp/cart/view.html?ref_=nav_cart'
    page.should have_css('.a-button-primary', :text => 'Checkout Whole Foods Market Cart')
  rescue Exception => e
    Log.error 'Could not visit cart and will retry. Error was %s' % e
    retry
  end
end

def goto_time_windows
  begin
    find('.a-button-primary', :text => 'Checkout Whole Foods Market Cart').click
    page.should have_text('Before you checkout')
    all('.a-button-primary', :text => 'Continue', :count => 2)[0].click
    reconfirm_password
    page.should have_text('Substitution preferences')
    all('.a-button-primary', :text => 'Continue', :count => 2)[0].click
  rescue Exception
    fail 'I ran into some problems moving across pages. I\'ll start over.'
  end
end

def reconfirm_password
  begin
    if page.has_css?('#ap_password', :wait => 2)
      if ENV["PW"].nil?
        raise NoPasswordError, 'Password was requested but there is nothing we can do about it. We need to stop here.'
      else
        find('#ap_password').set(ENV["PW"])
        find('#signInSubmit').click
      end
    end
    if page.has_text?('Your password is incorrect')
      raise InvalidPasswordError, 'Password was entered but was incorrect. We need to stop here.'
    end
  rescue => e
    Log.error e
  rescue Exception
    page.save_page
    fail 'Password was requested but something went wrong getting past this point. Restarting checkout.'
  end
end

def get_timeslot
  @timeslot_found = false
  while !@timeslot_found
    begin
      page.should have_text('Schedule your order', :wait => 30) # This page can show up so embarassingly slow for Amazon. Pls.
    rescue Exception
      fail 'Maybe got kicked out to some other page? Going to try to checkout for you again.'
    end
    select_day
    select_time if @timeslot_found
    refresh_if_no_availability
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
        if ENV["SAMEDAY"] && name != @today && Time.now - @script_start < 14400
          Log.info 'Even though we found availability, we\'re going to keep looking.'
          break
        end
        @timeslot_found = true
        date_buttons[index].click # Select the date
        Log.info 'We have clicked on the date where availability was found.'
        page.should_not have_text('No delivery windows available')
        break # Don't go on to check other dates since we found the one we want
      end
    end
  rescue Exception => e
    page.save_page # Save some information for troubleshooting if something goes wrong here
    fail 'Something went wrong selecting a day after availability was likely found. Error was %s' % e
  end
end

def select_time
  begin
    all('.a-button-normal', :text => 'FREE', :minimum => 1)[0].click # Click on first timeslot available
    sleep 1 # I hate this with a passion, but things seem to work better with this until I can figure a way without it
    find('.a-button-primary', :text => 'Continue').click
    Log.info 'We have selected a timeslot and am attempting to leave the timeslot page now.'
    page.save_page # Get a screenshot of available time windows that were open
    page.should_not have_text('Schedule your order', :wait => 120) # Use this expectation to ensure we have left the page. Wait a maximum of two minutes.
  rescue Exception => e
    page.save_page
    fail 'Something went wrong selecting a free timeslot. Error was %s' % e
  end
end

def refresh_if_no_availability
  if @timeslot_found == false
    begin
      random_seconds = rand(1..5)
      Log.info 'Bummer, nothing is available. Trying again after waiting for %s seconds.' % random_seconds
      find('.a-button-primary', :text => 'Continue').click # Do this so Capybara can detect change in page refresh
      page.should have_text('Select a window to continue')
      sleep random_seconds
      visit current_url
      page.should_not have_text('Select a window to continue')
    rescue Exception => e
      fail 'Something went wrong trying to refresh the page, but we\'ll try to continue anyway.'
    end
  end
end

def complete_checkout
  Log.info 'Attempting to complete checkout now.'
  begin
    using_wait_time 60 do # This becomes a critical path in our workflow, so extend the maximum wait time before we consider it a failure. Obviously if elements show up in a shorter time, fantastic.
      page.should have_text('Select a payment method')
      Log.info 'Reached payment page'
      find('#continue-top').click
      page.should have_text('Review your Whole Foods Market order')
      Log.info 'Reached final checkout page'
      num_items_on_checkout = all('.asin-title', :minimum => 1).size
      Log.info 'We found %s unique items on the final checkout page.' % num_items_on_checkout
      if ENV["FULLCART"] && @num_items_in_cart != num_items_on_checkout
        page.save_page
        Log.error 'Something went missing from your cart. We are going to stop here.'
      else
        find('#placeYourOrder').click
        page.should have_text('Thank you, your Whole Foods Market order has been placed')
        Log.info 'Checkout completed! We are so done!'
      end
    end
  rescue Exception => e
    page.save_page
    fail 'Amazon just took a dump on our order and likely kicked us all the way out. Gonna have to start all over. Error was: %s' % e
  end
end
