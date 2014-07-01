require "active_record"
module Collector
   class CollectorDb < ActiveRecord::Base
        def self.configure(config_path)
            config=YAML.load_file(config_path)
            self.abstract_class = true
            establish_connection(
                :adapter => "mysql",
                :host =>config["mysql"]["host"],
                :database =>config["mysql"]["db_name"],
                :username =>config["mysql"]["username"],
                :password =>config["mysql"]["password"],
                :port =>config["mysql"]["port"],
                :pool => 100
            )
        end
    end

    class InstanceStatus < CollectorDb
    	self.table_name="instance_status"
    end

    class DeaList < CollectorDb  
        self.table_name="dea_list"
    end 
end
