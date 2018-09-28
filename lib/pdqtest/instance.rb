require 'docker-api'
require 'pdqtest/puppet'
require 'pdqtest/docker'
require 'escort'

module PDQTest
  module Instance
    @@keep_container = false
    @@active_container = nil
    @@image_name = false
    @@privileged = false

    def self.get_active_container
      @@active_container
    end

    def self.get_keep_container
      @@keep_container
    end

    def self.set_keep_container(keep_container)
      @@keep_container = keep_container
    end

    def self.set_docker_image(image_name)
      @@image_name =
          if image_name
            Array(image_name.split(/,/))
          else
            false
          end
    end

    def self.set_privileged(privileged)
      @@privileged = privileged
    end

    def self.get_privileged
      @@privileged
    end

    def self.run(example=nil)
      # needed to prevent timeouts from container.exec()
      Excon.defaults[:write_timeout] = 10000
      Excon.defaults[:read_timeout] = 10000
      status = true

      # remove reference to any previous test container
      @@active_container = nil

      if PDQTest::Puppet::find_examples().empty?
        $logger.info "No acceptance tests found, annotate examples with #{PDQTest::Puppet.setting(:magic_marker)} to make some"
      else
        # process each supported OS
        test_platforms = @@image_name || Docker::acceptance_test_images
        $logger.info "Acceptance test on #{test_platforms}..."
        test_platforms.reject { |image_name|
          reject = false
          if Util.is_windows
            if image_name !~ /windows/
              $logger.info "Skipping test image #{image_name} (requires Linux)"
              reject = true
            end
          else
            if image_name =~ /windows/
              $logger.info "Skipping test image #{image_name} (requires Windows)"
              reject = true
            end
          end

          reject
        }.each { |image_name|
          $logger.info "--- start test with #{image_name} ---"
          @@active_container = PDQTest::Docker::new_container(image_name, @@privileged)
          $logger.info "alive, running tests"
          status &= PDQTest::Puppet.run(@@active_container, example)

          if @@keep_container
            $logger.info "finished build, container #{@@active_container.id} left on system"
            $logger.info "  docker exec -ti #{@@active_container.id} #{Util.shell} "
          else
            PDQTest::Docker.cleanup_container(@@active_container)
            @@active_container = nil
          end

          $logger.info "--- end test with #{image_name} (status: #{status})---"
        }
      end
      $logger.info "overall acceptance test status=#{status}"
      status
    end

    def self.shell
      # pick the first test platform to test on as our shell - want to do a specific one
      # just list it with --image-name
      image_name = (@@image_name || Docker::acceptance_test_images).first
      $logger.info "Opening a shell in #{image_name}"
      @@active_container = PDQTest::Docker::new_container(image_name, @@privileged)

      PDQTest::Docker.exec(@@active_container, PDQTest::Puppet.setup)

      # In theory I should be able to get something like the code below to
      # redirect all input streams and give a makeshift interactive shell, howeve
      # I'm damned if I get get this to do anything at all, so instead go the
      # easy way and start the container running, then use system() to redirect
      # all streams using the regular docker command.  Works a treat!
      # @@active_container.tap(&:start).attach(:tty => true)
      # @@active_container.exec('bash', tty: true).tap(&:start).attach( :tty => true, :stdin => $stdin) { |out, err|
      #   puts out
      #   puts err
      # }
      system("docker exec -ti #{@@active_container.id} #{Util.shell}")
      if @@keep_container
        $logger.info "finished build, container #{@@active_container.id} left on system"
        $logger.info "  docker exec -ti #{@@active_container.id} #{Util.shell} "
      else
          PDQTest::Docker.cleanup_container(@@active_container)
          @@active_container = nil
      end
    end
  end
end
