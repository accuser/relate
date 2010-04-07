require 'active_support'
require 'mongoid'
require 'mongoid/cached_document'

module Relate
  module Relations
    extend ActiveSupport::Concern
    
    module ClassMethods
      def ignorable(options = {})
        options.symbolize_keys!
        
        include Relate::Ignorable unless ignorable?
      
        if options.has_key? :before
          before_ignore options[:before]
        end
        
        if options.has_key? :after
          after_ignore options[:after]
        end
      end
      
      private
        def ignorable?
          false
        end
    end
  end
    
  module Ignorable
    extend ActiveSupport::Concern

    included do
      field :ignored, :type => Boolean, :default => false
      field :ignored_at, :type => Time
      field :ignored_by, :type => Mongoid::CachedDocument

      define_model_callbacks :ignore
    end

    module ClassMethods
      def ignored
        criteria.where :ignored => true
      end

      def ignored_by(ignorer)
        ignored.where 'ignored_by._type' => ignorer.class.to_s, 'ignored_by._id' => ignorer.id
      end
      
      private
        def ignorable?
          true
        end
    end

    module InstanceMethods
      def ignore(ignorer)
        unless ignored?
          _run_ignore_callbacks do
            update_attributes :ignored => true, :ignored_at => Time.now, :ignored_by => ignorer
          end
        end
  
        ignored?
      end
    end
  end
end
