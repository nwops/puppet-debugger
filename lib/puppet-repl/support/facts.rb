module PuppetRepl
  module Support
    module Facts
      # in the future we will want to grab real facts from real systems via puppetdb
      # or enc data
      def facterdb_filter
        'operatingsystem=RedHat and operatingsystemrelease=/^7/ and architecture=x86_64 and facterversion=/^2.4\./'
      end

      # uses facterdb (cached facts) and retrives the facts given a filter
      def facts
        unless @facts
          @facts ||= FacterDB.get_facts(facterdb_filter).first
        end
        @facts
      end
    end
  end
end
