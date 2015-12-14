# OpenLabTools - export script
require "sketchup.rb"
require "fileutils"
$curve_debug = false
$line_debug  = false

def write_point(p)
  $out_file.puts("10\n  %.3f" % (p.x.to_f * $stl_conv))
  $out_file.puts("20\n  %.3f" % (p.y.to_f * $stl_conv))
  $out_file.puts("30\n  %.3f" % (p.z.to_f * $stl_conv))
end

def export_component(c, folder)
  panel_name = c.name[8, c.name.length].downcase.tr(" ","_") # Convert to snake case
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
  $out_file.puts(" 0\nSECTION\n 2\nHEADER\n 9\n$MEASUREMENT\n 70\n 2\n 0\nENDSEC\n 0\nSECTION\n 2\nENTITIES")
  old_curve = 0
  $face_count = 0
  $line_count = 0
  $arc_count = 0
  $circle_count = 0
  in_polyline = false
  faces.each do |face|
    unless face.normal.perpendicular? normal
      $face_count += 1
      face.loops.each do |aloop|
        aloop.edges.each do |anedge|
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
            centrepoint =  curve.center.transform! t
            # The arc angles are relative to local arc x axis
            x_axis_angle = Math.atan2(anedge.curve.xaxis.transform!(t).x,
                                      anedge.curve.xaxis.transform!(t).y)
            y_axis_angle = Math.atan2(anedge.curve.yaxis.transform!(t).x,
                                      anedge.curve.yaxis.transform!(t).y)
            start_angle = (curve.start_angle - x_axis_angle).to_f * 57.29578 + 90
            end_angle   = (curve.end_angle   - x_axis_angle).to_f * 57.29578 + 90
            if in_polyline
              $out_file.puts(" 0\nSEQEND") # Close off polyline if open
              in_polyline = false
              $line_debug && puts("    close")
            end
            if (old_curve != curve) # Check if pointer is for same curve
              if (end_angle - start_angle >= 360) # Identify a circle - total angle = 2 pi radians
                $out_file.puts(" 0\nCIRCLE\n8\nlayer0\n66\n1")
                write_point(centrepoint)
                $out_file.puts("40\n  "+(curve.radius.to_f * $stl_conv).to_s)
                $circle_count += 1
              else
                $curve_debug && puts("    ARC " << centrepoint.to_s)
                reversed_curve   = (curve.normal.transform!(t) == face.normal.transform!(t).reverse)
                reversed_curve_2 = (curve.normal.transform!(t) == normal.transform!(t).reverse)
                reversed_face    = (face.normal.transform!(t) == normal.transform!(t).reverse)
                $curve_debug && reversed_edge  && puts("    REVERSED EDGE")
                $curve_debug && reversed_curve && puts("    REVERSED CURVE")
                $curve_debug && reversed_curve && puts("    REVERSED CURVE 2")
                $curve_debug && reversed_face  && puts("    REVERSED FACE")
                flip = false
                (reversed_edge)  &&  (reversed_face)   && flip = true
                !(reversed_edge) &&  (reversed_curve)  && (reversed_curve_2)   && !(reversed_face) && flip = true
                if flip
                  $curve_debug && puts("    FLIPPING CURVE")
                  new_end_angle = start_angle
                  start_angle = start_angle + (start_angle - end_angle)
                  end_angle = new_end_angle
                end
                $out_file.puts(" 0\nARC\n8\nlayer0\n66\n1")
                write_point(centrepoint)
                $out_file.puts("40\n  "+(curve.radius.to_f * $stl_conv).to_s)
                $out_file.puts("50\n  %.3f" % start_angle)
                $out_file.puts("51\n  %.3f" % end_angle)
                $arc_count += 1
                old_start_angle = curve.start_angle.to_f * 57.29578 + 90
                old_end_angle   = curve.end_angle.to_f * 57.29578 + 90
                $curve_debug && puts("    x axis - x %.3f" % anedge.curve.xaxis.x.to_s)
                $curve_debug && puts("    x axis - y %.3f" % anedge.curve.xaxis.y.to_s)
                $curve_debug && puts("    x axis - z %.3f" % anedge.curve.xaxis.z.to_s)
                $curve_debug && puts("    y axis - x %.3f" % anedge.curve.yaxis.x.to_s)
                $curve_debug && puts("    y axis - y %.3f" % anedge.curve.yaxis.y.to_s)
                $curve_debug && puts("    y axis - z %.3f" % anedge.curve.yaxis.z.to_s)
                $curve_debug && puts("    x_axis     %.3f" % (x_axis_angle * 57.29578))
                $curve_debug && puts("    y_axis     %.3f" % (y_axis_angle * 57.29578))
                $curve_debug && puts("    old_start  %.3f" % old_start_angle)
                $curve_debug && puts("    old_end    %.3f" % old_end_angle)
                $curve_debug && puts("    start      %.3f" % start_angle)
                $curve_debug && puts("    end        %.3f" % end_angle)
                $curve_debug && puts("")
              end
            end
            old_curve = curve
            in_polyline = false
          else
            unless in_polyline
              $line_debug && puts("    start polyline")
              $out_file.puts(" 0\nPOLYLINE\n8\nlayer0\n66\n1\n70\n8\n")
              $out_file.puts("10\n  0.0\n20\n  0.0\n30\n  0.0\n  0\nVERTEX\n8\nlayer0")
              write_point(start_point)
              $line_debug && puts("      " << start_point.to_s)
              in_polyline = true
            end
            $out_file.puts("0\nVERTEX\n8\nlayer0")
            write_point(end_point)
            $line_debug && puts("      " << end_point.to_s)
            $line_count += 1
          end
        end
      end
      in_polyline && $out_file.puts(" 0\nSEQEND") # Close off polyline if open
      in_polyline && $line_debug && puts("      close")
    end
  end
  $out_file.puts(" 0\nENDSEC\n 0\nEOF")
  $out_file.close
  $face_count   != 0 && puts("    " + $face_count.to_s   + " faces exported")
  $line_debug && $line_count   != 0 && puts("    " + $line_count.to_s   + " lines exported")
  $curve_debug && $arc_count    != 0 && puts("    " + $arc_count.to_s    + " arcs exported")
  $curve_debug && $circle_count != 0 && puts("    " + $circle_count.to_s + " circles exported")
end

def export
  SKETCHUP_CONSOLE.clear
  defined? $out_file && $out_file.close


  puts "running OpenLabTools export script"
  model = Sketchup.active_model

  # Set to front view and save any unsaved changes
  pages = model.pages
  pages.selected_page = pages[0]
  # Exit any edit instances
  loop do
    break unless model.close_active
  end
  if model.modified?
    model.save
    puts "saving model"
  end

  # Save script in to Git controlled directory each time it is run
  # This makes it easy to version control the script and helps ensure
  # changes in the script are committed with changes to the output.
  puts "saving export script in version controlled folder"
  model_path = model.path[/.+\\/] # Path to Sketchup model (in Git repo)
  FileUtils.cp(__FILE__, model_path << "panels\\")
  # Open parts list file
  parts_list = File.open(model_path + "parts_list.txt","w")
  # Clear existing .dxf files so if panel names have changed old files are overwritten
  puts "deleting old .dxf files"
  model_path << "dxf_files\\"
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
