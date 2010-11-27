print "Using native MySQL\n"
require 'logger'
$ADAPTER = 'mysql'

ActiveRecord::Base.logger = Logger.new("debug.log")

# GRANT ALL PRIVILEGES ON yaml_conditions_db.* to 'yaml_conditions'@'localhost';

ActiveRecord::Base.configurations = {
  'yaml_conditions_db' => {
    'adapter'   => 'mysql',
    'username'  => 'yaml_conditions',
    'encoding'  => 'utf8',
    'database'  => 'yaml_conditions_db',
  },
}

ActiveRecord::Base.establish_connection 'yaml_conditions_db'
