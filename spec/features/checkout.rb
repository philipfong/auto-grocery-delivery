require 'spec_helper'

feature "Check time slots of various online delivery apps" do

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
    puts 'Something went fatally wrong. Please reach out on Github.'
  end
end

def wait_for_checkout_page
  checkout_found = false
  while !checkout_found
    begin
      page.should have_text('No delivery times available')
      checkout_found = true
      puts 'Hi there! Looks like you are on the checkout page. Proceeding with checking delivery time slots...'
    rescue RSpec::Expectations::ExpectationNotMetError
      puts 'I am waiting for you to checkout. Take your time!'
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
        puts 'Waiting for %s seconds and trying again' % random_seconds
        sleep random_seconds
        visit current_url
        wait_for_instacart_throbber
      elsif page.has_text?('CHOOSE')
        timeslot_found = true
        puts 'Oooh-weee, we found a timeslot'
        # TO_DO Maybe send an alert. The script can be unpredictable after this.
      else
        puts 'I can\'t seem to find what I\'m looking for anymore, are you sure you\'re on the checkout page?'
      end
    rescue Exception => e
      puts 'Something else went wrong. Retrying anyway. Error was: %s' % e
      retry
    end
  end
end

def select_delivery_time
  begin
    page.should have_css('button', :text => 'CHOOSE', :wait => 10) # Extend wait period, on occasion the button takes a while to become active
    click_button('CHOOSE')
  rescue Exception => e
    puts 'Something went wrong once the choose timeslot button was found %s' % e
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
  puts 'About to place order at %s' % Time.now
  begin
    page.should have_css('button', :text => 'Place order', :wait => 10)
    click_button('Place order')
  rescue Exception => e
    puts 'Something went wrong once the place order button was found'
  end
end

def wait_for_instacart_throbber
  begin
    using_wait_time 10 do # These spinners can take a little while to show up and disappear, but is important to check so that we know the page is done loading
      page.should have_css('.ic-loading')
      page.should_not have_css('.ic-loading')
    end
  rescue Exception => e
    puts 'Something wrong happened checking for Instacart\'s spinny animations. This is not important enough to do something about, so let\s do nothing.'
  end
end