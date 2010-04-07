require 'spec_helper'

describe Relate::Confirmable do
  class Document
    include Relate
  end
  
  class ConfirmableDocument < Document
    confirmable :before => :before_method, :after => :after_method
    
    def before_method
      true
    end
    
    def after_method
    end
  end
  
  class Confirmer
    include Relate
  end
  
  def mock_confirmer(stubs = {})
    @mock_confirmer ||= mock(Confirmer, stubs)
  end
  
  it "should be included with Relate mixin" do
    Document.respond_to?(:confirmable?, true).should be true
  end

  it "should not include the confirmable behavior" do
    Document.send(:confirmable?).should be false
  end
  
  describe "#confirmable" do
    it "should include the confirmable behavior" do
      ConfirmableDocument.send(:confirmable?).should be true
    end
    
    it "should define #confirmed class method" do
      ConfirmableDocument.should respond_to :confirmed
    end
    
    it "should define #confirmed_by class method" do
      ConfirmableDocument.should respond_to :confirmed_by
    end
    
    it "should define #confirmed instance method" do
      ConfirmableDocument.new.should respond_to :confirmed
      ConfirmableDocument.new.should respond_to :confirmed=
    end

    it "should define #confirmed_at instance method" do
      ConfirmableDocument.new.should respond_to :confirmed_at
      ConfirmableDocument.new.should respond_to :confirmed_at=
    end

    it "should define #confirmed_by instance method" do
      ConfirmableDocument.new.should respond_to :confirmed_by
      ConfirmableDocument.new.should respond_to :confirmed_by=
    end
    
    it "should define #confirm callbacks" do
      ConfirmableDocument.should respond_to :before_confirm
      ConfirmableDocument.new.should respond_to :confirm
      ConfirmableDocument.should respond_to :after_confirm
    end
  end
  
  describe "#confirmed" do
    it "should return a criteria for selecting confirmed documents" do
      ConfirmableDocument.confirmed.selector[:confirmed].should be true
    end
  end

  describe "#confirmed_by" do
    before :each do
      mock_confirmer.stub(:class).and_return(Confirmer)
      mock_confirmer.stub(:id).and_return(42)
    end
    
    it "should return a criteria for selecting confirmed documents confirmed by a specific confirmer" do
      selector = ConfirmableDocument.confirmed_by(mock_confirmer).selector
      
      selector[:confirmed].should be true
      selector['confirmed_by._type'].should == 'Confirmer'
      selector['confirmed_by._id'].should be 42 
    end
  end
  
  describe "confirming a document" do
    before :each do
      @document = ConfirmableDocument.create
      
      mock_confirmer.stub(:class).and_return(Confirmer)
      mock_confirmer.stub(:id).and_return(42)
    end
    
    after :each do
      @document.destroy
    end
    
    it "should call the before_confirm callbacks" do
      @document.should_receive(:before_method)
      @document.confirm(mock_confirmer)
    end
    
    it "should call the after_confirm callbacks" do
      @document.should_receive(:after_method)
      @document.confirm(mock_confirmer)
    end
    
    it "should not call the after_confirm callbacks if the callback chain is terminated" do
      @document.should_receive(:before_method).and_return(false)
      @document.should_not_receive(:after_method)
      @document.confirm(mock_confirmer)
    end
    
    it "should mark the document as confirmed" do
      lambda do
        @document.confirm(mock_confirmer)
      end.should change(@document, :confirmed).from(false).to(true)
    end
    
    it "should record the time at which the document was confirmed" do
      time_now = Time.now
      
      Time.stub!(:now).and_return(time_now)
      
      @document.confirm(mock_confirmer)
      @document.confirmed_at.to_s.should == time_now.utc.to_s
    end
    
    it "should record the confirmer of the document" do
      Confirmer.stub!(:find).with(42).and_return(mock_confirmer)
      
      @document.confirm(mock_confirmer)
      @document.confirmed_by.should be mock_confirmer
    end
  end
end
