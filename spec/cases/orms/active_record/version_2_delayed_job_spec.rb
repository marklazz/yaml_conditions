require File.join( File.dirname(__FILE__), '..', '..', '..', 'ar_spec_helper')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'job')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'user')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'priority')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'delayed', 'job')
require File.join( File.dirname(__FILE__), '..', '..', '..', 'models', 'delayed', 'performable_method')

describe ::Orms::ActiveRecordVersion2 do

  before do
    Delayed::Job.destroy_all
    User.destroy_all
  end

  describe 'Delayed::Job#find' do

    class NotificationMailer; end # define this for test purposes

    before do
      user = User.create(:name => 'marcelo')
      @performable_method = Delayed::PerformableMethod.new(NotificationMailer, :deliver_admin_login, [ user, nil ])
      @job = Delayed::Job.create(:handler => "--- !ruby/struct:Delayed::PerformableMethod \nobject: CLASS:NotificationMailer\nmethod: :deliver_admin_login\nargs: \n- AR:User:#{user.id}\n- \n")
    end

    subject { Delayed::Job.first(:yaml_conditions => @yaml_conditions) }

    context 'test filter by args' do

      before do
        @yaml_conditions = { :handler => { :args => [ User.find_by_name('marcelo'), nil ] } }
      end

      #it { should == @job }
    end

    context 'test filtering by object and args' do
      before do
        @yaml_conditions = { :handler => { :object => NotificationMailer, :args => [ User.find_by_name('marcelo'), nil ] } }
      end

      #it { should == @job }
    end

    context 'test filtering by object, method and args' do
      before do
        @yaml_conditions = { :handler => { :object => NotificationMailer, :method => :deliver_admin_login, :args => [ User.find_by_name('marcelo'), nil ] } }
      end

      #it { should == @job }
    end

    context 'test filtering by object, method and wrong args' do
      before do
        user2 = User.create(:name => 'andres')
        @yaml_conditions = { :handler => { :object => NotificationMailer, :method => :deliver_admin_login, :args => [ User.find_by_name('andres'), nil ] } }
      end

      #it { should be_nil }
    end

    context 'test filtering by object, args and wrong method' do
      before do
        user2 = User.create(:name => 'andres')
        @yaml_conditions = { :handler => { :object => NotificationMailer, :method => :deliver_admin_login2, :args => [ User.find_by_name('andres'), nil ] } }
      end

      #it { should be_nil }
    end

    context 'test filtering by method, args and wrong object' do
      before do
        user2 = User.create(:name => 'andres')
        @yaml_conditions = { :handler => { :object => Object, :method => :deliver_admin_login2, :args => [ User.find_by_name('andres'), nil ] } }
      end

      #it { should be_nil }
    end

    context 'test filtering by object and args' do
      before do
        user2 = User.create(:name => 'andres')
        @job = Delayed::Job.create(:handler => "--- !ruby/struct:Delayed::PerformableMethod \nobject: CLASS:NotificationMailer\nmethod: :deliver_admin_login\nargs: \n- AR:User:#{user2.id}\n- Pablo\n")
        @yaml_conditions = { :handler => { :object => NotificationMailer, :args => [ User.find_by_name('andres'), 'Pablo' ] } }
      end

      #it { should == @job }
    end

    context 'test filter by args using wildcard' do

      before do
        @yaml_conditions = { :handler => { :args => [ User.find_by_name('marcelo'), '*' ] } }
      end

      #it { should == @job }
    end

    context 'test filter by using wildcard on args and specifying object' do

      before do
        @yaml_conditions = { :handler => { :object => NotificationMailer, :args => [ User.find_by_name('marcelo'), '*' ] } }
      end

      #it { should == @job }
    end

    context 'test filter by using wildcard on args and method, also specifying object' do

      before do
        @yaml_conditions = { :handler => { :object => NotificationMailer, :method => '*', :args => [ User.find_by_name('marcelo'), '*' ] } }
      end

      #it { should == @job }
    end

    context 'test filter by using wildcard on object, method and args also specified' do

      before do
        @yaml_conditions = { :handler => { :object => '*', :method => :deliver_admin_login, :args => [ User.find_by_name('marcelo'), nil ] } }
      end

      #it { should == @job }
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
          #it { should == @job_with_nested }
        end

        context 'with wrong value' do
          before do
            @yaml_conditions = { :handler => { :args => [ { :user => { :first_name => 'Pablo' }} ] } }
          end
          #it { should be_nil }
        end

        context 'with wrong hierarchy' do
          before do
            @yaml_conditions = { :handler => { :args => [ { :first_name => 'Marcelo' } ] } }
          end
          #it { should be_nil }
        end
      end

     context 'query last_name and city vlues of the delayed::job argument' do
        context 'with proper values' do
          before do
            @yaml_conditions = { :handler => { :args => [ { :user => { :last_name => 'Giorgi', :address => { :city => 'Montevideo' } } } ] } }
          end
          #it { should == @job_with_nested }
        end

        context 'with wrong value' do
          before do
            @yaml_conditions = { :handler => { :args => [ { :user => { :last_name => 'Marcelo', :address => { :city => 'Rio Negro' } } } ] } }
          end
          #it { should be_nil }
        end

        context 'with wrong hierarchy' do
          before do
            @yaml_conditions = { :handler => { :args => [ { :city => 'Montevideo' } ] } }
          end
          #it { should be_nil }
        end
      end
    end
  end
end
