# OpenLabTools - export script

require "sketchup.rb"
require "fileutils"

def export
  model = Sketchup.active_model

  # Set to front view and save any unsaved changes
  pages = model.pages
  puts pages
  pages.selected_page = pages[0]
  model.modified? || model.save

  # Save script in to Git controlled directory each time it is run
  # This makes it easy to version control the script and helps ensure
  # changes in the script are committed with changes to the output.
  model_path = model.path[/.+\\/] # Path to Sketchup model (in Git repo)
  FileUtils.cp(__FILE__, model_path << "vectors\\")

  # Iterate through components in model and create parts list
  parts_list = File.open( model_path << "parts_list.txt","w" )
  components = model.definitions
  components = components.sort_by { |c| c.name }
  $i = 0
  while $i < components.length do
    c = components[$i]
    unless c.group? || c.hidden?
      parts_list << c.count_instances
      parts_list << "x "
      parts_list <<  c.name
      parts_list << "\n"
    end
    $i +=1
  end
  parts_list.close
  # TODO - export vectors for parts that need machining
end

# Add menu item for running the script
if( not $openlabtools_loaded )
  tool_menu_index = 19 # position to insert menu option
  UI.menu("Tools").add_item("OpenLabTools - Export Vectors") {export}
end
$openlabtools_loaded = true
