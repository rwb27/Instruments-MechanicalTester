import os

print os.getcwd()

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

for x in files:
    open(x, 'a').close()

for x in files:
    f = open(x, 'w')

    f.write("### OpenLabTools Material Tester Documentation\n")
    for z in files:
        if z == x:
            f.write("- **" + titillate(z) + "**\n")
        else:
            f.write("- ["+ titillate(z) + "](\\" + z + ")\n")
    f.write("\n### " + titillate(x) + "\n")
    f.close()
