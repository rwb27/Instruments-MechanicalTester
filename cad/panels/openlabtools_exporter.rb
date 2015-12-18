# OpenLabTools - export script
require "sketchup.rb"
require "fileutils"
$rads_2_degs = -57.29578 # Radians to degrees conversion
$inch_2_mm   =  25.4     # Inches to mm conversion

def write_point(p)
  $out_file.puts("10\n  %.3f" % (p.x.to_f * $inch_2_mm))
  $out_file.puts("20\n  %.3f" % (p.y.to_f * $inch_2_mm))
  $out_file.puts("30\n  %.3f" % (p.z.to_f * $inch_2_mm))
end

def write_vertex(v)
  $out_file.puts("  0\nVERTEX\n8\nlayer0")
  write_point(v)
end

def close_polyline()
  $out_file.puts(" 0\nSEQEND") # Close off polyline if open
  $in_polyline = false
end

def export_screenshots_and_save()
  pages = $model.pages
  image_path = $model_path + "renders\\"
  Dir.foreach(image_path) {|f| fn = File.join(image_path, f); File.delete(fn) if f != '.' && f != '..'}
  loop do # Exit any edit instances
    break unless $model.close_active
  end
  i = 0
  pages.each do |page|
    puts "exporting screenshot - " + page.name.downcase.tr(" ","_")
    pages.selected_page = page
    image_name = $model_path + "renders\\" + i.to_s + "_" + page.name.downcase.tr(" ","_")
    $model.active_view.write_image({:filename => image_name + ".png",
      :width => 1280, :height => 720, :antialias => true, :compression => 0.9, :transparent => true})
    $model.active_view.write_image({:filename => image_name + "_small.png",
      :width => 420, :height => 520, :antialias => true, :compression => 0.9, :transparent => true})
    i += 1
  end
  pages.selected_page = pages[0] # Set to front view
  if $model.modified? # Save any unsaved changes
    puts "saving $model"
    $model.save
  end
end

def export_component(c, folder)
  panel_name = c.name[8, c.name.length].downcase.tr(" ","_") # Convert to snake case
  puts "  exporting " << panel_name
  $out_file = File.new(folder + panel_name + ".dxf", "w")
  faces = []
  c.entities.each {|e| (e.is_a?(Sketchup::Face) && faces << e)} # Compile list of faces
  faces = faces.sort_by {|f| f.area} # Sort faces in ascending area
  normal = faces.last.normal # Use largest face normal as local z axis
  t = Geom::Transformation.new([0,0,0], normal)
  $out_file.puts(" 0\nSECTION\n 2\nHEADER\n 9\n$MEASUREMENT\n 70\n 2\n 0\nENDSEC\n 0\nSECTION\n 2\nENTITIES")
  old_curve = 0
  $in_polyline = false
  faces.each do |face|
    unless face.normal.perpendicular? normal
    # if face == faces.last
      face.loops.each do |aloop|
        aloop.edges.each do |anedge|
          $in_polyline && close_polyline
          reversed_edge = anedge.reversed_in? face # Check to see if edge is reversed
          if reversed_edge
            start_point = anedge.end.position.transform! t
            end_point = anedge.start.position.transform! t
          else
            start_point = anedge.start.position.transform! t
            end_point = anedge.end.position.transform! t
          end
          if anedge.curve && anedge.curve.is_a?(Sketchup::ArcCurve) # Could be an arc or a circle
            curve = anedge.curve
            $in_polyline && close_polyline
            if (old_curve != curve) # Check if pointer is for same curve
              centrepoint =  curve.center.transform! t
              if (((curve.end_angle - curve.start_angle) * $rads_2_degs).abs >= 360)
                # Curve is a circle
                $out_file.puts(" 0\nCIRCLE\n8\nlayer0\n66\n1")
                write_point(centrepoint)
                $out_file.puts("40\n  %.3f" % (curve.radius.to_f * $inch_2_mm).to_s)
              else
                # Curve is an arc
                curve_a = curve.edges.first.start.position.transform!(t)
                curve_b = curve.edges[curve.edges.length/2].start.position.transform!(t)
                curve_c = curve.edges.last.end.position.transform!(t)
                angle_a = Math.atan2((curve_a - centrepoint).x, (curve_a - centrepoint).y) * $rads_2_degs
                angle_b = Math.atan2((curve_b - centrepoint).x, (curve_b - centrepoint).y) * $rads_2_degs
                angle_c = Math.atan2((curve_c - centrepoint).x, (curve_c - centrepoint).y) * $rads_2_degs
                a_b = (angle_b - angle_a)
                a_b >  180 && a_b -= 360
                a_b < -180 && a_b += 360
                if (a_b <= 0)
                  start_angle = angle_c
                  end_angle   = angle_a
                else
                  start_angle = angle_a
                  end_angle   = angle_c
                end

                $out_file.puts(" 0\nARC\n8\nlayer0\n66\n1")
                write_point(centrepoint)
                $out_file.puts("40\n  %.3f" % (curve.radius.to_f * $inch_2_mm).to_s)
                $out_file.puts("50\n  %.3f" % (start_angle + 90))
                $out_file.puts("51\n  %.3f" % (end_angle + 90))

              end
            end
            old_curve = curve
          else
            unless $in_polyline
              $out_file.puts(" 0\nPOLYLINE\n8\nlayer0\n66\n1\n70\n8\n")
              write_point([0, 0, 0])
              write_vertex(start_point)
              $in_polyline = true
            end
            write_vertex(end_point)
          end
        end
      end
      $in_polyline && close_polyline
    end
  end
  $out_file.puts(" 0\nENDSEC\n 0\nEOF")
  $out_file.close
end

def export
  SKETCHUP_CONSOLE.clear # Clear the console window
  puts "running OpenLabTools export script"
  $model = Sketchup.active_model
  $model_path = $model.path[/.+cad\\/] # Path to Sketchup $model (in Git repo) - regex matches to final "\"
  export_screenshots_and_save

  # Save script in to Git controlled directory each time it is run
  # This makes it easy to version control the script and helps ensure
  # changes in the script are committed with changes to the output.
  puts "saving export script in version controlled folder"
  FileUtils.cp(__FILE__, $model_path + "panels\\")

  # Clear existing .dxf files so if panel names have changed old files are overwritten
  begin # Ensure there's no open .dxf file
    $out_file.close
  rescue
  end
  puts "deleting old .dxf files"
  dxf_path = $model_path + "panels\\dxf_files\\"
  Dir.foreach(dxf_path) {|f| fn = File.join(dxf_path, f); File.delete(fn) if f != '.' && f != '..'}

  # Open parts list file
  parts_list = File.open($model_path + "panels\\parts_list.txt","w")

  # Iterate through components in $model creating parts list and exporting panel outlines
  puts "creating parts list and exporting panel outlines"
  components = $model.definitions
  components = components.sort_by { |c| c.name }
  i = 0
  while i < components.length do
    c = components[i]
    unless c.group? || c.hidden?
      parts_list << c.count_instances
      parts_list << "x "
      parts_list <<  c.name
      parts_list << "\n"
      c.name[0,8] == 'Panel - ' && export_component(c, dxf_path)
    end
    i += 1
  end
  parts_list.close
  puts "export compete"
end

# Add menu item for running the script
if(not $openlabtools_loaded)
  tool_menu_index = 19 # Position to insert menu option
  UI.menu("Tools").add_item("OpenLabTools - Export Panels") {export}
end
$openlabtools_loaded = true
