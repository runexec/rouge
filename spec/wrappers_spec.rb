# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe [
    Rouge::Macro,
    Rouge::Builtin,
    Rouge::Dequote,
    Rouge::Splice] do
  describe "the constructor" do
    it "should return a new wrapper" do
      described_class.each do |klass|
        klass.new(:abc).should be_an_instance_of klass
      end
    end

    it "should function with the alternate form" do
      described_class.each do |klass|
        klass[:aoeu].should eq klass.new(:aoeu)
      end
    end
  end

  describe "equality" do
    it "should be true for two wrappers with the same underlying object" do
      described_class.each do |klass|
        klass.new(:xyz).should eq klass.new(:xyz)
      end
    end
  end

  describe "the inner getter" do
    it "should return the object passed in" do
      described_class.each do |klass|
        klass.new(:boohoo).inner.should eq :boohoo
        l = lambda {}
        klass.new(l).inner.should eq l
      end
    end
  end

  describe "the Puby pretty-printing" do
    it "should resemble the [] constructor" do
      described_class.each do |klass|
        klass[:hello].inspect.should eq "#{klass.name}[:hello]"
      end
    end
  end
end

# vim: set sw=2 et cc=80:
