require 'spec_helper'

describe Relate::Ignorable do
  class Document
    include Relate
  end
  
  class IgnorableDocument < Document
    ignorable :before => :before_method, :after => :after_method
    
    def before_method
      true
    end
    
    def after_method
    end
  end
  
  class Ignorer
    include Relate
  end
  
  def mock_ignorer(stubs = {})
    @mock_ignorer ||= mock(Ignorer, stubs)
  end
  
  it "should be included with Relate mixin" do
    Document.respond_to?(:ignorable?, true).should be true
  end

  it "should not include the ignorable behavior" do
    Document.send(:ignorable?).should be false
  end
  
  describe "#ignorable" do
    it "should include the ignorable behavior" do
      IgnorableDocument.send(:ignorable?).should be true
    end
    
    it "should define #ignored class method" do
      IgnorableDocument.should respond_to :ignored
    end
    
    it "should define #ignored_by class method" do
      IgnorableDocument.should respond_to :ignored_by
    end
    
    it "should define #ignored instance method" do
      IgnorableDocument.new.should respond_to :ignored
      IgnorableDocument.new.should respond_to :ignored=
    end

    it "should define #ignored_at instance method" do
      IgnorableDocument.new.should respond_to :ignored_at
      IgnorableDocument.new.should respond_to :ignored_at=
    end

    it "should define #ignored_by instance method" do
      IgnorableDocument.new.should respond_to :ignored_by
      IgnorableDocument.new.should respond_to :ignored_by=
    end
    
    it "should define #ignore callbacks" do
      IgnorableDocument.should respond_to :before_ignore
      IgnorableDocument.new.should respond_to :ignore
      IgnorableDocument.should respond_to :after_ignore
    end
  end
  
  describe "#ignored" do
    it "should return a criteria for selecting ignored documents" do
      IgnorableDocument.ignored.selector[:ignored].should be true
    end
  end

  describe "#ignored_by" do
    before :each do
      mock_ignorer.stub(:class).and_return(Ignorer)
      mock_ignorer.stub(:id).and_return(42)
    end
    
    it "should return a criteria for selecting ignored documents ignored by a specific ignorer" do
      selector = IgnorableDocument.ignored_by(mock_ignorer).selector
      
      selector[:ignored].should be true
      selector['ignored_by._type'].should == 'Ignorer'
      selector['ignored_by._id'].should be 42 
    end
  end
  
  describe "ignoring a document" do
    before :each do
      @document = IgnorableDocument.create
      
      mock_ignorer.stub(:class).and_return(Ignorer)
      mock_ignorer.stub(:id).and_return(42)
    end
    
    after :each do
      @document.destroy
    end
    
    it "should call the before_ignor callbacks" do
      @document.should_receive(:before_method)
      @document.ignore(mock_ignorer)
    end
    
    it "should call the after_ignor callbacks" do
      @document.should_receive(:after_method)
      @document.ignore(mock_ignorer)
    end
    
    it "should not call the after_ignor callbacks if the callback chain is terminated" do
      @document.should_receive(:before_method).and_return(false)
      @document.should_not_receive(:after_method)
      @document.ignore(mock_ignorer)
    end
    
    it "should mark the document as ignored" do
      lambda do
        @document.ignore(mock_ignorer)
      end.should change(@document, :ignored).from(false).to(true)
    end
    
    it "should record the time at which the document was ignored" do
      time_now = Time.now
      
      Time.stub!(:now).and_return(time_now)
      
      @document.ignore(mock_ignorer)
      @document.ignored_at.to_s.should == time_now.utc.to_s
    end
    
    it "should record the ignorer of the document" do
      Ignorer.stub!(:find).with(42).and_return(mock_ignorer)
      
      @document.ignore(mock_ignorer)
      @document.ignored_by.should be mock_ignorer
    end
  end
end
