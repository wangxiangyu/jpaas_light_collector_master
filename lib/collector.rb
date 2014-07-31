require "logger"
require "database"

module Collector
    class Collector
        def initialize(config_path)
            @config=YAML.load_file(config_path)
            setup_log
        end
        attr_reader :config
        attr_reader :nats
        attr_reader :logger
        def setup_log
            @logger=Logger.new(config['logging']['file'])
            @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
            @logger.formatter = proc do |severity, datetime, progname, msg|
                "[#{datetime}] #{severity} : #{msg}\n"
            end
            @logger.level = Logger::DEBUG
        end
        def run
            begin
                change_state_to_stop
                remove_dead_instance
                remove_dead_dea
            rescue => e
                logger.error("Error in collector:#{e.message} #{e.backtrace}")
            end
        end
        def get_ip
            @local_ip||IPSocket.getaddress(Socket.gethostname)
        end
        def change_state_to_stop
            begin
                EM::PeriodicTimer.new(config["change_instance_to_stop_interval"]) do
                    time_change_instance_to_stop=Time.now.to_i-config["change_instance_to_stop_interval"]
                    InstanceStatus.where("time < #{time_change_instance_to_stop} AND state='RUNNING'").update_all({:state=>"STOPPED"})
                end
            rescue => e
                logger.error("Error in remove dead instance:#{e.message} #{e.backtrace}")
            end
        end

        def remove_dead_instance
            begin
                EM::PeriodicTimer.new(config["remove_dead_instance__interval"]) do
                    InstanceStatus.where("to_del_cnt < 0 ").destroy_all
                end
            rescue => e
                logger.error("Error in remove dead instance:#{e.message} #{e.backtrace}")
            end
        end

        def remove_dead_dea
            begin
                EM::PeriodicTimer.new(config["dea_remove_interval"]) do
                    time_delete=Time.now.to_i-config["dea_remove_interval"]
                    DeaList.where("time < #{time_delete}").destroy_all
                end
            rescue => e
                logger.error("Error in remove dead instance:#{e.message} #{e.backtrace}")
            end
        end
    end
end
