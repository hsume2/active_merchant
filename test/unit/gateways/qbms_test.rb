require 'test_helper'

class QbmsTest < Test::Unit::TestCase
  def setup
    @gateway = QbmsGateway.new(:login => 'login', :password => 'password', :test_mode => true)
    @customer_id = '3187'
    @credit_card = credit_card
  end

  def test_successful_create_customer_credit_card
    @gateway.expects(:ssl_post).returns(successful_create_customer_credit_card)

    assert response = @gateway.create_customer_credit_card(
      :customer_id => @customer_id,
      :credit_card => @credit_card,
      :credit_card_address => '1234 Fake Street',
      :credit_card_postal_code => '94043'
    )
    assert_success response

    assert_nil response.authorization
    assert_equal 'Status OK', response.message
    assert_equal '101123456789012345671111', response.params['wallet_entry_id']
    assert_equal 'false', response.params['is_duplicate']
    assert response.test?
  end

  def test_successful_update_customer_credit_card
    @gateway.expects(:ssl_post).returns(successful_update_customer_credit_card)

    assert response = @gateway.update_customer_credit_card(
      :customer_id => @customer_id,
      :wallet_entry_id => '102138136671000089895100',
      :credit_card => credit_card,
      :credit_card_address => '1234 Fake Street',
      :credit_card_postal_code => '94043'
    )
    assert_success response

    assert_equal 'Status OK', response.message
  end

  def test_successful_delete_customer_credit_card
    @gateway.expects(:ssl_post).returns(successful_delete_customer_credit_card)

    assert response = @gateway.delete_customer_credit_card(
      :customer_id => @customer_id,
      :wallet_entry_id => '102138136671000089895100'
    )
    assert_success response

    assert_equal 'Status OK', response.message
  end

  def test_successful_get_customer_credit_card
    @gateway.expects(:ssl_post).returns(successful_get_customer_credit_card)

    assert response = @gateway.get_customer_credit_card(
      :customer_id => @customer_id,
      :wallet_entry_id => '102138136671000089895100'
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
  end

  def test_successful_charge_customer_credit_card
    @gateway.expects(:ssl_post).returns(successful_charge_customer_credit_card)

    assert response = @gateway.charge_customer_credit_card(
      :customer_id => @customer_id,
      :wallet_entry_id => '102138136671000089895100',
      :amount => 100
    )
    assert_success response
    assert_equal 'YY1000045039', response.authorization
    assert_equal "Y", response.avs_result['street_match']
		assert_equal "Y", response.avs_result['postal_match']
		assert_equal "X", response.cvv_result['code']
  end

  def test_successful_authorize_customer_credit_card
    @gateway.expects(:ssl_post).returns(successful_authorize_customer_credit_card)

    assert response = @gateway.authorize_customer_credit_card(
      :customer_id => @customer_id,
      :wallet_entry_id => '102138136671000089895100',
      :amount => 100
    )
    assert_success response
    assert_equal 'YY1000045060', response.authorization
    assert_equal "Y", response.avs_result['street_match']
		assert_equal "Y", response.avs_result['postal_match']
		assert_equal "X", response.cvv_result['code']
  end

  def test_successful_capture_customer_credit_card
    @gateway.expects(:ssl_post).returns(successful_capture_customer_credit_card)

    assert response = @gateway.capture(@amount, '1234')
    assert_success response
    assert_equal 'YY1000045083', response.authorization
  end

  def test_successful_customer_credit_card_txn_void
    @gateway.expects(:ssl_post).returns(successful_customer_credit_card_txn_void)

    assert response = @gateway.void('1234')
    assert_success response
  end

  private

  def successful_create_customer_credit_card
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.0//EN" "http://merchantaccount.quickbooks.co.../qbmsxml40.dtd">
<QBMSXML>
     <QBMSXMLMsgsRs>
          <CustomerCreditCardWalletAddRs statusCode = "0" statusMessage = "Status OK" statusSeverity = "INFO" >
               <WalletEntryID>101123456789012345671111</WalletEntryID>
               <IsDuplicate>false</IsDuplicate>
           </CustomerCreditCardWalletAddRs>
      </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end

  def successful_update_customer_credit_card
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.1//EN" "http://merchantaccount.ptc.quickbooks.com/dtds/qbmsxml41.dtd">
<QBMSXML>
 <SignonMsgsRs>
  <SignonDesktopRs statusCode="0" statusSeverity="INFO">
   <ServerDateTime>2010-12-22T19:21:45</ServerDateTime>
   <SessionTicket>V1-140-mx_IXwvQ0G8CMa4T2XePNQ:182650529</SessionTicket>
  </SignonDesktopRs>
 </SignonMsgsRs>
 <QBMSXMLMsgsRs>
  <CustomerCreditCardWalletModRs statusCode="0" statusMessage="Status OK" statusSeverity="INFO"/>
 </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end

  def successful_delete_customer_credit_card
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.1//EN" "http://merchantaccount.ptc.quickbooks.com/dtds/qbmsxml41.dtd">
<QBMSXML>
 <SignonMsgsRs>
  <SignonDesktopRs statusCode="0" statusSeverity="INFO">
   <ServerDateTime>2010-12-22T20:17:43</ServerDateTime>
   <SessionTicket>V1-140-whlEzuEAVIc7hDKetciNsQ:182650529</SessionTicket>
  </SignonDesktopRs>
 </SignonMsgsRs>
 <QBMSXMLMsgsRs>
  <CustomerCreditCardWalletDelRs statusCode="0" statusMessage="Status OK" statusSeverity="INFO"/>
 </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end

  def successful_get_customer_credit_card
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.1//EN" "http://merchantaccount.ptc.quickbooks.com/dtds/qbmsxml41.dtd">
<QBMSXML>
 <SignonMsgsRs>
  <SignonDesktopRs statusCode="0" statusSeverity="INFO">
   <ServerDateTime>2010-12-22T19:02:28</ServerDateTime>
   <SessionTicket>V1-140-MoDAMwNkIeKtJdUS7Lv0_w:182650529</SessionTicket>
  </SignonDesktopRs>
 </SignonMsgsRs>
 <QBMSXMLMsgsRs>
  <CustomerWalletQueryRs statusCode="0" statusMessage="Status OK" statusSeverity="INFO">
   <MaskedCreditCardNumber>************5100</MaskedCreditCardNumber>
   <ExpirationMonth>09</ExpirationMonth>
   <ExpirationYear>2011</ExpirationYear>
   <NameOnCard>Longbob Longsen</NameOnCard>
   <CreditCardAddress>1133 Sonora Ct.</CreditCardAddress>
   <CreditCardPostalCode>94086</CreditCardPostalCode>
  </CustomerWalletQueryRs>
 </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end

  def successful_charge_customer_credit_card
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.1//EN" "http://merchantaccount.ptc.quickbooks.com/dtds/qbmsxml41.dtd">
<QBMSXML>
 <SignonMsgsRs>
  <SignonDesktopRs statusCode="0" statusSeverity="INFO">
   <ServerDateTime>2010-12-22T21:10:16</ServerDateTime>
   <SessionTicket>V1-140-85DcJAKIx8G8vDih4GepCA:182650529</SessionTicket>
  </SignonDesktopRs>
 </SignonMsgsRs>
 <QBMSXMLMsgsRs>
  <CustomerCreditCardWalletChargeRs statusCode="0" statusMessage="Status OK" statusSeverity="INFO">
   <CreditCardTransID>YY1000045039</CreditCardTransID>
   <AuthorizationCode>140032</AuthorizationCode>
   <AVSStreet>Pass</AVSStreet>
   <AVSZip>Pass</AVSZip>
   <CardSecurityCodeMatch>NotAvailable</CardSecurityCodeMatch>
   <MerchantAccountNumber>5247711076653800</MerchantAccountNumber>
   <ReconBatchID>420101222 1Q13075247711076653800AUTO04</ReconBatchID>
   <PaymentGroupingCode>4</PaymentGroupingCode>
   <PaymentStatus>Completed</PaymentStatus>
   <TxnAuthorizationTime>2010-12-22T21:07:23</TxnAuthorizationTime>
   <TxnAuthorizationStamp>1293052043</TxnAuthorizationStamp>
   <ClientTransID>q0081f3d</ClientTransID>
  </CustomerCreditCardWalletChargeRs>
 </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end

  def successful_authorize_customer_credit_card
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.1//EN" "http://merchantaccount.ptc.quickbooks.com/dtds/qbmsxml41.dtd">
<QBMSXML>
 <SignonMsgsRs>
  <SignonDesktopRs statusCode="0" statusSeverity="INFO">
   <ServerDateTime>2010-12-22T21:42:01</ServerDateTime>
   <SessionTicket>V1-140-vdRcv_NMcLpvIsuGBcBRcw:182650529</SessionTicket>
  </SignonDesktopRs>
 </SignonMsgsRs>
 <QBMSXMLMsgsRs>
  <CustomerCreditCardWalletAuthRs statusCode="0" statusMessage="Status OK" statusSeverity="INFO">
   <CreditCardTransID>YY1000045060</CreditCardTransID>
   <AuthorizationCode>447279</AuthorizationCode>
   <AVSStreet>Pass</AVSStreet>
   <AVSZip>Pass</AVSZip>
   <CardSecurityCodeMatch>NotAvailable</CardSecurityCodeMatch>
  </CustomerCreditCardWalletAuthRs>
 </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end

  def successful_capture_customer_credit_card
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.1//EN" "http://merchantaccount.ptc.quickbooks.com/dtds/qbmsxml41.dtd">
<QBMSXML>
 <SignonMsgsRs>
  <SignonDesktopRs statusCode="0" statusSeverity="INFO">
   <ServerDateTime>2010-12-22T22:10:54</ServerDateTime>
   <SessionTicket>V1-140-9W8y1RAu0A601PBdl7OzGw:182650529</SessionTicket>
  </SignonDesktopRs>
 </SignonMsgsRs>
 <QBMSXMLMsgsRs>
  <CustomerCreditCardCaptureRs statusCode="0" statusMessage="Status OK" statusSeverity="INFO">
   <CreditCardTransID>YY1000045083</CreditCardTransID>
   <AuthorizationCode>563168</AuthorizationCode>
   <MerchantAccountNumber>5247711076653800</MerchantAccountNumber>
   <ReconBatchID>420101222 1Q14105247711076653800AUTO04</ReconBatchID>
   <PaymentGroupingCode>4</PaymentGroupingCode>
   <PaymentStatus>Completed</PaymentStatus>
   <TxnAuthorizationTime>2010-12-22T22:10:54</TxnAuthorizationTime>
   <TxnAuthorizationStamp>1293055854</TxnAuthorizationStamp>
   <ClientTransID>q0081f61</ClientTransID>
  </CustomerCreditCardCaptureRs>
 </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end

  def successful_customer_credit_card_txn_void
    <<-RESPONSE
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE QBMSXML PUBLIC "-//INTUIT//DTD QBMSXML QBMS 4.1//EN" "http://merchantaccount.ptc.quickbooks.com/dtds/qbmsxml41.dtd">
<QBMSXML>
 <SignonMsgsRs>
  <SignonDesktopRs statusCode="0" statusSeverity="INFO">
   <ServerDateTime>2010-12-23T00:39:43</ServerDateTime>
   <SessionTicket>V1-140-Cicwg0j07yrwilM0CqjMdQ:182650529</SessionTicket>
  </SignonDesktopRs>
 </SignonMsgsRs>
 <QBMSXMLMsgsRs>
  <CustomerCreditCardTxnVoidRs statusCode="0" statusMessage="Status OK" statusSeverity="INFO">
   <CreditCardTransID>YY1000045152</CreditCardTransID>
   <ClientTransID>q0081f9c</ClientTransID>
  </CustomerCreditCardTxnVoidRs>
 </QBMSXMLMsgsRs>
</QBMSXML>

    RESPONSE
  end
end