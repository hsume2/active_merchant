require 'test_helper'

class RemoteQbmsTest < Test::Unit::TestCase
  def setup
    Base.mode = :test

    @gateway = QbmsGateway.new(fixtures(:qbms))
    @gateway.logger = Logger.new(STDOUT)

    @amount = 100
    @customer_id = "Test-#{Time.now.to_i}" # Ensures a new customer each time
    @credit_card = credit_card('5105105105105100')

    @options = {
    }
  end

  def test_successful_create_customer_credit_card
    assert response = @gateway.create_customer_credit_card(
      :customer_id => @customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response

    assert_nil response.authorization
    assert_equal 'Status OK', response.message
    assert_not_nil response.params['wallet_entry_id']
    assert_equal 'false', response.params['is_duplicate']
  end

  def test_succesful_create_duplicate_customer_credit_card
    assert response = @gateway.create_customer_credit_card(
      :customer_id => @customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response

    assert response = @gateway.create_customer_credit_card(
      :customer_id => @customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response

    assert_equal 'Status OK', response.message
    assert_equal 'true', response.params['is_duplicate']
  end

  def test_successful_create_update_and_get_customer_credit_card
    customer_id = "Test2-#{Time.now.to_i}" # Ensures a new customer each time

    # ==========
    # = Create =
    # ==========
    assert response = @gateway.create_customer_credit_card(
      :customer_id => customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response
    assert_not_nil (wallet_entry_id = response.params['wallet_entry_id'])
    assert_equal 'false', response.params['is_duplicate']

    # ===============
    # = Get Created =
    # ===============
    assert response = @gateway.get_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id
    )
    assert_success response
    assert_equal '94086',            response.params['credit_card_postal_code']
    assert_equal '1133 Sonora Ct.',  response.params['credit_card_address']
    assert_equal '2011',             response.params['expiration_year']
    assert_equal '0',                response.params['status_code']
    assert_equal '09',               response.params['expiration_month']
    assert_equal 'Longbob Longsen',  response.params['name_on_card']
    assert_equal '************5100', response.params['masked_credit_card_number']
    assert_equal 'INFO',             response.params['status_severity']
    assert_equal 'Status OK',        response.params['status_message']

    # ==========
    # = Update =
    # ==========
    assert response = @gateway.update_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id,
      :credit_card => credit_card('5105105105105100', :last_name => 'Shortsen'),
      :credit_card_address => '1135 Sonora Ct.'
    )
    assert_success response

    # ===============
    # = Get Updated =
    # ===============
    assert response = @gateway.get_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id
    )
    assert_success response
    assert_equal '94086',            response.params['credit_card_postal_code']
    assert_equal '1135 Sonora Ct.',  response.params['credit_card_address']
    assert_equal '2011',             response.params['expiration_year']
    assert_equal '0',                response.params['status_code']
    assert_equal '09',               response.params['expiration_month']
    assert_equal 'Longbob Shortsen', response.params['name_on_card']
    assert_equal '************5100', response.params['masked_credit_card_number']
    assert_equal 'INFO',             response.params['status_severity']
    assert_equal 'Status OK',        response.params['status_message']
  end

  def test_successful_create_and_delete_customer_credit_card
    customer_id = "Test2-#{Time.now.to_i}" # Ensures a new customer each time

    # ==========
    # = Create =
    # ==========
    assert response = @gateway.create_customer_credit_card(
      :customer_id => customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response
    assert_not_nil (wallet_entry_id = response.params['wallet_entry_id'])
    assert_equal 'false', response.params['is_duplicate']

    # ==========
    # = Delete =
    # ==========
    assert response = @gateway.delete_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id
    )
    assert_success response

    # ===============
    # = Get Deleted =
    # ===============
    assert response = @gateway.get_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id
    )
    assert_failure response # Can't be found anymore
    assert_equal 'No wallet-related records found in database.', response.message
    assert_equal '10315', response.params['status_code']
  end

  def test_failure_get_customer_credit_card_with_short_wallet
    assert response = @gateway.get_customer_credit_card(
      :customer_id => 'bad',
      :wallet_entry_id => 'worse'
    )
    assert_failure response
    assert_equal 'The string worse in the field WalletEntryID is too short. The minimum length is 24.', response.message
    assert_equal '10307', response.params['status_code']
  end

  def test_failure_get_customer_credit_card_with_missing_wallet
    assert response = @gateway.get_customer_credit_card(
      :customer_id => 'Missing',
      :wallet_entry_id => '102138136671000089895100'
    )
    assert_failure response
    assert_equal 'No wallet-related records found in database.', response.message
    assert_equal '10315', response.params['status_code']
  end

  def test_failure_create_customer_credit_card_with_missing_information
    assert response = @gateway.create_customer_credit_card(
      :customer_id => @customer_id,
      :credit_card => credit_card('ABCD'),
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_failure response
    assert_equal 'The field CreditCardNumber has an invalid format. ', response.message
    assert_equal '10309', response.params['status_code']
  end

  def test_successful_create_and_charge_customer_credit_card
    customer_id = "Test3-#{Time.now.to_i}" # Ensures a new customer each time

    assert response = @gateway.create_customer_credit_card(
      :customer_id => customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response
    assert_not_nil (wallet_entry_id = response.params['wallet_entry_id'])

    assert response = @gateway.charge_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id,
      :amount => @amount
    )
    assert_success response
    assert_equal "Y", response.avs_result['street_match']
    assert_equal "Y", response.avs_result['postal_match']
    assert_equal "X", response.cvv_result['code']
    assert_not_nil response.params['credit_card_trans_id']
  end

  def test_successful_create_and_authorize_and_capture_customer_credit_card
    customer_id = "Test4-#{Time.now.to_i}" # Ensures a new customer each time

    assert response = @gateway.create_customer_credit_card(
      :customer_id => customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response
    assert_not_nil (wallet_entry_id = response.params['wallet_entry_id'])

    assert response = @gateway.authorize_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id,
      :amount => @amount
    )
    assert_success response
    assert (authorization = response.authorization)
    assert_equal "Y", response.avs_result['street_match']
    assert_equal "Y", response.avs_result['postal_match']
    assert_equal "X", response.cvv_result['code']

    assert response = @gateway.authorize_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id,
      :amount => @amount
    )
    assert_success response

    assert response = @gateway.capture(@amount, authorization)
    assert_success response
    assert response.authorization
  end

  def test_successful_create_authorize_and_void_customer_credit_card
    customer_id = "Test5-#{Time.now.to_i}" # Ensures a new customer each time

    assert response = @gateway.create_customer_credit_card(
      :customer_id => customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1133 Sonora Ct.',
      :credit_card_postal_code => '94086'
    )
    assert_success response
    assert_not_nil (wallet_entry_id = response.params['wallet_entry_id'])

    assert response = @gateway.authorize_customer_credit_card(
      :customer_id => customer_id,
      :wallet_entry_id => wallet_entry_id,
      :amount => @amount
    )
    assert_success response
    assert (authorization = response.authorization)

    assert response = @gateway.void(authorization)
    assert_success response
  end
end
