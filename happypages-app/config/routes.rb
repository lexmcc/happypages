Rails.application.routes.draw do
  # Web analytics collection
  post "collect", to: "analytics/collect#create"
  get "s.js", to: "analytics/script#show"

  # API endpoints for checkout extension
  namespace :api do
    resources :referrals, only: [ :create, :show ]
    resource :config, only: [ :show ]
    resources :analytics, only: [ :create ]
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
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Invite flow
  get "invite/:token", to: "invites#show", as: :invite
  patch "invite/:token", to: "invites#update"

  # Shopify OAuth
  get "auth/shopify", to: "shopify_auth#initiate"
  get "auth/shopify/callback", to: "shopify_auth#callback"

  # Admin endpoints
  post "admin/register_webhook", to: "admin#register_webhook"

  namespace :admin do
    # Dashboard as landing page
    get "/", to: "dashboard#index", as: :dashboard

    # Campaigns page (list discount groups)
    resources :campaigns, only: [ :index ], controller: "discount_groups"

    # Discount group CRUD
    resources :discount_groups, only: [ :new, :create, :edit, :update ] do
      member do
        post :activate
        post :schedule_override
        post :cancel_override
      end
    end

    # Analytics
    resources :analytics, only: [ :index ]

    # Thank-You Card editor
    resource :thank_you_card, only: [ :edit, :update ], controller: "thank_you_card"

    # Referral Page editor
    resource :referral_page, only: [ :edit, :update ], controller: "referral_page"

    # Media library
    resources :media_assets, only: [ :index, :create, :destroy ]

    # Integrations
    resource :integrations, only: [ :edit, :update, :destroy ], controller: "integrations"

    # AI image generation
    resources :image_generations, only: [ :create ] do
      collection do
        get :status
      end
    end

    # Customer import
    resources :customer_imports, only: [ :create ] do
      collection do
        get :status
      end
    end

    # Feature preview pages (locked features)
    resources :features, only: [ :show ], param: :feature_name

    # Settings (shop slug)
    resource :settings, only: [ :edit, :update ], controller: "settings"

    # Legacy config route — redirect to dashboard
    resource :config, only: [ :edit, :update ]
  end

  # Embedded app landing page (loaded in Shopify admin iframe)
  get "embedded", to: "embedded#show"
  post "embedded/authenticate", to: "embedded#authenticate"

  # Public pages
  get "privacy", to: "pages#privacy"

  # Super admin dashboard
  namespace :superadmin do
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout
    root to: "shops#index"
    resources :shops, only: [ :index, :show, :create ] do
      member do
        get :manage
        post :suspend
        post :reactivate
        post :rescrape_brand
      end
      resources :shop_features, only: [ :create, :update, :destroy ]
      resources :shop_users, only: [ :create ] do
        member do
          post :send_invite
        end
      end
      post :impersonate, on: :member
    end
    resource :impersonation, only: [ :destroy ], controller: "impersonations"
    resources :scene_assets, except: [ :show ]
    resources :prompt_templates, except: [ :show ] do
      member do
        post :test_generate
      end
    end
  end

  # Health check for Railway/load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # Root redirects to refer (will show error without params)
  root "referrals#show"
end
