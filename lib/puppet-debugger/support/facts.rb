module PuppetDebugger
  module Support
    module Facts
      # in the future we will want to grab real facts from real systems via puppetdb
      # or enc data

      # allow the user to specify the facterdb filter
      def dynamic_facterdb_filter
        ENV['REPL_FACTERDB_FILTER'] || default_facterdb_filter
      end

      def default_facterdb_filter
        "operatingsystem=#{facter_os_name} and operatingsystemrelease=#{facter_os_version} and architecture=x86_64 and facterversion=#{facter_version}"
      end

      def facter_version
        ENV['REPL_FACTER_VERSION'] || default_facter_version
      end

      # return the correct supported version of facter facts
      def default_facter_version
        if Gem::Version.new(Puppet.version) >= Gem::Version.new(4.4)
          '/^3\.1/'
        else
          '/^2\.4/'
        end
      end

      def facter_os_name
        ENV['REPL_FACTER_OS_NAME'] || 'Fedora'
      end

      def facter_os_version
        ENV['REPL_FACTER_OS_VERSION'] || '23'
      end

      def set_facts(value)
        @facts = value
      end

      # uses facterdb (cached facts) and retrives the facts given a filter
      # creates a new facts object
      # we could also use fact_merge to get real facts from the real system or puppetdb
      def node_facts
        node_facts = FacterDB.get_facts(dynamic_facterdb_filter).first
        if node_facts.nil?
          message = <<-EOS
Using filter: #{facterdb_filter}
Bad FacterDB filter, please change the filter so it returns a result set.
See https://github.com/camptocamp/facterdb/#with-a-string-filter
          EOS
          raise PuppetDebugger::Exception::BadFilter.new(:message => message)
        end
        # fix for when --show-legacy facts are not part of the facter 3 fact set
        node_facts[:fqdn] = node_facts[:networking].fetch('fqdn',nil) unless node_facts[:fqdn]
        node_facts
      end

      def default_facts
        unless @facts
          values = Hash[ node_facts.map { |k, v| [k.to_s, v] } ]
          name = values['fqdn']
          @facts ||= Puppet::Node::Facts.new(name, values)
        end
        @facts
      end

      def server_facts
        data = {}
        data["servername"] = Facter.value("fqdn") || Facter.value('networking')['fqdn']
        data['serverip'] = Facter.value("ipaddress")
        data["serverversion"] = Puppet.version.to_s
        data
      end

    end
  end
end
