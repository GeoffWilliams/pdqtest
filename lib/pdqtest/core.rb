module PDQTest
  module Core

    def self.run(functions)
      # wrap in array if needed
      functions = Array(functions)
      functions.each { |f|
        if ! f.call
          abort("ABORTED - there are test failures! :(")
        end
      }

      true
    end

  end
end