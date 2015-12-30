import os
title = "OpenLabTools Materials Tester Documentation"
files = [
    "00-getting_started.md",
    "01-sourcing_components.md",
    "02-cutting_panels.md",
    "03-assembly-01_front_enclosure.md",
    "03-assembly-02_rear_face.md",
    "03-assembly-03_rear_module.md",
    "03-assembly-04_electronics.md",
    "03-assembly-05_motors.md",
    "04-installing_software.md",
    "05-commissioning.md",
    "06-designing_an_experiment.md",
    "07-running_an_experiment.md",
    "08-maintenance.md",
    "09-customisation.md",
    "10-performance.md"]
comment_end = "END TITLE BLOCK"


def commentate(x):
    return "\n[//]: # (" + x + ")\n"


def navigate(f):
    t = "### %s\n" % title
    for z in files:
        if z == x:
            t += "- **" + titillate(z) + "**\n"
        else:
            t += "- [" + titillate(z) + "](\\" + z + ")\n"
    t += "\n### %s\n" % titillate(x)
    t += commentate(comment_end)
    return t


def titillate(x):
    t = ""
    layers = x.split('.md')[0].split("-")[1:]
    if len(layers) == 1:
        t += layers[0].replace('_', ' ').title()
    else:
        t += layers[0].replace('_', ' ').title()
        t += " Step "
        words = layers[1].split('_')
        t += words[0].title()
        t += " -"
        for w in words[1:]:
            t += " "
            t += w.title()
    return t

if __name__ == "__main__":
    print "checking for unlisted doc files"
    current_files = os.listdir(os.getcwd())
    for x in current_files:
        if x[-3:] == ".md" and x not in files:
            print "  %s not in file list - removing" % x
            os.remove(x)
    for x in files:
        content = ""
        if os.path.isfile(x):
            with open(x, 'r+') as f:
                content = f.read().split(commentate(comment_end))[1]
                f.seek(0)
                f.write(navigate(x))
                f.write(content)
                f.truncate()
        else:
            with open(x, 'w') as f:
                f.write(navigate(x))
                f.write(content)
    print "complete"
