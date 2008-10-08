require 'sqlite3'
require 'thread'
class Stat
  class Record
    attr_accessor :host,
                  :path, 
                  :query,
                  :time_period,
                  :unique
                
    class << self
      def from_url(referer)
        record        = self.new
        url           = URI.parse(referer)
        record.host   = url.host  || ''
        record.path   = url.path  || ''
        record.query  = url.query || ''
        record
      end      
    end
    
    def initialize
      self.time_period = Time.now.to_i / AppConfig.time_period
    end
  end
  
  @@records   = []
  @@mutex     = Mutex.new
  
  ROBOT_UA    = [
                  /robot/i, 
                  /spider/i, 
                  /bot/i, 
                  /crawl/i, 
                  /harvest/i, 
                  /slurp/i
                ]
                
  class << self
    def record(ip, ua, referer, unique)
      return if ip.blank? or ua.blank? or referer.blank?
      return if invalid_ip?(ip)
      return if invalid_ua?(ua)
      return unless matched_url?(referer)
      record              = Record.from_url(referer)
      record.unique       = unique
      @@records << record
    end
    
    def count(conds = [])
      sql = "SELECT COUNT(*) FROM stats"
      if conds.any?
        sql += " WHERE #{conds.shift}"
        db.get_first_value(sql, conds).to_i
      else
        db.get_first_value(sql).to_i
      end
    end
    
    def delete_all
      db.execute('DELETE FROM stats')
    end
    
    def all(conds = [])
      select_all(conds).collect {|res|
        from_array(res)
      }
    end
    
    def first(conds = [])
      select_first(conds).collect {|res|
        from_array(res)
      }[0]
    end
    
    def commit!
      @@last_wrote = Time.now
      records = []
      @@mutex.synchronize do
        # Would be a race condition
        records = @@records.dup
        @@records = []
      end
      
      db.transaction do |db|
        records.each do |record| 
          db.execute(
            %{
              INSERT INTO stats (
                host, 
                path, 
                query, 
                time_period
              )
              VALUES (?, ?, ?, ?)
            }, 
            record.host, 
            record.path, 
            record.query,
            record.time_period
          )
          
          sql = []
          sql << 'UPDATE stats'
          if record.unique
            sql << 'SET visits = visits + 1, unique_visits = unique_visits + 1'
          else
            sql << 'SET visits = visits + 1'
          end
          sql << 'WHERE host = ? AND path = ? AND query = ? AND time_period = ?'
          db.execute(
            sql.join(" \n"), 
            record.host, 
            record.path, 
            record.query,
            record.time_period
          )
        end
      end
    end
    
    def needs_commit?
      !defined?(@@last_wrote) or @@last_wrote <= (Time.now - AppConfig.write_period)
    end
    
    private
    
      def from_array(ar)
        stat = Stat.new
        stat.host           = ar[0]
        stat.path           = ar[1]
        stat.query          = ar[2]
        stat.visits         = ar[3].to_i
        stat.unique_visits  = ar[4].to_i
        stat.time_period    = ar[5].to_i
        stat
      end
    
      def select_first(conds = [])
        sql = "SELECT * from stats"
        if conds.any?
          sql += " WHERE #{conds.shift}"
          sql += " LIMIT 1"
          db.execute(sql, conds)
        else
          sql += " LIMIT 1"
          db.execute(sql)
        end      
      end
    
      def select_all(conds = [])
        sql = "SELECT * from stats"
        if conds.any?
          sql += " WHERE #{conds.shift}"
          db.execute(sql, conds)
        else
          db.execute(sql)
        end
      end
    
      def db
        @@db ||= begin
          db = SQLite3::Database.new("stats.sqlite3")
          db.execute(%{
            CREATE TABLE IF NOT EXISTS 'stats' (
              'host'           VARCHAR(255),
              'path'           VARCHAR(255),
              'query'          VARCHAR(255),
              'visits'         INTEGER DEFAULT 0,
              'unique_visits'  INTEGER DEFAULT 0,
              'time_period'    INTEGER UNIQUE ON CONFLICT IGNORE NOT NULL
            ) 
          })
          db.execute_batch(%{
            CREATE INDEX IF NOT EXISTS 'host_index'  ON 'stats' ('host');
            CREATE INDEX IF NOT EXISTS 'path_index'  ON 'stats' ('path');
            CREATE INDEX IF NOT EXISTS 'query_index' ON 'stats' ('query');  
            CREATE INDEX IF NOT EXISTS 'time_period_index' ON 'stats' ('time_period');
          })
          db
        end
      end
      
      def invalid_ip?(ip)
        AppConfig.ip_blacklist && AppConfig.ip_blacklist.include?(ip)
      end
    
      def invalid_ua?(ua)
        ROBOT_UA.select {|n| n =~ ua }.any?
      end
      
      def matched_url?(url)
        !AppConfig.match_url or url =~ Regexp.new(AppConfig.match_url)
      end
  end
  
  # Attributes
  attr_accessor :host,
                :path, 
                :query,
                :visits,
                :unique_visits,
                :time_period
end

END { Stat.commit! }