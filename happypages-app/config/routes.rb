Rails.application.routes.draw do
  # API endpoints for checkout extension
  namespace :api do
    resources :referrals, only: [:create]
    resource :config, only: [:show]
    resources :analytics, only: [:create]
  end

  # Main referral page - takes firstName and email from URL params
  # Shop-specific URL (preferred for multi-tenant)
  get ":shop_slug/refer", to: "referrals#show", as: :shop_referral
  # Legacy URL (falls back to session or first shop)
  get "refer", to: "referrals#show"

  # Webhook endpoint for Shopify order notifications
  post "webhooks/orders", to: "webhooks#orders"

  # Shopify compliance webhooks (mandatory for protected customer data)
  # All compliance topics route to same endpoint, dispatched by X-Shopify-Topic header
  post "webhooks/compliance", to: "webhooks#compliance"

  # Webhook endpoint for Awtomic subscription events
  post "webhooks/awtomic", to: "awtomic_webhooks#handle"

  # Session management
  get "login", to: "sessions#new"
  delete "logout", to: "sessions#destroy"

  # Shopify OAuth
  get "auth/shopify", to: "shopify_auth#initiate"
  get "auth/shopify/callback", to: "shopify_auth#callback"

  # Admin endpoints
  post "admin/register_webhook", to: "admin#register_webhook"

  namespace :admin do
    # Dashboard as landing page
    get "/", to: "dashboard#index", as: :dashboard

    # Campaigns page (list discount groups)
    resources :campaigns, only: [:index], controller: "discount_groups"

    # Discount group CRUD
    resources :discount_groups, only: [:new, :create, :edit, :update] do
      member do
        post :activate
        post :schedule_override
        post :cancel_override
      end
    end

    # Analytics
    resources :analytics, only: [:index]

    # Thank-You Card editor
    resource :thank_you_card, only: [:edit, :update], controller: "thank_you_card"

    # Referral Page editor
    resource :referral_page, only: [:edit, :update], controller: "referral_page"

    # Integrations
    resource :integrations, only: [:edit, :update, :destroy], controller: "integrations"

    # Settings (shop slug)
    resource :settings, only: [:edit, :update], controller: "settings"

    # Legacy config route — redirect to dashboard
    resource :config, only: [:edit, :update]
  end

  # Embedded app landing page (loaded in Shopify admin iframe)
  get "embedded", to: "embedded#show"

  # Public pages
  get "privacy", to: "pages#privacy"

  # Health check for Railway/load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # Root redirects to refer (will show error without params)
  root "referrals#show"
end
