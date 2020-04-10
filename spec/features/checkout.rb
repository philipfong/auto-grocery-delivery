require 'spec_helper'

feature "Check time slots of various online delivery apps" do

  scenario "Instacart" do
    open_instacart
    wait_for_checkout_page
    wait_for_timeslot
    select_delivery_time
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
  while true
    begin
      page.should have_text('No delivery times available')
      puts 'Hi there! Looks like you are on the checkout page. Proceeding with checking delivery time slots...'
    rescue RSpec::Expectations::ExpectationNotMetError
      puts 'I am waiting for you to checkout. Take your time!'
      sleep 60
      retry
    end
  end
end

def wait_for_timeslot
  random_seconds = rand(10..60)
  timeslot_found = false
  while !timeslot_found
    begin
      if page.has_text?('No delivery times available')
        puts 'Waiting for %s seconds and trying again' % random_seconds
        sleep random_seconds
      elsif page.has_text?('CHOOSE')
        puts 'Ohh boy, we found a timeslot'
      else
        puts 'Something else totally went wrong, but we\'ll try again anyway'
      end
    rescue Exception => e
      puts 'Something else really really totally went wrong. Retrying anyway. Error was: %s' % e
      retry
    end
  end
end

def select_delivery_time
  click_button('CHOOSE')
  if page.has_button?('Continue')
    click_button('Continue')
  end
  if page.has_text?('Please re-enter your card number.')
    fail 'Sorry about that. It looks like Instacart needs your card info again. We\'re going to stop here.'
  end
  page.should_not have_css('#Delivery options')
  page.should_not have_css('.ic-loading')
end

def place_order
  click_button('Place order')
end