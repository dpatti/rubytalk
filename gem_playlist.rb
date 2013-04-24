require 'mysql'                                                                                                                                                 
require 'sqlite3'
require 'youtube_it'

def get_ids
  videos = []
  conn =  Mysql.new('localhost', 'spartoi', '', 'spartoi')
  rs = conn.query('select post_text from phpbb3_posts where topic_id=2102')
  rs.each_hash do |row|
    if row['post_text'] =~ /watch\?v=([-\w]+)/
      videos << $1
    end
  end
  videos
end

def local_db(&block)
  SQLite3::Database.new("playlist.db", &block)
end

def get_local_db
  local_db do |db|
    # Initialize
    db.execute <<-SQL
      create table if not exists playlist (
        id varchar(20)
      );
    SQL

    # Check for stuff
    rows = db.execute <<-SQL
      select * from playlist;
    SQL

    return rows.map(&:first)
  end
end

def add_to_local_db id
  local_db do |db|
    db.execute <<-SQL
      insert into playlist values ("#{ id }");
    SQL
  end
end

def new_items
  get_ids.uniq - get_local_db
end

def add_to_playlist id
  @client ||= YouTubeIt::OAuth2Client.new(
    client_access_token: "",
    client_refresh_token: "",
    client_id: "",
    client_secret: "",
    dev_key: ""
  )
  @client.refresh_access_token!
  @client.add_video_to_playlist("PLZhH5KHVNWwdmzb8LapjfdQPbPdsbDVF7", id)
rescue AuthenticationError => e
  print "...failed: #{ e.to_s.strip }"
  if e.to_s.include?("too_many_recent_calls")
    puts " (retrying in 10s)"
    sleep 10
    retry
  end
rescue UploadError => e
  print "...failed: #{ e.to_s.strip }"
end

new_items.each do |id|
  print "Adding #{ id }"
  add_to_playlist id
  add_to_local_db id
  puts
end
