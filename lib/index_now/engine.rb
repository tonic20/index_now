module IndexNow
  class Engine < ::Rails::Engine
    isolate_namespace IndexNow

    rake_tasks do
      load File.expand_path("../tasks/index_now.rake", __dir__)
    end
  end
end
