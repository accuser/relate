require 'active_support'
require 'mongoid'
require 'mongoid/cached_document'

module Relate
  module Relations
    extend ActiveSupport::Concern
    
    module ClassMethods
      def confirmable(options = {})
        options.symbolize_keys!
        
        include Relate::Confirmable unless confirmable?
        
        if options.has_key? :before
          before_confirm options[:before]
        end
        
        if options.has_key? :after
          after_confirm options[:after]
        end
      end
      
      private
        def confirmable?
          false
        end
    end
  end
    
  module Confirmable
    extend ActiveSupport::Concern

    included do
      field :confirmed, :type => Boolean, :default => false
      field :confirmed_at, :type => Time
      field :confirmed_by, :type => Mongoid::CachedDocument

      define_model_callbacks :confirm
    end

    module ClassMethods
      def confirmed
        criteria.where :confirmed => true
      end

      def confirmed_by(confirmer)
        confirmed.where 'confirmed_by._type' => confirmer.class.to_s, 'confirmed_by._id' => confirmer.id
      end
      
      private
        def confirmable?
          true
        end
    end

    module InstanceMethods
      def confirm(confirmer)
        unless confirmed?
          _run_confirm_callbacks do
            update_attributes :confirmed => true, :confirmed_at => Time.now, :confirmed_by => confirmer
          end
        end
  
        confirmed?
      end
    end
  end
end
