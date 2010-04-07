require 'active_support'
require 'mongoid'
require 'mongoid/cached_document'

module Relate
  module Relations
    extend ActiveSupport::Concern
    
    module ClassMethods
      def rejectable(options = {})
        options.symbolize_keys!
        
        include Relate::Rejectable unless rejectable?
        
        if options.has_key? :before
          before_reject options[:before]
        end
        
        if options.has_key? :after
          after_reject options[:after]
        end
      end
      
      private
        def rejectable?
          false
        end
    end
  end
    
  module Rejectable
    extend ActiveSupport::Concern

    included do
      field :rejected, :type => Boolean, :default => false
      field :rejected_at, :type => Time
      field :rejected_by, :type => Mongoid::CachedDocument

      define_model_callbacks :reject
    end

    module ClassMethods
      def rejected
        criteria.where :rejected => true
      end

      def rejected_by(rejector)
        rejected.where 'rejected_by._type' => rejector.class.to_s, 'rejected_by._id' => rejector.id
      end
      
      private
        def rejectable?
          true
        end
    end

    module InstanceMethods
      def reject(rejector)
        unless rejected?
          _run_reject_callbacks do
            update_attributes :rejected => true, :rejected_at => Time.now, :rejected_by => rejector
          end
        end
  
        rejected?
      end
    end
  end
end
