module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class QbmsGateway < Gateway
      class_inheritable_accessor :test_url, :live_url, :logger

      self.test_url = 'https://merchantaccount.ptc.quickbooks.com/j/AppGateway'
      self.live_url = 'https://merchantaccount.quickbooks.com/j/AppGateway'

      API_VERSION = '4.1'

      QBMS_ACTIONS = {
        :customer_credit_card_wallet_add => 'CustomerCreditCardWalletAdd',
        :customer_credit_card_wallet_mod => 'CustomerCreditCardWalletMod',
        :customer_credit_card_wallet_del => 'CustomerCreditCardWalletDel',
        :customer_credit_card_wallet_charge => 'CustomerCreditCardWalletCharge',
        :customer_credit_card_wallet_auth => 'CustomerCreditCardWalletAuth',
        :customer_credit_card_capture => 'CustomerCreditCardCapture',
        :customer_credit_card_txn_void => 'CustomerCreditCardTxnVoid',
        :customer_wallet_query => 'CustomerWalletQuery'
      }

      # Creates a new QbmsGateway
      #
      # The gateway requires that a valid login and password be passed
      # in the +options+ hash.
      #
      # ==== Options
      #
      # * <tt>:login</tt> -- The QBMS SDK ApplicationLogin (REQUIRED)
      # * <tt>:password</tt> -- The QBMS SDK ConnectionTicket. (REQUIRED)
      # * <tt>:test</tt> -- +true+ or +false+. If true, perform transactions against the test server.
      #   Otherwise, perform transactions against the production server.
      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
        super
      end

      def create_customer_credit_card(options)
        requires!(options, :customer_id)
        requires!(options, :credit_card)
        requires!(options, :credit_card_address)
        requires!(options, :credit_card_postal_code)

        xml = build_request(:customer_credit_card_wallet_add, options)
        commit(:customer_credit_card_wallet_add, xml)
      end

      def update_customer_credit_card(options)
        requires!(options, :wallet_entry_id)
        requires!(options, :customer_id)
        requires!(options, :credit_card)

        xml = build_request(:customer_credit_card_wallet_mod, options)
        commit(:customer_credit_card_wallet_mod, xml)
      end

      def get_customer_credit_card(options)
        requires!(options, :wallet_entry_id)
        requires!(options, :customer_id)

        xml = build_request(:customer_wallet_query, options)
        commit(:customer_wallet_query, xml)
      end

      def delete_customer_credit_card(options)
        requires!(options, :wallet_entry_id)
        requires!(options, :customer_id)

        xml = build_request(:customer_credit_card_wallet_del, options)
        commit(:customer_credit_card_wallet_del, xml)
      end

      def charge_customer_credit_card(options)
        requires!(options, :wallet_entry_id)
        requires!(options, :customer_id)
        requires!(options, :amount)

        xml = build_request(:customer_credit_card_wallet_charge, options)
        commit(:customer_credit_card_wallet_charge, xml)
      end

      def authorize_customer_credit_card(options)
        requires!(options, :wallet_entry_id)
        requires!(options, :customer_id)
        requires!(options, :amount)

        xml = build_request(:customer_credit_card_wallet_auth, options)
        commit(:customer_credit_card_wallet_auth, xml)
      end

      def capture(money, authorization, options = {})
        options.update(:amount => money, :credit_card_trans_id => authorization)
        requires!(options, :credit_card_trans_id)

        xml = build_request(:customer_credit_card_capture, options)
        commit(:customer_credit_card_capture, xml)
      end

      def void(authorization)
        options.update(:credit_card_trans_id => authorization)
        requires!(options, :credit_card_trans_id)

        xml = build_request(:customer_credit_card_txn_void, options)
        commit(:customer_credit_card_txn_void, xml)
      end

      private

      def build_request(action, options)
        xml = Builder::XmlMarkup.new(:indent => 2)

        create_qbmsxml_msgs_rq(xml,options) {
          xml.tag!("#{QBMS_ACTIONS[action]}Rq") do
            send("build_#{action}_request", xml, options)
          end
        }

        xml.target!
      end

      # Populate the header and QBMSXML for a QBMSXMLMsgsRq Request
      def create_qbmsxml_msgs_rq(xml, options)
        create_xml_header(xml, options)

        xml.tag!('QBMSXML') do
          add_signon_msgs_rq(xml, options)
          xml.tag!('QBMSXMLMsgsRq') do
            yield
          end
        end
      end

      # Create the XML header for a QBMSXML Request
      def create_xml_header(xml,options)
        xml.instruct!(:xml, :version => '1.0', :encoding => 'utf-8')
        xml.instruct!(:qbmsxml, :version => API_VERSION)
      end

      def add_signon_msgs_rq(xml, options)
        xml.tag!('SignonMsgsRq') do
          xml.tag!('SignonDesktopRq') do
            xml.tag!('ClientDateTime', Time.now.utc)
            xml.tag!('ApplicationLogin', @options[:login])
            xml.tag!('ConnectionTicket', @options[:password])
          end
        end
      end

      def build_customer_credit_card_wallet_add_request(xml, options)
        xml.tag!('CustomerID', options[:customer_id])
        xml.tag!('CreditCardNumber', options[:credit_card].number)
        xml.tag!('ExpirationMonth', options[:credit_card].month)
        xml.tag!('ExpirationYear', options[:credit_card].year)
        xml.tag!('NameOnCard', options[:credit_card].name)
        xml.tag!('CreditCardAddress', options[:credit_card_address])
        xml.tag!('CreditCardPostalCode', options[:credit_card_postal_code])
      end

      def add_wallet_entry_id_and_customer_id(xml, options)
        xml.tag!('WalletEntryID', options[:wallet_entry_id])
        xml.tag!('CustomerID', options[:customer_id])
      end

      def build_customer_credit_card_wallet_mod_request(xml, options)
        add_wallet_entry_id_and_customer_id(xml, options)
        xml.tag!('ExpirationMonth', options[:credit_card].month)
        xml.tag!('ExpirationYear', options[:credit_card].year)
        xml.tag!('NameOnCard', options[:credit_card].name)
        xml.tag!('CreditCardAddress', options[:credit_card_address]) if options[:credit_card_address]
        xml.tag!('CreditCardPostalCode', options[:credit_card_postal_code]) if options[:credit_card_postal_code]
      end

      alias_method :build_customer_credit_card_wallet_del_request, :add_wallet_entry_id_and_customer_id
      alias_method :build_customer_wallet_query_request, :add_wallet_entry_id_and_customer_id

      def build_customer_credit_card_wallet_charge_request(xml, options)
        xml.tag!('TransRequestID', generate_unique_id)
        add_wallet_entry_id_and_customer_id(xml, options)
        xml.tag!('Amount', Money.parse(options[:amount]).to_s)
      end

      alias_method :build_customer_credit_card_wallet_auth_request, :build_customer_credit_card_wallet_charge_request

      def build_customer_credit_card_capture_request(xml, options)
        xml.tag!('TransRequestID', generate_unique_id)
        xml.tag!('CreditCardTransID', options[:credit_card_trans_id])
        xml.tag!('Amount', Money.parse(options[:amount]).to_s) if !options[:amount].blank?
      end

      def build_customer_credit_card_txn_void_request(xml, options)
        xml.tag!('TransRequestID', generate_unique_id)
        xml.tag!('CreditCardTransID', options[:credit_card_trans_id])
      end

      def parse_avs_result(response_params)
        attrs = {}

        if avs_street = response_params['avs_street']
          attrs[:street_match] = avs_street == 'Pass' ? 'Y' : 'N'
        end

        if avs_zip = response_params['avs_zip']
          attrs[:postal_match] = avs_zip == 'Pass' ? 'Y' : 'N'
        end

        attrs
      end

      def parse_cvv_result(response_params)
        if card_security_code_match = response_params['card_security_code_match']
          case card_security_code_match
          when 'Y'
            'M'
          when 'N'
            'N'
          else
            'X'
          end
        end
      end

      def commit(action, request)
        url = test? ? test_url : live_url
        xml = ssl_post(url, request, "Content-Type" => "application/x-qbmsxml")

        response_params = parse(action, xml)

        message = response_params['status_message']
        success = response_params['status_code'] == '0'

        response = Response.new(success, message, response_params,
          :test => test?,
          :avs_result => parse_avs_result(response_params),
          :cvv_result => parse_cvv_result(response_params),
          :authorization => response_params['credit_card_trans_id']
        )

        response
      end

      def parse(action, xml)
        xml = REXML::Document.new(xml)

        root = REXML::XPath.first(xml, "//QBMSXML/QBMSXMLMsgsRs/#{QBMS_ACTIONS[action]}Rs")
        if root
          response = parse_element(root)
          response ||= {}

          root.attributes.each_attribute { |attribute|
            response[attribute.expanded_name.underscore] = attribute.value
          }
        end

        response
      end

      def parse_element(node)
        if node.has_elements?
          response = {}

          node.elements.each{ |e|
            key = e.name.underscore
            value = parse_element(e)
            if response.has_key?(key)
              if response[key].is_a?(Array)
                response[key].push(value)
              else
                response[key] = [response[key], value]
              end
            else
              response[key] = parse_element(e)
            end
          }
        else
          response = node.text
        end

        response
      end
    end
  end
end