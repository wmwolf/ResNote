require 'Date'
require 'FileUtils'
require 'YAML'

class Project
  @projects_dir = File.join(ENV['HOME'], 'Dropbox', 'Research_Journal', 'Projects')
  @notes_dir = File.join(ENV['HOME'], 'Dropbox', 'Research_Journal', 'Notes')
  @prefs_loaded = false
  class << self
    attr_accessor :projects_dir, :notes_dir, :prefs_loaded
  end

  def self.load_preferences
    pref_file = File.join(ENV['HOME'], '.ResNote', 'prefs.yml')
    return unless File.exist?(pref_file)
    prefs = YAML.load(IO.read(pref_file))
    notes_dir ||= prefs['notes_dir']
    projects_dir ||= prefs['projects_dir']
    prefs_loaded = true
  end

  def self.load(name)
    unless Dir.entries(projects_dir).include?(name)
      raise("Cannot find project #{name} in projects directory: " +
        "#{projects_dir}.")
    metadata = YML.load(IO.read(File.join(projects_dir, name)))
    proj = Project.new(name)
    proj.set_created_date metadata['date_created']
    metadata['notes'].each do |note|
      new_note = Note.load(note)
      proj.add_note(new_note)
    end

  attr_reader :name, :date_created, :notes, :dir
  def initialize(name)
    Project.load_preferences unless Project.prefs_loaded
    @name = name
    @date_created = Date.today
    @dir = File.join(Project.projects_dir, name)
    @notes = []
    @dir_made = false
  end

  def add_note(new_note)
    @notes << new_note unless @notes.include?(new_note)
    update_record if @dir_made
  end

  def remove_note(note)
    @notes.delete(note)
    update_record if @dir_made
  end

  def update_record
    metadata = {
      'name' => name
      'date_created' => date_created
      'notes' => notes
    }
    yml_data = YAML.dump(metadata)
    File.open(File.join(dir, 'metadata.yml'), 'w') { |f| f.puts yml_data }
  end

  def make_dir
    FileUtils.mkdir_p dir unless @dir_made
    @dir_made = true
    update_record
  end

  def load

