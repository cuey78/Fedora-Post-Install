#!/usr/bin/python3
import os
import subprocess
import sys

# Function to clone a git repository
def clone_repo(repo_url, clone_dir):
    if not os.path.exists(clone_dir):
        subprocess.run(["git", "clone", "depth=1", repo_url, clone_dir])
    else:
        print(f"Directory {clone_dir} already exists. Pulling latest changes.")
        original_dir = os.getcwd()
        os.chdir(clone_dir)
        subprocess.run(["git", "pull"])
        os.chdir(original_dir)

# Function to run a script from the cloned repository
def run_script(script_path):
    if os.path.exists(script_path):
        subprocess.run(["bash", script_path])  # Assuming it's a bash script
    else:
        print(f"Script {script_path} does not exist.")

# Main function
def main():
    repo_url = "https://github.com/cuey78/fedora-post-install"  # Replace with your repository URL
    clone_dir = "Fedora-post-install"  # Directory to clone the repo into
    script_path = os.path.join(clone_dir, "main.sh")  # Path to the script to run

    clone_repo(repo_url, clone_dir)

      # Change back to original directory
    os.chdir(clone_dir)

    # Make main.sh executable
    os.chmod("main.sh", 0o755)

    # Execute main.sh as root
    subprocess.run(["sudo", "./main.sh"])

if __name__ == "__main__":
    main()
