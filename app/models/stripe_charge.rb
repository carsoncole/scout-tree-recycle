class StripeCharge
  def initialize(event)
    @stripe_event = event.data.object
  end

  def process
    checkout_session if @stripe_event.object == "checkout.session"
    charge if @stripe_event.object == "charge"
    payment_intent if @stripe_event.object == "payment_intent"
  end

  private

  def present?(value)
    value.present? rescue false
  end

  def card_from(object)
    payment_method_details = object.respond_to?(:payment_method_details) ? object.payment_method_details : nil
    return nil unless payment_method_details

    if payment_method_details.respond_to?(:card) && present?(payment_method_details.card)
      payment_method_details.card
    elsif payment_method_details.respond_to?(:card_present) && present?(payment_method_details.card_present)
      payment_method_details.card_present
    else
      nil
    end
  end

  def merge_card(updates, card)
    return unless card

    updates[:last4] = card.last4 if present?(card.last4) rescue nil
    updates[:card_last4] = card.last4 if present?(card.last4) rescue nil
    updates[:brand] = card.brand if present?(card.brand) rescue nil
    updates[:card_brand] = card.brand if present?(card.brand) rescue nil
    updates[:funding] = card.funding if present?(card.funding) rescue nil
    updates[:card_funding] = card.funding if present?(card.funding) rescue nil
    updates[:country] = card.country if present?(card.country) rescue nil
    updates[:card_country] = card.country if present?(card.country) rescue nil
    updates[:network] = card.network if present?(card.network) rescue nil
    updates[:card_network] = card.network if present?(card.network) rescue nil
    updates[:exp_month] = card.exp_month if present?(card.exp_month) rescue nil
    updates[:exp_year] = card.exp_year if present?(card.exp_year) rescue nil
  end

  def merge_direct_stripe_fields(updates, object)
    return unless object

    {
      last4: :last4,
      card_last4: :last4,
      brand: :brand,
      card_brand: :brand,
      funding: :funding,
      card_funding: :funding,
      country: :country,
      card_country: :country,
      network: :network,
      card_network: :network,
      exp_month: :exp_month,
      exp_year: :exp_year
    }.each do |target, source|
      value = object.respond_to?(source) ? object.public_send(source) : nil
      updates[target] = value if present?(value) rescue nil
    end

    # General Stripe fields that may be provided directly on the object.
    {
      receipt_url: :receipt_url,
      receipt_number: :receipt_number,
      receipt_no: :receipt_number,
      receipt_id: :receipt_number,
      currency: :currency,
      description: :description,
      phone: :phone,
      payment_method_id: :payment_method,
      payment_method: :payment_method
    }.each do |target, source|
      value = object.respond_to?(source) ? object.public_send(source) : nil
      updates[target] = value if present?(value) rescue nil
    end

    # Also support nested payment_method_details on the object itself.
    merge_card(updates, card_from(object)) rescue nil
  end

  def address_updates(updates, address, prefix: "billing")
    return unless address

    updates[:"#{prefix}_address_line1"] = address.line1 if present?(address.line1) rescue nil
    updates[:"#{prefix}_address_line2"] = address.line2 if present?(address.line2) rescue nil
    updates[:"#{prefix}_city"] = address.city if present?(address.city) rescue nil
    updates[:"#{prefix}_state"] = address.state if present?(address.state) rescue nil
    updates[:"#{prefix}_postal_code"] = address.postal_code if present?(address.postal_code) rescue nil
    updates[:"#{prefix}_country"] = address.country if present?(address.country) rescue nil
  end

  def charge
    charge_obj = @stripe_event
    stripe_payment_intent_id = charge_obj.respond_to?(:payment_intent) ? charge_obj.payment_intent : nil
    donation = nil
    donation = Donation.find_by_stripe_payment_intent_id(stripe_payment_intent_id) if stripe_payment_intent_id.present?
    donation ||= Donation.find_by_stripe_charge_id(charge_obj.id) if charge_obj.respond_to?(:id) && charge_obj.id.present?
    donation ||= Donation.find_by_charge_id(charge_obj.id) if charge_obj.respond_to?(:id) && charge_obj.id.present?
    donation ||= Donation.find_or_create_by(stripe_payment_intent_id: stripe_payment_intent_id) if stripe_payment_intent_id.present?

    return unless donation

    amount = if charge_obj.respond_to?(:amount) && charge_obj.amount.present?
               charge_obj.amount == 0 ? 0 : charge_obj.amount / 100.0
    else
               donation.amount
    end
    amount_refunded = if charge_obj.respond_to?(:amount_refunded) && charge_obj.amount_refunded.present?
                        charge_obj.amount_refunded == 0 ? 0 : charge_obj.amount_refunded / 100.0
    else
                        0
    end
    refunded = charge_obj.respond_to?(:refunded) ? charge_obj.refunded : false

    updates = {}
    updates[:amount] = refunded ? amount - amount_refunded : amount
    updates[:status] = "refunded" if refunded
    updates[:receipt_url] = charge_obj.receipt_url if present?(charge_obj.receipt_url) rescue nil
    updates[:receipt_number] = charge_obj.receipt_number if present?(charge_obj.receipt_number) rescue nil
    updates[:currency] = charge_obj.currency if present?(charge_obj.currency) rescue nil
    updates[:description] = charge_obj.description if present?(charge_obj.description) rescue nil
    updates[:stripe_charge_id] = charge_obj.id if present?(charge_obj.id) rescue nil
    updates[:charge_id] = charge_obj.id if present?(charge_obj.id) rescue nil
    updates[:payment_method_id] = charge_obj.payment_method if present?(charge_obj.payment_method) rescue nil
    updates[:payment_method] = charge_obj.payment_method if charge_obj.payment_method.is_a?(String) rescue nil

    billing_details = charge_obj.respond_to?(:billing_details) ? charge_obj.billing_details : nil
    if billing_details
      updates[:customer_name] = billing_details.name if present?(billing_details.name) rescue nil
      updates[:email] = billing_details.email if present?(billing_details.email) rescue nil
      updates[:phone] = billing_details.phone if present?(billing_details.phone) rescue nil
      updates[:billing_name] = billing_details.name if present?(billing_details.name) rescue nil
      updates[:billing_email] = billing_details.email if present?(billing_details.email) rescue nil
      updates[:billing_phone] = billing_details.phone if present?(billing_details.phone) rescue nil
      address_updates(updates, billing_details.address) if billing_details.respond_to?(:address)
    end

    merge_card(updates, card_from(charge_obj))
    merge_direct_stripe_fields(updates, charge_obj)

    payment_method_details = charge_obj.respond_to?(:payment_method_details) ? charge_obj.payment_method_details : nil
    if payment_method_details && payment_method_details.respond_to?(:type)
      updates[:card_type] = payment_method_details.type if present?(payment_method_details.type) rescue nil
    end

    donation.update(updates.compact)
  end

  def checkout_session
    reservation = Reservation.where(id: @stripe_event.client_reference_id).first
    amount = @stripe_event.amount_total == 0 ? 0 : @stripe_event.amount_total / 100.0 rescue @stripe_event.amount_total
    donation = Donation.find_or_create_by(stripe_payment_intent_id: @stripe_event.payment_intent)
    updates = {
      checkout_session_id: @stripe_event.id,
      checkout_session_status: @stripe_event.status,
      checkout_session_customer_email: @stripe_event.customer_email,
      reservation_id: reservation&.id,
      amount: amount,
      status: @stripe_event.status,
      payment_status: @stripe_event.payment_status,
      email: @stripe_event.customer_details&.email,
      customer_name: @stripe_event.customer_details&.name,
      stripe_payment_intent_id: @stripe_event.payment_intent
    }
    updates[:currency] = @stripe_event.currency if present?(@stripe_event.currency) rescue nil

    customer_details = @stripe_event.customer_details
    if customer_details
      updates[:phone] = customer_details.phone if present?(customer_details.phone) rescue nil
      address_updates(updates, customer_details.address) rescue nil
    end

    shipping_details = @stripe_event.shipping_details rescue nil
    if shipping_details
      # store shipping address in billing_*? keep separate not needed
    end

    # Extract card details when Stripe provides them (expanded payment intent/charge).
    if @stripe_event.respond_to?(:charges) && @stripe_event.charges.respond_to?(:data) && @stripe_event.charges.data.present?
      charge_obj = @stripe_event.charges.data.first
      updates[:receipt_url] = charge_obj.receipt_url if present?(charge_obj.receipt_url) rescue nil
      updates[:receipt_number] = charge_obj.receipt_number if present?(charge_obj.receipt_number) rescue nil
      updates[:stripe_charge_id] = charge_obj.id if present?(charge_obj.id) rescue nil
      updates[:charge_id] = charge_obj.id if present?(charge_obj.id) rescue nil
      updates[:payment_method_id] = charge_obj.payment_method if present?(charge_obj.payment_method) rescue nil
      merge_card(updates, card_from(charge_obj))
    end

    if @stripe_event.respond_to?(:payment_method_details)
      merge_card(updates, card_from(@stripe_event))
    end
    merge_direct_stripe_fields(updates, @stripe_event)

    donation.update(updates.compact)

    # Confirm the reservation once payment succeeds so the confirmation
    # email and routing kick off from the webhook rather than a page
    # load. Only reservations still in the donation step are advanced,
    # so cancelled or already confirmed reservations are left alone.
    if reservation && @stripe_event.payment_status == "paid" && reservation.donation?
      reservation.routing!
    end
  end

  def payment_intent
    payment_intent_obj = @stripe_event
    charge_obj = nil
    if payment_intent_obj.respond_to?(:charges) && payment_intent_obj.charges.respond_to?(:data)
      charge_obj = payment_intent_obj.charges.data&.first
    end

    pi_id = payment_intent_obj.id
    donation = Donation.find_or_create_by(stripe_payment_intent_id: pi_id)

    amount = if payment_intent_obj.respond_to?(:amount) && payment_intent_obj.amount.present?
               payment_intent_obj.amount == 0 ? 0 : payment_intent_obj.amount / 100.0
    else
               donation.amount
    end

    updates = {}
    updates[:payment_intent_id] = pi_id
    updates[:stripe_payment_intent_id] = pi_id
    updates[:amount] = amount if payment_intent_obj.respond_to?(:amount) && payment_intent_obj.amount.present?
    updates[:payment_status] = payment_intent_obj.status if present?(payment_intent_obj.status) rescue nil
    updates[:description] = payment_intent_obj.description if present?(payment_intent_obj.description) rescue nil
    updates[:currency] = payment_intent_obj.currency if present?(payment_intent_obj.currency) rescue nil
    updates[:email] = payment_intent_obj.receipt_email if present?(payment_intent_obj.receipt_email) rescue nil

    if charge_obj
      updates[:receipt_url] = charge_obj.receipt_url if present?(charge_obj.receipt_url) rescue nil
      updates[:receipt_number] = charge_obj.receipt_number if present?(charge_obj.receipt_number) rescue nil
      updates[:stripe_charge_id] = charge_obj.id if present?(charge_obj.id) rescue nil
      updates[:charge_id] = charge_obj.id if present?(charge_obj.id) rescue nil
      updates[:payment_method_id] = charge_obj.payment_method if present?(charge_obj.payment_method) rescue nil
      updates[:payment_method] = charge_obj.payment_method if charge_obj.payment_method.is_a?(String) rescue nil

      billing_details = charge_obj.respond_to?(:billing_details) ? charge_obj.billing_details : nil
      if billing_details
        updates[:customer_name] = billing_details.name if present?(billing_details.name) rescue nil
        updates[:email] = billing_details.email if present?(billing_details.email) rescue nil
        updates[:phone] = billing_details.phone if present?(billing_details.phone) rescue nil
        updates[:billing_name] = billing_details.name if present?(billing_details.name) rescue nil
        updates[:billing_email] = billing_details.email if present?(billing_details.email) rescue nil
        updates[:billing_phone] = billing_details.phone if present?(billing_details.phone) rescue nil
        address_updates(updates, billing_details.address) if billing_details.respond_to?(:address)
      end

      merge_card(updates, card_from(charge_obj))
      merge_direct_stripe_fields(updates, charge_obj)

      payment_method_details = charge_obj.respond_to?(:payment_method_details) ? charge_obj.payment_method_details : nil
      if payment_method_details && payment_method_details.respond_to?(:type)
        updates[:card_type] = payment_method_details.type if present?(payment_method_details.type) rescue nil
      end
    end

    if payment_intent_obj.respond_to?(:payment_method_details)
      merge_card(updates, card_from(payment_intent_obj))
    end
    merge_direct_stripe_fields(updates, payment_intent_obj)

    donation.update(updates.compact)

    # only if paid via phone app (kept for backwards compatibility)
    if @stripe_event&.charges&.data[0]&.payment_method_details&.respond_to?(:card_present)
      # no-op: details already recorded above
    end
  end
end
