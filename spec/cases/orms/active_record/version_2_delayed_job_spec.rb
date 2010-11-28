require File.join( File.dirname(__FILE__), '..', '..', '..', 'ar_spec_helper')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'job')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'user')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'priority')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'support_classes')
# require delayed_job if available
begin
  require "delayed_job"
rescue LoadError
  # not installed
end

describe ::Orms::ActiveRecordVersion2 do

  before do
    Delayed::Job.destroy_all
    User.destroy_all
  end

  describe 'Delayed::Job#find' do
    context "Used with PerformableMethod's jobs" do

        before do
          user = User.create(:name => 'marcelo')
          @job = Delayed::Job.enqueue Delayed::PerformableMethod.new(NotificationMailer, :deliver_admin_login, [ User.find_by_name('marcelo'), nil ] )
        end

        subject { Delayed::Job.first(:yaml_conditions => @yaml_conditions) }

        context 'test filter by class' do

          before do
            @yaml_conditions = { :class => Delayed::PerformableMethod }
          end

          it { should == @job }
        end


        context 'test filter by args' do

          before do
            @yaml_conditions = { :handler => { :class => Delayed::PerformableMethod, :args => [ User.find_by_name('marcelo'), nil ] } }
          end

          it { should == @job }
        end

        context 'test filtering by object and args' do
          before do
            @yaml_conditions = { :handler => { :object => NotificationMailer, :args => [ User.find_by_name('marcelo'), nil ] } }
          end

          it { should == @job }
        end

        context 'test filtering by object, method and args' do
          before do
            @yaml_conditions = { :handler => { :object => NotificationMailer, :method => :deliver_admin_login, :args => [ User.find_by_name('marcelo'), nil ] } }
          end

          it { should == @job }
        end

        context 'test filtering by object, method and wrong args' do
          before do
            user2 = User.create(:name => 'andres')
            @yaml_conditions = { :handler => { :object => NotificationMailer, :method => :deliver_admin_login, :args => [ User.find_by_name('andres'), nil ] } }
          end

          it { should be_nil }
        end

        context 'test filtering by object, args and wrong method' do
          before do
            user2 = User.create(:name => 'andres')
            @yaml_conditions = { :handler => { :object => NotificationMailer, :method => :deliver_admin_login2, :args => [ User.find_by_name('andres'), nil ] } }
          end

          it { should be_nil }
        end

        context 'test filtering by method, args and wrong object' do
          before do
            user2 = User.create(:name => 'andres')
            @yaml_conditions = { :handler => { :object => Object, :method => :deliver_admin_login2, :args => [ User.find_by_name('andres'), nil ] } }
          end

          it { should be_nil }
        end

        context 'test filtering by object and args' do
          before do
            user2 = User.create(:name => 'andres')
            @job = Delayed::Job.create(:handler => "--- !ruby/struct:Delayed::PerformableMethod \nobject: CLASS:NotificationMailer\nmethod: :deliver_admin_login\nargs: \n- AR:User:#{user2.id}\n- Pablo\n")
            @yaml_conditions = { :handler => { :object => NotificationMailer, :args => [ User.find_by_name('andres'), 'Pablo' ] } }
          end

          it { should == @job }
        end

        context 'test filter by args using wildcard' do

          before do
            @yaml_conditions = { :handler => { :args => [ User.find_by_name('marcelo'), '*' ] } }
          end

          it { should == @job }
        end

        context 'test filter by using wildcard on args and specifying object' do

          before do
            @yaml_conditions = { :handler => { :object => NotificationMailer, :args => [ User.find_by_name('marcelo'), '*' ] } }
          end

          it { should == @job }
        end

        context 'test filter by using wildcard on args and method, also specifying object' do

          before do
            @yaml_conditions = { :handler => { :object => NotificationMailer, :method => '*', :args => [ User.find_by_name('marcelo'), '*' ] } }
          end

          it { should == @job }
        end

        context 'test filter by using wildcard on object, method and args also specified' do

          before do
            @yaml_conditions = { :handler => { :object => '*', :method => :deliver_admin_login, :args => [ User.find_by_name('marcelo'), nil ] } }
          end

          it { should == @job }
        end

        context 'test filter by using wildcard on object, method and args also specified (withuod handler wrapper)' do

          before do
            @yaml_conditions = { :object => '*', :method => :deliver_admin_login, :args => [ User.find_by_name('marcelo'), nil ] }
          end

          it { should == @job }
        end

        context "job with nested hash: { :user => { :first_name => 'Marcelo', :last_name => 'Giorgi', :address => { :city => 'Montevideo', :country => 'Uruguay' } }}" do
          before do
            @job_with_nested = Delayed::Job.create(:handler => "--- !ruby/struct:Delayed::PerformableMethod \nobject: CLASS:NotificationMailer\nmethod: :deliver_test_email\nargs: \n- :user: \n    :first_name: Marcelo\n    :last_name: Giorgi\n    :address: \n      :city: Montevideo\n      :country: Uruguay\n")
          end

          context 'query first_name hash value of the delayed::job argument' do
            context 'with proper value' do
              before do
                @yaml_conditions = { :handler => { :args => [ { :user => { :first_name => 'Marcelo' }} ] } }
              end
              it { should == @job_with_nested }
            end

            context 'with wrong value' do
              before do
                @yaml_conditions = { :handler => { :args => [ { :user => { :first_name => 'Pablo' }} ] } }
              end
              it { should be_nil }
            end

            context 'with wrong hierarchy' do
              before do
                @yaml_conditions = { :handler => { :args => [ { :first_name => 'Marcelo' } ] } }
              end
              it { should be_nil }
            end
          end

         context 'query last_name and city vlues of the delayed::job argument' do
            context 'with proper values' do
              before do
                @yaml_conditions = { :handler => { :args => [ { :user => { :last_name => 'Giorgi', :address => { :city => 'Montevideo' } } } ] } }
              end
              it { should == @job_with_nested }
            end

            context 'with wrong value' do
              before do
                @yaml_conditions = { :handler => { :args => [ { :user => { :last_name => 'Marcelo', :address => { :city => 'Rio Negro' } } } ] } }
              end
              it { should be_nil }
            end

            context 'with wrong hierarchy' do
              before do
                @yaml_conditions = { :handler => { :args => [ { :city => 'Montevideo' } ] } }
              end
              it { should be_nil }
            end
          end

         context 'query the same as before but wihtout handler key' do
            context 'with proper values' do
              before do
                @yaml_conditions = { :args => [ { :user => { :last_name => 'Giorgi', :address => { :city => 'Montevideo' } } } ] }
              end
              it { should == @job_with_nested }
            end

            context 'with wrong value' do
              before do
                @yaml_conditions = { :args => [ { :user => { :last_name => 'Marcelo', :address => { :city => 'Rio Negro' } } } ] }
              end
              it { should be_nil }
            end

            context 'with wrong hierarchy' do
              before do
                @yaml_conditions = { :args => [ { :city => 'Montevideo' } ] }
              end
              it { should be_nil }
            end
         end
        end
      end
    end

    context 'Used with a custom struct' do

       before do
          user = User.create(:name => 'marcelo')
          simple_job = SimpleJob.new
          simple_job.name = 'job_name'
          simple_job.kind = 'my_kind'
          @job = Delayed::Job.enqueue simple_job
        end

        subject { Delayed::Job.first(:yaml_conditions => @yaml_conditions) }

        context 'filter by correct class' do

          before do
            @yaml_conditions = { :handler => { :class => SimpleJob } }
          end

          it { should == @job }
        end

        context 'filter by correct class (Without handler wrapper)' do

          before do
            @yaml_conditions = { :class => SimpleJob }
          end

          it { should == @job }
        end

        context 'filter by wrong class (Without handler wrapper)' do

          before do
            @yaml_conditions = { :class => NotificationMailer }
          end

          it { should be_nil }
        end

        context 'filter by correct name' do

          before do
            @yaml_conditions = { :handler => { :class => SimpleJob, :name => 'job_name' } }
          end

          it { should == @job }
        end

        context 'filter by correct name and kind (without handler wrapper)' do

          before do
            @yaml_conditions = { :class => SimpleJob, :name => 'job_name', :kind => 'my_kind' }
          end

          it { should == @job }
        end

        context 'filter by wrong name but correct kind (without handler wrapper)' do

          before do
            @yaml_conditions = { :class => SimpleJob, :name => 'wrong_name', :kind => 'my_kind' }
          end

          it { should be_nil }
        end

        context 'filter by correct name, kind and realted_user (not serialized field)' do

          before do
            @yaml_conditions = { :class => SimpleJob, :name => 'job_name', :kind => 'my_kind', :related_user => Yaml::NotSerializedField.new(User.find_by_name('marcelo')) }
          end

          it { should == @job }
        end

        context 'filter by correct name, kind and realted_user (not serialized field)' do

          before do
            User.create(:name => 'andres')
            @yaml_conditions = { :class => SimpleJob, :name => 'job_name', :kind => 'my_kind', :related_user => Yaml::NotSerializedField.new(User.find_by_name('andres')) }
          end

          it { should be_nil }
        end

    context "More on using wildcards and nested structures" do

        before do
          user = User.create(:name => 'marcelo')
          @some_nested_job = Delayed::Job.enqueue Delayed::PerformableMethod.new(NotificationMailer, :deliver_admin_login, [ User.find_by_name('marcelo'), { :some => { :nested => 'strucutre' }} ] )
        end

        subject { Delayed::Job.first(:yaml_conditions => @yaml_conditions) }

        context 'test nested structure with proper conditions' do

          before do
            @yaml_conditions = { :class => Delayed::PerformableMethod, :args => [ '*', '*', { :some => { :nested => 'strucutre' } }] }
          end

          it { should == @some_nested_job }
        end

        context 'test nested structure with wrong method' do

          before do
            @yaml_conditions = { :class => Delayed::PerformableMethod, :args => [ '*', :bad_symbol, { :some => { :nested => 'strucutre' } }] }
          end

          it { should be_nil }
        end

        context 'test nested structure with wrong args' do
          context 'bad string' do
            before do
              @yaml_conditions = { :class => Delayed::PerformableMethod, :args => [ '*', :bad_symbol, { :some => { :nested => 'bad_strucutre' } }] }
            end

            it { should be_nil }
          end

          context 'bad key' do
            before do
              @yaml_conditions = { :class => Delayed::PerformableMethod, :args => [ '*', :bad_symbol, { :some => { :bad_nested => 'strucutre' } }] }
            end

            it { should be_nil }
          end
        end
    end

    end
end if defined?(Delayed::Job)
