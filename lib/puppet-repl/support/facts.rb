module PuppetRepl
  module Support
    module Facts
      # in the future we will want to grab real facts from real systems via puppetdb
      # or enc data
      def facterdb_filter
        'operatingsystem=RedHat and operatingsystemrelease=/^7/ and architecture=x86_64 and facterversion=/^2.4\./'
      end

      def set_facts(value)
        @facts = value
      end

      # uses facterdb (cached facts) and retrives the facts given a filter
      # creates a new facts object
      # we could also use fact_merge to get real facts from the real system or puppetdb
      def default_facts
        unless @facts
          node_facts = FacterDB.get_facts(facterdb_filter).first
          values = Hash[ node_facts.map { |k, v| [k.to_s, v] } ]
          @facts ||= Puppet::Node::Facts.new(values['fqdn'], values)
        end
        @facts
      end

      def server_facts
        data = {}
        data["servername"] = Facter.value("fqdn")
        data['serverip'] = Facter.value("ipaddress")
        data["serverversion"] = Puppet.version.to_s
        data
      end

    end
  end
end
