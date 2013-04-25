require 'mysql'                                                                                                                                                 
require 'sqlite3'
require 'youtube_it'

# Scan the posts for a topic in the database and pull out anything that looks
# like a YouTube id.
def get_ids
  videos = []
  conn =  Mysql.new('localhost', 'spartoi', '', 'spartoi')
  rs = conn.query('select post_text from phpbb3_posts where topic_id=2102')
  # Iterate over the rows in the database we collected
  rs.each_hash do |row|
    # Match the contents against a regex
    if row['post_text'] =~ /watch\?v=([-\w]+)/
      videos << $1
    end
  end
  videos
end

def local_db(&block)
  # Instead of repeating myself, I wrote this method to pass on the block to the
  # initializer below. What I should have done was just save this to an instance
  # variable at the start and not recreate it each time.
  SQLite3::Database.new("playlist.db", &block)
end

def get_local_db
  local_db do |db|
    # Initialize - I used heredocs here (fancy multi-line strings) since that's
    # what they did in the documentation. Honestly nothing here was worthy of
    # more than one line.
    db.execute <<-SQL
      create table if not exists playlist (
        id varchar(20)
      );
    SQL

    # Check for stuff
    rows = db.execute <<-SQL
      select * from playlist;
    SQL

    # Remember we get an array of rows. Each row is an array with one element.
    # So we have to flatten.
    return rows.flatten
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
  # Some ids may have been posted twice (i.e., if you quote a post with a
  # video), so we .uniq to remove those. Array subtraction to get what is left.
  get_ids.uniq - get_local_db
end

def add_to_playlist id
  # Set up the client only once
  @client ||= YouTubeIt::OAuth2Client.new(
    client_access_token: "",
    client_refresh_token: "",
    client_id: "",
    client_secret: "",
    dev_key: ""
  )
  # This is for OAuth2, and ideally I would move this to the first time and
  # anytime there is an AuthenticationError
  @client.refresh_access_token!
  @client.add_video_to_playlist("PLZhH5KHVNWwdmzb8LapjfdQPbPdsbDVF7", id)

rescue AuthenticationError => e
  # I didn't mention these errors. They mostly happen if the user who uploaded
  # the video got deleted or if the video was deleted.
  print "...failed: #{ e.to_s.strip }"
  # Or too many calls. Take a break and try again.
  if e.to_s.include?("too_many_recent_calls")
    puts " (retrying in 10s)"
    sleep 10
    # This actually just restarts the method. Can only be used within a rescue
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
