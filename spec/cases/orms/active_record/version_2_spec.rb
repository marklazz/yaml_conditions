require File.join( File.dirname(__FILE__), '..', '..', '..', 'ar_spec_helper')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'job')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'user')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'priority')

describe Orms::ActiveRecordVersion2 do

  before do
    Job.destroy_all
    User.destroy_all
  end

  describe '#find' do
   context 'there is a Job(data: #User{:name => marcelo})' do

      before do
        user = User.create(:name => 'marcelo')
        @job = Job.create(:name => 'job1', :data => YAML.dump(user))
        @job.priorities.create(:value => 1)
        @job.priorities.create(:value => 2)
        @job.priorities.create(:value => 3)
        @job2 = Job.create(:name => 'job2', :data => YAML.dump(user))
        @job2.priorities.create(:value => 3)
        @job3 = Job.create(:name => 'job3')
        @yaml_conditions = {}
        @conditions = {}
        @includes = {}
        @selector = :first
      end

      subject { Job.find(@selector, :include => @includes, :yaml_conditions => @yaml_conditions, :conditions => @conditions) }

      context ":yaml_conditions == { :data => { :class => User, :name => 'marcelo' } }" do
        before do
          @yaml_conditions = { :data => { :class => User, :name => 'marcelo' } }
        end

        it { should == @job }

        context 'used with standard conditions (String version), that should match the existing Job.' do
          before do
            @conditions = "name = 'job1'"
          end

          it { should == @job }
        end

        context 'used with standard conditions (Hash version), that should match the existing Job.' do
          before do
            @conditions = { :name => 'job1' }
          end

          it { should == @job }
        end

        context 'used with standard conditions (Array version), that should match the existing Job.' do
          before do
            @conditions = [ 'name = ?', 'job1' ]
          end

          it { should == @job }
        end

        context 'used with std nested contidions (Hash version), that should match' do
          before do
            @includes = :priorities
            @conditions = { :name => 'job1', :priorities => { :value => 1 } }
          end

          it { should == @job }
        end

        context 'used with std nested contidions (Hash version), that should match MANY priorities' do
          before do
            @includes = :priorities
            @conditions = { :name => 'job1', :priorities => { :value => [1, 3] } }
          end

          it { should == @job }
        end

        context 'used with std nested contidions (Array version), that should match MANY jobs' do
          before do
            @selector = :all
            @includes = :priorities
            @conditions = [ '(jobs.name = ? OR jobs.name = ?) and priorities.value IN (?)', 'job1', 'job2', [1, 3] ]
          end

          it { should == [@job, @job2] }
        end

        context 'used with std nested contidions (Hash version), that should NOT match' do
          before do
            @includes = :priorities
            @conditions = { :name => 'job1', :priorities => { :value => 14 } }
          end

          it { should be_nil }
        end

        context 'used with std nested contidions (Array version), that should match' do
          before do
            @includes = :priorities
            @conditions = [ 'jobs.name = ? AND priorities.value = ?', 'job1', 2 ]
          end

          it { should == @job }
        end

       context 'used with std nested contidions (Array version), that should NOT match' do
          before do
            @includes = :priorities
            @conditions = [ 'jobs.name = ? AND priorities.value = ?', 'job1', 14 ]
          end

          it { should be_nil }
        end

        context 'used with standard conditions (that should NOT match the existing Job)' do
          before do
            @conditions = { :name => 'unexisting' }
          end

          it { should be_nil }
        end
      end

      context ":yaml_conditions == { :data => { :class => User, :name => 'andres' } }" do
        before do
          @yaml_conditions = { :data => { :class => User, :name => 'andres' } }
        end

        it { should be_nil }
      end
    end

    context 'there is a Job(data: #Struct{:method => :new_email, :handler => User#(email => marcelo) })' do

      before do
        @struct = Struct.new(:method, :handler, :email)
        @user = User.create(:name => 'marcelo', :address => 'address1')
        struct_instance = @struct.new(:new_email, @user.to_yaml, 'foo@gmail.com')
        @job = Job.create(:name => 'job1', :data => struct_instance)
        @yaml_conditions = {}
        @conditions = {}
      end

      subject { Job.find(:first, :yaml_conditions => @yaml_conditions, :conditions => @conditions) }

      context 'filter for string attribute stored on the serialized field' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :email => 'foo@gmail.com' } }
        end

        it { should == @job }
      end

      context 'filter for symbol attribute stored on the serialized field' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :method => :new_email } }
        end

        it { should == @job }
      end

      context "yaml_conditions have the right hierarchy" do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :handler => { :class => 'User', :name => 'marcelo', :address => 'address1' } } }
        end

        it { should == @job }

       context 'used with standard conditions (that should match the existing Job)' do
          before do
            @conditions = { :name => 'job1' }
          end

          it { should == @job }
        end

       context 'used with standard conditions (that should NOT match the existing Job)' do
          before do
            @conditions = { :name => 'unexisting' }
          end

          it { should be_nil }
        end
      end

      context "yaml_conditions that match key/value but WRONG hierarchy" do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :struct => { :handler => { :another_nested_object => { :class => 'User', :name => 'marcelo' } } } } }
        end

        it { should be_nil }
      end

      context "correct yaml_conditions but WRONG class name" do
        before do
          @yaml_conditions = { :data => { :class => 'WrongModel', :struct => { :handler => { :class => 'User', :name => 'marcelo' } } } }
        end

        it { should be_nil }
      end

      context ":yaml_conditions == { :data => { :class => 'Struct', :struct => { :handler => { :class => 'User', :name => 'bad-name' } } } }" do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :struct => { :handler => { :class => 'User', :name => 'bad-name' } } } }
        end

        it { should be_nil }
      end
    end
  end
end
