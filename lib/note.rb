require 'Date'
require 'FileUtils'
require 'YAML'

class Note
  @save_dir = File.join(ENV['HOME'], 'Dropbox', 'Research_Journal')
  @base_dir = File.join(@save_dir, 'base')
  @base_suffix = '.tex'
  @base_file = File.join('base', @base_suffix)
  @base_extras = []
  @prefs_loaded = false
  @to_replace = [
    'REPLACE_DAY_CREATED',
    'REPLACE_MONTH_CREATED',
    'REPLACE_YEAR_CREATED'
  ]
  class << self
    attr_accessor :save_dir, :base_suffix, :base_file, :base_extras, 
      :prefs_loaded
  end

  def self.create_note_file(name)
    # make new directory
    new_dir = note_dir(name)
    new_file = "#{name}.#{base_suffix}"
    FileUtils.mkdir_p new_dir
    # copy base file over
    FileUtils.cp File.join(base_dir, base_file),
      File.join(new_dir, new_file)
    # copy extra files over
    base_extras.each { |extra| FileUtils.cp File.join(base_dir, extra) new_dir }
    File.join(new_dir, new_file)
  end

  def self.note_dir(name)
    File.join(save_dir, name)
  end

  def self.load_preferences
    prefs = YAML.load(ENV['HOME'], '.ResNote', 'defaults.yml')
    save_dir ||= prefs['save_dir']
    base_dir ||= prefs['base_dir']
    base_suffix ||= prefs['base_suffix']
    base_file ||= prefs['base_file']
    base_extras ||= prefs['base_extras']
    prefs_loaded = true
  end


  attr_reader :date_created, :project, :dir, :name
  attr_accessor :tags, :file
  def initialize(project)
    Note.load_preferences unless Note.prefs_loaded
    @date_created = Date.today
    @project = project
    @name = "#{date_created}_#{project}"
    @dir = File.join(Note.save_dir, name)
    @tags = []
    @file = nil
  end

  def add_tag(new_tag)
    @tags << new_tag
    update_record if file
    self
  end

  def remove_tag(tag)
    @tags.delete(tag)
    update_record if file
    self
  end

  def similar_notes(database)
    database.search_by_project_and_tags(project, tags)
  end

  def update_record
    metadata = {
      "date_created" => date_created,
      "project" => project,
      "tags" => tags,
    }
    yml_data = YAML.dump(metadata)
    File.open(File.join(dir, "metadata.yml")) { |f| f.puts(yml_data) }
    self
  end

  def create_file
    self.file = Note.create_note_file(name)
    base_contents = IO.read(file)
    update_record
  end
end

