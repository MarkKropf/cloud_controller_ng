module VCAP::CloudController
  module Jobs
    module Runtime
      class DropletUpload < Struct.new(:local_path, :app_id)
        include VCAP::CloudController::TimedJob

        def perform
          Timeout.timeout max_run_time(:droplet_upload) do
            app = VCAP::CloudController::App[id: app_id]

            if app
              blobstore = CloudController::DependencyLocator.instance.droplet_blobstore
              CloudController::DropletUploader.new(app, blobstore).upload(local_path)
            end

            FileUtils.rm_f(local_path)
          end
        end

        def error(job, _)
          if job.attempts == max_attempts - 1 && File.exists?(local_path)
            FileUtils.rm_f(local_path)
          end
        end

        def max_attempts
          3
        end
      end
    end
  end
end
