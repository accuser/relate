require 'active_support'
require 'mongoid'
require 'mongoid/cached_document'

module Relate
  module Relations
    extend ActiveSupport::Concern
    
    module ClassMethods
      def acceptable(options = {})
        include Relate::Acceptable unless acceptable?
        
        if options.has_key? :before
          before_accept options[:before]
        end
        
        if options.has_key? :after
          after_accept options[:after]
        end
      end
      
      private
        def acceptable?
          false
        end
    end
  end
  
  module Acceptable
    extend ActiveSupport::Concern

    included do
      field :accepted, :type => Boolean, :default => false
      field :accepted_at, :type => Time
      field :accepted_by, :type => Mongoid::CachedDocument

      define_model_callbacks :accept
    end

    module ClassMethods
      def accepted
        criteria.where :accepted => true
      end

      def accepted_by(accepter)
        accepted.where 'accepted_by._type' => accepter.class.to_s, 'accepted_by._id' => accepter.id
      end
      
      private
        def acceptable?
          true
        end
    end

    module InstanceMethods
      def accept(accepter)
        unless accepted?
          _run_accept_callbacks do
            update_attributes :accepted => true, :accepted_at => Time.now, :accepted_by => accepter
          end
        end
  
        accepted?
      end
    end
  end
end
