require 'spec_helper'

feature "Check time slots of various online delivery apps" do

  before(:all) do
    if ENV["CARD"] == nil || ENV["EXP"] == nil || ENV["CVV"] == nil
      Log.info 'Still in beta: No card info was passed on execution, so let\'s cross our fingers on checkout.'
    end
  end

  scenario "Instacart" do
    open_instacart
    wait_for_checkout_page
    wait_for_timeslot
    select_delivery_time
    place_order
  end

end

def open_instacart
  begin
    visit 'https://www.instacart.com/'
    page.should have_text 'Groceries delivered in as little as 1 hour'
  rescue Exception => e
    Log.error 'Something went fatally wrong. Please reach out on Github.'
  end
end

def goto_checkout
  visit 'https://www.instacart.com'
  click_button('Cart')
  click_link('Go to Checkout')
  page.should have_text('Choose delivery time', :wait => 10)
  wait_for_instacart_throbber
end

def refresh_checkout
  visit current_url
  page.should have_text('Choose delivery time', :wait => 10)
  wait_for_instacart_throbber
end

def wait_for_checkout_page
  checkout_found = false
  while !checkout_found
    begin
      page.should have_text('No delivery times available')
      checkout_found = true
      Log.info 'Hi there! Looks like you are on the checkout page. Proceeding with checking delivery time slots...'
    rescue RSpec::Expectations::ExpectationNotMetError
      Log.info 'I am waiting for you to checkout. Take your time!'
      sleep 60
      retry
    end
  end
end

def wait_for_timeslot
  timeslot_found = false
  while !timeslot_found
    random_seconds = rand(10..60)
    begin
      if page.has_text?('No delivery times available')
        Log.info 'Waiting for %s seconds and trying again' % random_seconds
        sleep random_seconds
        refresh_checkout
      elsif page.has_text?('CHOOSE')
        timeslot_found = true
        Log.info 'Oooh-weee, we found a timeslot'
      elsif page.has_text?('maintenance')
        Log.info 'It looks like Instacart is under maintenance. Attempting to get to checkout page myself.'
        goto_checkout
      elsif page.has_css?('.error-module')
        Log.error 'It looks like the website is having problems. Attempting to display error message and get to checkout page myself.'
        error_message = find('.error-module').text
        Log.error error_message
        goto_checkout
      else
        Log.error 'I can\'t seem to find what I\'m looking for anymore, are you sure you\'re on the checkout page? I\'ll try to get there myself.'
        goto_checkout
      end
    rescue Exception => e
      Log.error 'Something else went wrong. Retrying anyway. Error was: %s' % e
      retry
    end
  end
end

def wait_for_instacart_throbber
  begin
    using_wait_time 10 do # These spinners can take a little while to show up and disappear, but is important to check so that we know the page is done loading
      page.should have_css('.ic-loading')
      page.should_not have_css('.ic-loading')
    end
  rescue Exception => e
    Log.error 'Something wrong happened checking for Instacart\'s spinny animations. This is not important enough to do something about, so let\s do nothing.'
  end
end

def select_delivery_time
  begin
    page.should have_css('button', :text => 'CHOOSE', :wait => 10) # Extend wait period, on occasion the button takes a while to become active
    click_button('CHOOSE')
  rescue Exception => e
    Log.error 'Something went wrong once the choose timeslot button was found %s' % e
  end
  using_wait_time 10 do
    page.should_not have_css('#Delivery options')
    page.should_not have_css('.ic-loading')
  end
  if page.has_button?('Continue') # There is a step that can come up that asks for a note to the delivery driver
    click_button('Continue')
  end
  if page.has_text?('Please re-enter your card number.') # This also comes up on occasion, mostly for those who have never placed an Instacart order
    fail 'Sorry about that. It looks like Instacart needs your card info again. We\'re going to stop here.'
  end
end

def place_order
  Log.info 'About to place order!'
  begin
    page.should have_css('button', :text => 'Place order', :wait => 10)
    click_button('Place order')
  rescue Exception => e
    Log.error 'Something went wrong once the place order button was found'
  end
end
