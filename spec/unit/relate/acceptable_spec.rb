require 'spec_helper'

describe Relate::Acceptable do
  class Document
    include Relate
  end
  
  class AcceptableDocument < Document
    acceptable :before => :before_method, :after => :after_method
    
    def before_method
      true
    end
    
    def after_method
    end
  end
  
  class Accepter
    include Relate
  end
  
  def mock_accepter(stubs = {})
    @mock_accepter ||= mock(Accepter, stubs)
  end
  
  it "should be included with Relate mixin" do
    Document.respond_to?(:acceptable?, true).should be true
  end

  it "should not include the acceptable behavior" do
    Document.send(:acceptable?).should be false
  end
  
  describe "#acceptable" do
    it "should include the acceptable behavior" do
      AcceptableDocument.send(:acceptable?).should be true
    end
    
    it "should define #accepted class method" do
      AcceptableDocument.should respond_to :accepted
    end
    
    it "should define #accepted_by class method" do
      AcceptableDocument.should respond_to :accepted_by
    end
    
    it "should define #accepted instance method" do
      AcceptableDocument.new.should respond_to :accepted
      AcceptableDocument.new.should respond_to :accepted=
    end

    it "should define #accepted_at instance method" do
      AcceptableDocument.new.should respond_to :accepted_at
      AcceptableDocument.new.should respond_to :accepted_at=
    end

    it "should define #accepted_by instance method" do
      AcceptableDocument.new.should respond_to :accepted_by
      AcceptableDocument.new.should respond_to :accepted_by=
    end
    
    it "should define #accept callbacks" do
      AcceptableDocument.should respond_to :before_accept
      AcceptableDocument.new.should respond_to :accept
      AcceptableDocument.should respond_to :after_accept
    end
  end
  
  describe "#accepted" do
    it "should return a criteria for selecting accepted documents" do
      AcceptableDocument.accepted.selector[:accepted].should be true
    end
  end

  describe "#accepted_by" do
    before :each do
      mock_accepter.stub(:class).and_return(Accepter)
      mock_accepter.stub(:id).and_return(42)
    end
    
    it "should return a criteria for selecting accepted documents accepted by a specific accepter" do
      selector = AcceptableDocument.accepted_by(mock_accepter).selector
      
      selector[:accepted].should be true
      selector['accepted_by._type'].should == 'Accepter'
      selector['accepted_by._id'].should be 42 
    end
  end
  
  describe "accepting a document" do
    before :each do
      @document = AcceptableDocument.create
      
      mock_accepter.stub(:class).and_return(Accepter)
      mock_accepter.stub(:id).and_return(42)
    end
    
    after :each do
      @document.destroy
    end
    
    it "should call the before_accept callbacks" do
      @document.should_receive(:before_method)
      @document.accept(mock_accepter)
    end
    
    it "should call the after_accept callbacks" do
      @document.should_receive(:after_method)
      @document.accept(mock_accepter)
    end
    
    it "should not call the after_accept callbacks if the callback chain is terminated" do
      @document.should_receive(:before_method).and_return(false)
      @document.should_not_receive(:after_method)
      @document.accept(mock_accepter)
    end
    
    it "should mark the document as accepted" do
      lambda do
        @document.accept(mock_accepter)
      end.should change(@document, :accepted).from(false).to(true)
    end
    
    it "should record the time at which the document was accepted" do
      time_now = Time.now
      
      Time.stub!(:now).and_return(time_now)
      
      @document.accept(mock_accepter)
      @document.accepted_at.to_s.should == time_now.utc.to_s
    end
    
    it "should record the accepter of the document" do
      Accepter.stub!(:find).with(42).and_return(mock_accepter)
      
      @document.accept(mock_accepter)
      @document.accepted_by.should be mock_accepter
    end
  end
end
