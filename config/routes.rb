War::Application.routes.draw do
  root :to => 'home#index'

  match '/tutorial', :to => 'home#tutorial'
  match '/why_subscribe', :to => 'home#why_subscribe'
  match '/post_subscribe', :to => 'home#post_subscribe'
  match '/donate', :to => 'home#donate'
  match '/thank_you', :to => 'home#thank_you'
  match '/heartbeat', :to => 'home#heartbeat'

  resources :users do
    collection do
      post :login
      get :logout
      get :forgot_password
      post :reset_password
      post :subscribe_to_waiting_list
      get :announce
      post :send_announcement
      post :spreedly_update
      post :trialpay_update
      post :paypal_ipn
      post :paypal_donation_ipn
      get :usernames
    end
  end

  resources :messages, :only => [:index, :new, :create] do
    member do
      get :thread
    end
  end

  resources :global_chat_messages, :only => [:create]

  match '/dynamic_javascripts/:action.js', :to => 'javascripts', :format => :js

  resources :maps do
    member do
      post :clone
    end
  end

  resources :games do
    member do
      post :execute_command
      post :unexecute_last_command
      get :command_history
      post :update_subscription
      post :join
      post :leave
      post :kick_user
      post :start
      get :possible_destinations_from
      post :move_unit
      post :capture_base
      post :buy_unit
      get :possible_targets_from
      post :attack
      post :end_turn
      post :send_reminder
      post :chat
      post :undo
      post :toggle_peace
      post :invite_via_email
      post :invite_via_ec
    end

    collection do
      post :new_player_join
    end
  end

  resources :forums
  resources :topics do
    member do
      post :create_reply
      post :subscribe
      post :unsubscribe
    end
  end

  namespace :admin do
    resources :funnels
    resources :users do
      collection do
        get :switch
        post :login_as
      end
    end
    match 'retention' => 'user_activations#index'
  end

  match 'analytics' => 'admin#analytics'

  match 'help' => 'help#index'
  match 'help/movement' => 'help#movement'
  match 'help/combat' => 'help#combat'
  match 'help/units' => 'help#units'
  match 'help/strategy' => 'help#strategy'
  match 'help/etiquette' => 'help#etiquette'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
