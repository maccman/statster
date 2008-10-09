class Stats < Merb::Controller
  does_not_provide :html
  provides :xml, :json
  
  def index
    conds = []
    args  = []
    
    if params[:host]
      conds << 'host = ?'
      args  << params[:host]
    end
    
    if params[:path]
      conds << 'path = ?'
      args  << params[:path]
    end
    
    if params[:query]
      conds << 'query = ?'
      args  << params[:query]
    end
    
    if params[:time_period]
      conds << 'time_period = ?'
      args  << params[:time_period]
    elsif params[:time]
      if params[:to_time]
        conds << 'time_period BETWEEN ? AND ?'
        args  << convert_time(params[:time])
        args  << convert_time(params[:to_time])
      else
        conds << 'time_period = ?'
        args  << convert_time(params[:time])
      end
    end
    
    args.insert(0, conds.join(' AND ')) if conds.any?
    
    if params[:sum]
      result        = SumResult.new
      result.hits   = Stat.sum(:hits,   args)
      result.visits = Stat.sum(:visits, args)
    else
      result = Stat.all(args)
    end
    display result
  end
  
  def stats_file
    path_a = File.join(Merb.root, *%w[lib stats.js.erb])
    path_b = File.join(Merb.root, *%w[public stats.js])
    data = ERB.new(File.read(path_a)).result
    File.open(path_b, 'w+') {|f| f.write data }
    self.content_type = :js
    data
  end
  
  def record
    Stat.record(
      request.remote_ip,
      request.user_agent, 
      request.referer,
      (params[:unique] == 'true')
    )
    run_later {
      Stat.commit! if Stat.needs_commit?
    }
    send_file(File.join(Merb.root, *%w[public blank.gif]), {
      :disposition => 'inline',
      :filename => 'blank.gif',
      :type => 'image/gif'
    })
  end
  
  # Force commit
  def commit
    Stat.commit!
    ''
  end
  
  private
  
    class SumResult
      attr_accessor :visits,
                    :hits
      
      def to_xml(options = {})
        options[:indent] ||= 2
        xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
        xml.instruct! unless options[:skip_instruct]
        xml.stat do
          xml.visits  visits
          xml.hits    hits
        end
      end
      
      def to_json
        {
          :visits => visits,
          :hits   => hits
        }.to_json
      end
    end
  
    def convert_time(str)
      Time.parse_utc(str).to_i / AppConfig.time_period rescue nil
    end
end