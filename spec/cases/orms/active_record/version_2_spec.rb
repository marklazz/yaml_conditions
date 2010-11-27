require File.join( File.dirname(__FILE__), '..', '..', '..', 'ar_spec_helper')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'job')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'user')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'user_data')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'priority')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'period')

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
        with_warnings(nil) { @struct = Struct.new('MyStruct', :method, :handler, :email, :number, :some_rate) }
        @user = User.create(:name => 'marcelo', :address => 'address1')
        struct_instance = @struct.new(:new_email, @user.to_yaml, 'foo@gmail.com', 4, 0.005)
        @job = Job.create(:name => 'job1', :data => struct_instance)
        @yaml_conditions = {}
        @conditions = {}
      end

      subject { Job.find(:first, :yaml_conditions => @yaml_conditions, :conditions => @conditions) }

      context 'filter for the proper class but wrong float' do
        before do
          @yaml_conditions = { :data => { :class => 'MyStruct', :some_rate =>  0.003 } }
        end

        it { should be_nil }
      end

      context 'filter for the proper class and float number' do
        before do
          @yaml_conditions = { :data => { :class => 'MyStruct', :some_rate =>  0.005 } }
        end

        it { should == @job }
      end

      context 'filter for the class of the serialized field' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct::MyStruct' } }
        end

        it { should == @job }
      end

      context 'filter for the class of the serialized field' do
        before do
          @yaml_conditions = { :data => { :class => 'MyStruct' } }
        end

        it { should == @job }
      end

      context 'filter for string attribute stored on the serialized field' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :email => 'foo@gmail.com' } }
        end

        it { should == @job }
      end

      context 'filter by the proper symbol, an integer and a float number' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :method => :new_email, :number => 4, :some_rate => 0.005 } }
        end

        it { should == @job }
      end

      context 'filter by the correct symbol and integer, but a wrong float number' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :method => :new_email, :number => 4, :some_rate => 0.002 } }
        end

        it { should be_nil }
      end

      context 'filter by the proper symbol and number' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :method => :new_email, :number => 4 } }
        end

        it { should == @job }
      end

      context 'filtering with the correct symbol and a wrong number' do
        before do
          @yaml_conditions = { :data => { :class => 'Struct', :method => :new_email, :number => 3 } }
        end

        it { should be_nil }
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

      context 'query a nested ActiveRecord value' do
        before do
          period = Period.create(:year => 2000)
          user_data = UserData.create(:social_number => 123, :title => 'Computer Engineer', :period => period)
          user = User.create(:name => 'marcelo', :details => user_data)
          @complex_job = Job.create(:name => 'job1', :data => { :owner => user })
        end

        context 'query using correct social_number' do
          before do
            @yaml_conditions = { :data => { :class => Hash, :owner => { :name => 'marcelo', :details => { :social_number => 123 } } } }
          end

          it { should == @complex_job }
        end

        context 'query using correct social_number' do
          before do
            @yaml_conditions = { :data => { :class => Hash, :owner => { :name => 'marcelo', :details => { :social_number => 124 } } } }
          end

          it { should be_nil }
        end

        context 'query using the UserData class' do
          before do
            @yaml_conditions = { :data => { :class => Hash, :owner => { :name => 'marcelo', :details => { :class => UserData } } } }
          end

          it { should == @complex_job }
        end

        context 'query using the UserData class and title and social_number' do
          before do
            @yaml_conditions = { :data => { :class => Hash, :owner => { :name => 'marcelo', :details => { :class => UserData, :title =>  'Computer Engineer' } } } }
          end

          it { should == @complex_job }
        end

        context 'query using the UserData class, social_number and wrong title' do
          before do
            @yaml_conditions = { :data => { :class => Hash, :owner => { :name => 'marcelo', :details => { :class => UserData, :title =>  'Teacher' } } } }
          end

          it { should be_nil }
        end

        context 'query using the UserData class and title and social_number' do
          before do
            @yaml_conditions = { :data => { :class => Hash, :owner => { :name => 'marcelo', :details => { :class => UserData, :title =>  'Computer Engineer', :period => { :class => Period, :year => 2000 } } } } }
          end

          it { should == @complex_job }
        end

        context 'query using NotSerializedField' do
          before do
            @yaml_conditions = { :data => { :class => Hash, :owner => { :name => 'marcelo', :details => { :class => UserData, :title =>  'Computer Engineer', :period => { :class => Period, :year => Yaml::NotSerializedField.new(2000) } } } } }
          end

          it { should == @complex_job }
        end
      end
    end
  end
end
