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

    # Specs (AI-powered specification interviews)
    resources :specs, only: [:index, :new, :create, :show] do
      member do
        post :message
        post :complete
        get :export
        post :new_version
        post :create_handoff
        get :board_cards
        patch :update_card
        post :create_card
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

  # Slack integration webhooks
  namespace :slack_integration do
    post "events", to: "events#create"
    post "actions", to: "actions#create"
    post "commands", to: "commands#create"
  end

  # Slack OAuth (client portal context)
  get "specs/slack/install", to: "slack_integration/oauth#install", as: :slack_install
  get "specs/slack/callback", to: "slack_integration/oauth#callback", as: :slack_callback

  # Specs guest access (no login required)
  get "specs/join/:token", to: "specs/guests#join", as: :specs_guest_join
  get "specs/session/:token", to: "specs/guests#show", as: :specs_guest_session
  post "specs/session/:token/message", to: "specs/guests#message", as: :specs_guest_message

  # Specs client portal (authenticated)
  get "specs/login", to: "specs/sessions#new", as: :specs_login
  post "specs/login", to: "specs/sessions#create"
  delete "specs/logout", to: "specs/sessions#destroy", as: :specs_logout
  get "specs/invite/:token", to: "specs/invites#show", as: :specs_invite
  patch "specs/invite/:token", to: "specs/invites#update"
  get "specs/dashboard", to: "specs/dashboard#index", as: :specs_dashboard
  get "specs/projects/new", to: "specs/projects#new", as: :new_specs_project
  post "specs/projects", to: "specs/projects#create", as: :specs_projects
  get "specs/projects/:id", to: "specs/projects#show", as: :specs_project
  post "specs/projects/:id/message", to: "specs/projects#message", as: :specs_project_message
  get "specs/projects/:id/export", to: "specs/projects#export", as: :specs_project_export
  get "specs/projects/:id/board_cards", to: "specs/projects#board_cards", as: :specs_project_board_cards

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
    resources :organisations, only: [ :index, :create ] do
      member do
        get :manage
      end
      resources :specs_clients, only: [ :create ], controller: "specs_clients" do
        member do
          post :send_invite
        end
      end
    end
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
