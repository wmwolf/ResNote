require 'Date'
require 'FileUtils'
require 'YAML'

class Note
  MONTHS = {
    1 => "January",
    2 => "February",
    3 => "March",
    4 => "April",
    5 => "May",
    6 => "June",
    7 => "July",
    8 => "August",
    9 => "September",
    10 => "October",
    11 => "November",
    12 => "December"
  }
  @notes_dir = File.join(ENV['HOME'], 'Dropbox', 'Research_Journal', 'Notes')
  @projects_dir = File.join(ENV['HOME'],'Dropbox','Research_Journal','Projects')
  @tags_dir = File.join(ENV['HOME'], 'Dropbox', 'Research_Journal', 'Tags')
  @base_dir = File.join(@notes_dir, 'base')
  @base_suffix = '.tex'
  @base_file = File.join('base', @base_suffix)
  @base_extras = []
  @prefs_loaded = false
  @to_replace = [
    ['REPLACE_DAY_CREATED', Date.today.day],
    ['REPLACE_MONTH_CREATED', MONTHS[Date.today.month]],
    ['REPLACE_YEAR_CREATED', Date.today.year]
  ]
  class << self
    attr_accessor :notes_dir, :projects_dir, :tags_dir, :base_suffix, 
      :base_file, :base_extras, :prefs_loaded, :to_replace
  end

  def self.create_note_file(name)
    # make new directory
    new_dir = note_dir(name)
    new_file = "#{name}.#{base_suffix}"
    FileUtils.mkdir_p new_dir
    # copy base file over
    FileUtils.cp File.join(base_dir, base_file), File.join(new_dir, new_file)
    # copy extra files over
    base_extras.each { |extra| FileUtils.cp File.join(base_dir, extra) new_dir }
    File.join(new_dir, new_file)
  end

  def self.note_dir(name)
    File.join(notes_dir, name)
  end

  def self.load_preferences
    pref_file = File.join(ENV['HOME'], '.ResNote', 'prefs.yml')
    return unless File.exist?(pref_file)
    prefs = YAML.load(IO.read(pref_file))
    notes_dir ||= prefs['notes_dir']
    projects_dir ||= prefs['projects_dir']
    tags_dir ||= prefs['tags_dir']
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
    @project.add_note(self)
    @name = "#{date_created}_#{project}"
    @dir = File.join(Note.notes_dir, name)
    @tags = []
    @file = nil
  end

  def add_tag(new_tag)
    @tags << new_tag unless tags.include?(new_tag)
    new_tag.add_note(self)
    update_record if file
    self
  end

  def remove_tag(tag)
    @tags.delete(tag)
    tag.remove_note(self)
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
    File.open(File.join(dir, "metadata.yml"), 'w') { |f| f.puts yml_data }
    self
  end

  def create_file
    self.file = Note.create_note_file(name)
    base_contents = IO.read(file)
    Note.to_replace.each { |rep| base_contents.gsub!(rep[0], rep[1]) }
    File.open(self.file, 'w') { |f| f.puts(base_contents) }
    update_record
    self
  end

  def delete
    tags.each { |tag| tag.remove_note(self) }
    project.remove_note(self)
    FileUtils.rm_r dir
  end

  def open
    system("#{ENV['EDITOR']} #{file}")
  end
end

