require 'spec_helper'

feature "Check time slots for Instacart" do

  before(:all) do
    if ENV["CARD"] == nil || ENV["EXP"] == nil || ENV["CVV"] == nil
      Log.info 'Still in beta: No card info was passed on execution, so let\'s cross our fingers on checkout.'
      @card_info_found = false
    end
  end

  scenario "Instacart" do
    open_instacart
    wait_for_checkout_page
    complete_checkout
  end

end

def open_instacart
  begin
    visit 'https://www.instacart.com/'
    page.should have_text 'Groceries delivered in as little as 1 hour'
  rescue Exception => e
    Log.error 'You might be having problems getting this running in the first place, or Instacart changed their homepage content. Please reach out to me on Github for help.'
    fail 'Could not load Instacart page'
  end
end

def wait_for_checkout_page
  checkout_found = false
  while !checkout_found
    begin
      page.should have_text('No delivery times available')
      checkout_found = true
      Log.info 'Hi there! Looks like you are on the checkout page. Proceeding with checking delivery time slots...'
    rescue Exception
      Log.info 'I am waiting for you to checkout. Take your time!'
      sleep 60
      retry
    end
  end
end

def complete_checkout
  confirm_address
  wait_for_timeslot
  select_delivery_time
  set_delivery_instructions
  reconfirm_payment
  confirm_contact_sharing
  place_order
end

def refresh_checkout
  visit current_url
  page.should have_text('Choose delivery time')
  wait_for_instacart_throbber
end

def restart_checkout
  visit 'https://www.instacart.com'
  click_button('Cart')
  click_link('Go to Checkout')
  page.should have_text('Choose delivery time')
  wait_for_instacart_throbber
  complete_checkout
end

def confirm_address
  if page.has_text?('Add delivery address', :wait => 2)
    find('textarea[placeholder="Instructions for delivery (optional)"]').set('Please leave at doorstep.')
    click_button('Confirm')
    wait_for_instacart_throbber
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
      elsif page.has_text?('CHOOSE', :wait => 2)
        timeslot_found = true
        Log.info 'Oooh-weee, we found a timeslot'
        page.save_page
      elsif page.has_text?('maintenance', :wait => 2)
        Log.info 'It looks like Instacart is under maintenance. Attempting to get to checkout page myself.'
        restart_checkout
      elsif page.has_css?('.error-module', :wait => 2)
        Log.error 'It looks like the website is having problems. Attempting to display error message and get to checkout page myself.'
        error_message = find('.error-module').text
        Log.error error_message
        restart_checkout
      else
        Log.error 'I can\'t seem to find what I\'m looking for anymore, are you sure you\'re on the checkout page? I\'ll try to get there myself.'
        restart_checkout
      end
    rescue Exception => e
      Log.error 'Something else went wrong. Retrying anyway. Error was: %s' % e
      retry
    end
  end
end

def wait_for_instacart_throbber
  begin
    page.should have_css('.ic-loading')
    page.should_not have_css('.ic-loading')
  rescue Exception # Rescue all, IME checks on spinners can produce a stale element exception from webdriver
    Log.error 'Something wrong happened checking for Instacart\'s spinny animations. This is not important enough to do something about, so let\s do nothing.'
  end
end

def select_delivery_time
  timeslot_selected = false
  begin
    while !timeslot_selected
      find('[id*="Delivery"]').all('input[name="delivery_option"]', :minimum => 1)[0].click # Find and click first available
      wait_for_instacart_throbber
      if page.has_css?('[id*="Delivery"]') # Here we probably got the "Demand is higher than normal message" and have to try again
        next
      else
        page.should_not have_css('[id*="Delivery"]')
        page.should_not have_css('.ic-loading')
        timeslot_selected = true
        Log.info 'Timeslot selected'
      end
    end
  rescue Exception => e
    Log.error 'Something went wrong after we saw timeslots available %s' % e
    fail 'Failing because choosing the timeslot didn\'t work out.'
  end
end

def set_delivery_instructions
  if page.has_button?('Continue') # There is a step that can come up that asks for a note to the delivery driver
    Log.info 'Delivery instructions were requested, we are just dismissing this one.'
    click_button('Continue')
  end
end

def reconfirm_payment
  if page.has_text?('Please re-enter your card number.') # This also comes up on occasion, mostly for those who have never placed an Instacart order
    Log.info 'Payment info was requested'
    page.save_page # I don't know what this looks like, so this will help further development
    if @card_info_found == false
      Log.error 'We aren\'t able to complete checkout due to Instacart asking to reconfirm card details.'
      fail 'Sorry about that. It looks like Instacart needs your card info again. We\'re going to stop here.'
    else
      Log.info 'Adding card info'
      # TO_DO Input card details into checkout
    end
  end
end

def confirm_contact_sharing
  if page.has_text?('Share my contact information and order details with')
    Log.info 'Contact sharing requested'
    click_button('Allow')
    page.should have_text('Opted In')
  else
    Log.info 'Contact sharing was not asked for during this checkout.'
  end
end

def place_order
  Log.info 'About to place order!'
  begin
    page.should have_css('button', :text => 'Place order')
    all('button', :text => 'Place order', :minimum => 1)[0].click
  rescue Exception => e
    Log.error 'Something went wrong once the place order button was found'
    Log.error e
    fail 'Failing because order could not be placed'
  end
end
