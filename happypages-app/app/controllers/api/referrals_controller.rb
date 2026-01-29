module Api
  class ReferralsController < ApplicationController
    include KlaviyoTrackable
    include ShopIdentifiable
    skip_before_action :verify_authenticity_token
    skip_before_action :set_current_shop
    before_action :set_shop_from_header

    def create
      first_name = params[:first_name].presence || params[:firstName].presence
      email = params[:email].presence

      if first_name.blank? || email.blank?
        return render json: {
          success: false,
          error: "Missing required parameters: first_name and email"
        }, status: :unprocessable_entity
      end

      # Find existing referral by email (idempotent) - scope to shop
      scope = Referral.all
      scope = scope.where(shop: Current.shop) if Current.shop
      referral = scope.find_by(email: email)

      if referral
        render json: {
          success: true,
          referral_code: referral.referral_code,
          already_existed: true
        }
      else
        referral = Referral.new(first_name: first_name, email: email, shop: Current.shop)

        if referral.save
          create_discount(referral)
          add_customer_note(referral)
          track_klaviyo(:referral_created, referral)

          render json: {
            success: true,
            referral_code: referral.referral_code,
            already_existed: false
          }, status: :created
        else
          render json: {
            success: false,
            error: referral.errors.full_messages.join(", ")
          }, status: :unprocessable_entity
        end
      end
    end

    private

    def create_discount(referral)
      group = SharedDiscount.current(Current.shop)

      unless group
        Rails.logger.warn "No active discount group, skipping discount creation"
        return
      end

      return unless Current.shop  # Requires shop context
      provider = Current.shop.discount_provider

      generation = group.current_generation

      unless generation
        result = provider.create_generation_discount(
          group: group,
          initial_code: referral.referral_code
        )

        if result[:success]
          generation = result[:generation]
          referral.update(
            discount_generation: generation,
            shopify_discount_id: result[:discount_id],
            uses_shared_discount: true
          )
          Rails.logger.info "Created new generation for #{referral.referral_code}: #{result[:discount_id]}"
        else
          Rails.logger.error "Failed to create generation: #{result[:errors]}"
        end
        return
      end

      result = provider.add_code_to_generation(
        code: referral.referral_code,
        generation: generation
      )

      if result[:success]
        referral.update(
          discount_generation: generation,
          shopify_discount_id: result[:discount_id],
          uses_shared_discount: true
        )
        Rails.logger.info "Added #{referral.referral_code} to generation #{generation.id}"
      else
        Rails.logger.error "Discount creation failed: #{result[:errors]}"
      end
    rescue => e
      Rails.logger.error "Discount creation error: #{e.message}"
    end

    def add_customer_note(referral)
      return unless Current.shop  # Requires shop context

      customer_provider = Current.shop.customer_provider
      customer_id = customer_provider.lookup_by_email(referral.email)

      if customer_id
        referral.update(shopify_customer_id: customer_id)

        result = customer_provider.update_note(
          customer_id: customer_id,
          note: "Referral Code: #{referral.referral_code}"
        )

        if result[:success]
          Rails.logger.info "Added note to customer #{customer_id}: Referral Code: #{referral.referral_code}"
        else
          Rails.logger.error "Failed to add customer note: #{result[:errors]}"
        end
      else
        Rails.logger.warn "No customer found for #{referral.email}, skipping note"
      end
    rescue => e
      Rails.logger.error "Error adding customer note: #{e.message}"
    end
  end
end
