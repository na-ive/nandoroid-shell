import os
import shutil

# Get the script's directory (widgets/)
current_dir = os.path.dirname(os.path.abspath(__file__))
# Get the project root (nandoroid/)
root_dir = os.path.dirname(current_dir)

src = os.path.join(root_dir, "example", "modules", "common", "widgets", "shapes")
dst = os.path.join(current_dir, "shapes")

if os.path.exists(dst):
    shutil.rmtree(dst)
shutil.copytree(src, dst)
print("Copied shapes directory.")
