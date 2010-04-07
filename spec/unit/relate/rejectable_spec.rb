require 'spec_helper'

describe Relate::Rejectable do
  class Document
    include Relate
  end
  
  class RejectableDocument < Document
    rejectable :before => :before_method, :after => :after_method
    
    def before_method
      true
    end
    
    def after_method
    end
  end
  
  class Rejecter
    include Relate
  end
  
  def mock_rejector(stubs = {})
    @mock_rejector ||= mock(Rejecter, stubs)
  end
  
  it "should be included with Relate mixin" do
    Document.respond_to?(:rejectable?, true).should be true
  end

  it "should not include the rejectable behavior" do
    Document.send(:rejectable?).should be false
  end
  
  describe "#rejectable" do
    it "should include the rejectable behavior" do
      RejectableDocument.send(:rejectable?).should be true
    end
    
    it "should define #rejected class method" do
      RejectableDocument.should respond_to :rejected
    end
    
    it "should define #rejected_by class method" do
      RejectableDocument.should respond_to :rejected_by
    end
    
    it "should define #rejected instance method" do
      RejectableDocument.new.should respond_to :rejected
      RejectableDocument.new.should respond_to :rejected=
    end

    it "should define #rejected_at instance method" do
      RejectableDocument.new.should respond_to :rejected_at
      RejectableDocument.new.should respond_to :rejected_at=
    end

    it "should define #rejected_by instance method" do
      RejectableDocument.new.should respond_to :rejected_by
      RejectableDocument.new.should respond_to :rejected_by=
    end
    
    it "should define #reject callbacks" do
      RejectableDocument.should respond_to :before_reject
      RejectableDocument.new.should respond_to :reject
      RejectableDocument.should respond_to :after_reject
    end
  end
  
  describe "#rejected" do
    it "should return a criteria for selecting rejected documents" do
      RejectableDocument.rejected.selector[:rejected].should be true
    end
  end

  describe "#rejected_by" do
    before :each do
      mock_rejector.stub(:class).and_return(Rejecter)
      mock_rejector.stub(:id).and_return(42)
    end
    
    it "should return a criteria for selecting rejected documents rejected by a specific rejector" do
      selector = RejectableDocument.rejected_by(mock_rejector).selector
      
      selector[:rejected].should be true
      selector['rejected_by._type'].should == 'Rejecter'
      selector['rejected_by._id'].should be 42 
    end
  end
  
  describe "rejecting a document" do
    before :each do
      @document = RejectableDocument.create
      
      mock_rejector.stub(:class).and_return(Rejecter)
      mock_rejector.stub(:id).and_return(42)
    end
    
    after :each do
      @document.destroy
    end
    
    it "should call the before_reject callbacks" do
      @document.should_receive(:before_method)
      @document.reject(mock_rejector)
    end
    
    it "should call the after_reject callbacks" do
      @document.should_receive(:after_method)
      @document.reject(mock_rejector)
    end
    
    it "should not call the after_reject callbacks if the callback chain is terminated" do
      @document.should_receive(:before_method).and_return(false)
      @document.should_not_receive(:after_method)
      @document.reject(mock_rejector)
    end
    
    it "should mark the document as rejected" do
      lambda do
        @document.reject(mock_rejector)
      end.should change(@document, :rejected).from(false).to(true)
    end
    
    it "should record the time at which the document was rejected" do
      time_now = Time.now
      
      Time.stub!(:now).and_return(time_now)
      
      @document.reject(mock_rejector)
      @document.rejected_at.to_s.should == time_now.utc.to_s
    end
    
    it "should record the rejector of the document" do
      Rejecter.stub!(:find).with(42).and_return(mock_rejector)
      
      @document.reject(mock_rejector)
      @document.rejected_by.should be mock_rejector
    end
  end
end
