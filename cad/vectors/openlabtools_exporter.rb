# OpenLabTools - export script
require "sketchup.rb"
require "fileutils"

def write_point(p)
  $out_file.puts("10\n  "+(p.x.to_f * $stl_conv).to_s)
  $out_file.puts("20\n  "+(p.y.to_f * $stl_conv).to_s)
  $out_file.puts("30\n  "+(p.z.to_f * $stl_conv).to_s)
end

def export_component(c, folder)
  panel_name = c.name[8, c.name.length]
  puts "  exporting " << panel_name
  $stl_conv = 25.4 # Inches to mm conversion
  $out_file = File.new(folder + panel_name + ".dxf", "w")
  faces = []
  c.entities.each do |e|
    e.is_a?(Sketchup::Face) && faces << e
  end
  faces = faces.sort_by { |f| f.area }
  normal = faces.last.normal # Use largest face normal as local z axis
  t = Geom::Transformation.new([0,0,0], normal)
  $out_file.puts("0\nSECTION\n2\nHEADER\n9\nMEASUREMENT\n70\n2\n0\nENDSEC\n0\nSECTION\n2\nENTITIES")

  old_curve = 0
  $face_count = 0
  $line_count = 0
  $arc_count = 0
  $circle_count = 0
  new_polyline = true
  faces.each do |face|
    unless face.normal.perpendicular? normal
      $face_count += 1
      face.loops.each do |aloop|
        aloop.edges.each do |anedge|
          if anedge.curve && anedge.curve.is_a?(Sketchup::ArcCurve) # Could be an arc or a circle
            curve = anedge.curve
            centrepoint =  curve.center.transform! t
            # The arc angles are relative to local arc x axis
            x_axis_angle = Math.atan2(anedge.curve.xaxis.transform!(t).x, anedge.curve.xaxis.transform!(t).y)
            start_angle = curve.start_angle - x_axis_angle
            end_angle = curve.end_angle - x_axis_angle
            new_polyline || $out_file.puts("  0\nSEQEND") # Close off polyline if open

            if (old_curve != curve) # Check if pointer is for same curve
              if (end_angle - start_angle > 6.2831) # Identify a circle - total angle = 2 pi radians
                $out_file.puts("0\nCIRCLE\n8\nlayer0\n66\n1")
                write_point(centrepoint)
                $out_file.puts("40\n  "+(curve.radius.to_f * $stl_conv).to_s)
                $circle_count += 1
              else
                $out_file.puts("0\nARC\n8\nlayer0\n66\n1")
                write_point(centrepoint)
                $out_file.puts("40\n  "+(curve.radius.to_f * $stl_conv).to_s)
                $out_file.puts("50\n  "+(start_angle.to_f / 3.142 * 180 + 90).to_s)
                $out_file.puts("51\n  "+(end_angle.to_f / 3.142 * 180 + 90).to_s)
                $arc_count += 1
              end
            end
            old_curve = curve
            new_polyline = true
          else
            if (new_polyline)
              start_point = anedge.end.position.transform! t
              $out_file.puts("0\nPOLYLINE\n8\nlayer0\n66\n1\n70\n8\n")
              $out_file.puts("10\n  0.0\n20\n  0.0\n30\n  0.0\n  0\nVERTEX\n8\nlayer0")
                write_point(start_point)
              new_polyline = false
            end
              end_point = anedge.start.position.transform! t
              $out_file.puts("0\nVERTEX\n8\nlayer0")
                write_point(end_point)
              $line_count += 1
          end
        end
        if (!new_polyline)
           $out_file.puts("  0\nSEQEND")
        end
      end
    end
  end
  $out_file.puts(" 0\nENDSEC\n 0\nEOF")
  $out_file.close
  $face_count   != 0 && puts("    " + $face_count.to_s   + " faces exported")
  $line_count   != 0 && puts("    " + $line_count.to_s   + " lines exported")
  $arc_count    != 0 && puts("    " + $arc_count.to_s    + " arcs exported")
  $circle_count != 0 && puts("    " + $circle_count.to_s + " circles exported")
end

def export
  puts "\n\nrunning OpenLabTools export script"
  model = Sketchup.active_model

  # Set to front view and save any unsaved changes
  puts "saving model"
  pages = model.pages
  pages.selected_page = pages[0]
  # TODO Exit any edit instances
  model.modified? || model.save

  # Save script in to Git controlled directory each time it is run
  # This makes it easy to version control the script and helps ensure
  # changes in the script are committed with changes to the output.
  puts "saving export script in version controlled folder"
  model_path = model.path[/.+\\/] # Path to Sketchup model (in Git repo)
  FileUtils.cp(__FILE__, model_path << "vectors\\")
  # Open parts list file
  parts_list = File.open(model_path + "parts_list.txt","w")
  # Clear existing .dxf files so if panel names have changed old files are overwritten
  puts "deleting old .dxf files"
  model_path << "panels\\"
  Dir.foreach(model_path) {|f| fn = File.join(model_path, f); File.delete(fn) if f != '.' && f != '..'}

  # Iterate through components in model creating parts list and exporting panel outlines
  puts "creating parts list and exporting panel outlines"
  components = model.definitions
  components = components.sort_by { |c| c.name }
  i = 0
  while i < components.length do
    c = components[i]
    unless c.group? || c.hidden?
      parts_list << c.count_instances
      parts_list << "x "
      parts_list <<  c.name
      parts_list << "\n"
      c.name[0,8] == 'Panel - ' && export_component(c, model_path)
    end
    i +=1
  end
  parts_list.close
  puts "export compete"
end

# Add menu item for running the script
if(not $openlabtools_loaded)
  tool_menu_index = 19 # Position to insert menu option
  UI.menu("Tools").add_item("OpenLabTools - Export Vectors") {export}
end
$openlabtools_loaded = true
