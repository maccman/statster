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
      conds << 'host = query'
      args  << params[:query]
    end
    
    if params[:time_period]
      conds << 'time_period = ?'
      args  << params[:time_period]
    end
    
    args.insert(0, conds.join(' ')) if conds.any?
    
    if params[:count]
      count = Stat.count(args)
      display count
    else
      stats = Stat.all(args)
      display(stats)
    end
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
      !!params[:unique]
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
end