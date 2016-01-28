namespace :db do
  namespace :mongo do
    desc 'Drops all the collections for the database for the current Rails.env'
    task :drop => :environment do
      Mongoid.master.collections.each {|col| col.drop_indexes && col.drop unless ['system.indexes', 'system.users'].include?(col.name) }
    end

    desc 'Load the seed data from db/seeds.rb'
    task :seed => :environment do
      seed_file = File.join(Rails.application.root, 'db', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end

    desc 'Create the database, and initialize with the seed data'
    task :setup => [ 'db:mongo:create', 'db:mongo:seed' ]

    desc 'Delete data and seed'
    task :reseed => [ 'db:mongo:drop', 'db:mongo:seed' ]

    desc 'Current database version'
    task :version => :environment do
      puts Mongoid::Migrator.current_version.to_s
    end

    desc "Migrate the database through scripts in db/mongo/migrate or the paths you sepcify with MIGRATE_PATH=a/b/c,a/b/d,a/b/e. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
    task :migrate => :environment do
      Mongoid::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      path = ENV['MIGRATE_PATH'] ? ENV['MIGRATE_PATH'].split(':') : Mongoid::Migrator.migrations_path
      Mongoid::Migrator.migrate(path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    end

    namespace :migrate do
      desc  'Rollback the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
      task :redo => :environment do
        if ENV["VERSION"]
          Rake::Task["db:mongo:migrate:down"].invoke
          Rake::Task["db:mongo:migrate:up"].invoke
        else
          Rake::Task["db:mongo:rollback"].invoke
          Rake::Task["db:mongo:migrate"].invoke
        end
      end

      desc 'Resets your database using your migrations for the current environment'
      # should db:create be changed to db:setup? It makes more sense wanting to seed
      task :reset => ["db:mongo:drop", "db:mongo:create", "db:mongo:migrate"]

      desc 'Runs the "up" for a given migration VERSION. Overwrite the default script path with MIGRATE_PATH=a/b/c,a/b/d,a/b/e.'
      task :up => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        path = ENV['MIGRATE_PATH'] ? ENV['MIGRATE_PATH'].split(':') : Mongoid::Migrator.migrations_path
        Mongoid::Migrator.run(:up, path, version)
      end

      desc 'Runs the "down" for a given migration VERSION. Overwrite the default script path with MIGRATE_PATH=a/b/c,a/b/d,a/b/e.'
      task :down => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        path = ENV['MIGRATE_PATH'] ? ENV['MIGRATE_PATH'].split(':') : Mongoid::Migrator.migrations_path
        Mongoid::Migrator.run(:down, path, version)
      end
    end

    desc 'Rolls the database back to the previous migration. Specify the number of steps with STEP=n. Overwrite the default script path with MIGRATE_PATH=a/b/c,a/b/d,a/b/e.'
    task :rollback => :environment do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      path = ENV['MIGRATE_PATH'] ? ENV['MIGRATE_PATH'].split(':') : Mongoid::Migrator.migrations_path
      Mongoid::Migrator.rollback(path, step)
    end

    namespace :schema do
      task :load do
        # noop
      end
    end

    namespace :test do
      task :prepare do
        # Stub out for MongoDB
      end
    end
  end
end
