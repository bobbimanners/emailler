#
# netboot65 server
#
# Jonno Downes (jonno@jamtronix.com) - January, 2009
# 
#

Thread.abort_on_exception=true

def log_msg(msg)
  puts "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{msg}"
end

$:.unshift(File.dirname(__FILE__)) unless
	$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'netboot65_tftp'

bootfile_dir=File.expand_path(File.dirname(__FILE__)+"//..//boot")
tftp_server=Netboot65TFTPServer.new(bootfile_dir)

tftp_server.start
begin
  loop do
    sleep(1)  #wake up every second to get keyboard input, so we break on ^C
  end
rescue Interrupt
  log_msg "got interrupt signal - shutting down"
end
tftp_server.shutdown
log_msg "shut down complete."