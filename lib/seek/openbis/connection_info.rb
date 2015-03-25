module Seek
  module Openbis
    #to store and pass about the connection info - for the purposes of the demo only
    #this is bad practice and not threadsafe or secure
    class ConnectionInfo
      include Singleton
      attr_accessor :username,:password,:endpoint

      def self.setup username,password,endpoint
        me = self.instance
        me.username=username
        me.password=password
        me.endpoint=endpoint
      end
    end
  end
end