#!/bin/bash

# If any command fails, the script will exit immediately
set -e

# Could be prod,dev,staging,local?
installation_name=test-install
app_user=test-install

# Name of the service being deployed
app_name=postgres

# System user that will run the docker containers
docker_user=dockertestusr

# Root directory where all container data will be stored
containers_data_base_path=/srv/containers_data

# Temporary directory where the git repository will be cloned before copying the dockerfiles to the final destination
checkout_directory=/home/$docker_user/$installation_name/checkout

# Final directory where the dockerfiles will be copied to and where the docker compose commands will be run
dockerfiles_directory=/home/$docker_user/$installation_name/$app_name

# Final directory where the application data will be stored
storage_directory=$containers_data_base_path/$installation_name/storage/$app_name
# Path to the .env file
env_file=$dockerfiles_repo_directory/.env
# Name of the variable in the .env file that needs to be updated with the correct storage directory path
variable_name="POSTGRES_DB_VOLUME_BASE_PATH"

# Name of directory where docker files are stored in the git repository
dockerfiles_repo_directory=docker-files

# Git repository URL
repo_url=https://github.com/GiovanniCapocci/test-dev.git

echo "Making sure the checkout directory doesn't exist before cloning"
sudo -u $docker_user rm -rf $checkout_directory

echo "Attempting git clone"



sudo -u $docker_user git clone $repo_url $checkout_directory
echo "Git clone completed"

# Updating .env POSTGRES_DB_VOLUME_BASE_PATH variable with the correct storage directory path
echo "Updating .env POSTGRES_DB_VOLUME_BASE_PATH variable with the correct storage directory path"
# Check if the variable exists in the .env file, if it does, update it, if not, add it
if grep -q "${variable_name}=" "$env_file"; then
    sed -i "s|^${variable_name}.*|${variable_name}=${storage_directory}|" "$env_file"
    echo "Updated ${variable_name} in .env file to ${storage_directory}"
else
    echo "${variable_name} not found in .env file. Adding it."
    echo "${variable_name}=${storage_directory}" >> "$env_file"
fi

echo "Attempting to clone config files to: $dockerfiles_directory"
if [ -d "$dockerfiles_directory" ]; then
    echo "Directory $dockerfiles_directory already exists. Removing it."
    sudo -u $docker_user rm -r $dockerfiles_directory
fi

echo "Creating directory $dockerfiles_directory"
sudo -u $docker_user mkdir -p $dockerfiles_directory

echo "Cloning config files..."
sudo -u $docker_user cp -r $checkout_directory/$dockerfiles_repo_directory/. $dockerfiles_directory

echo "Changing into directory $dockerfiles_directory and running docker compose commands"
cd $dockerfiles_directory
docker compose pull
docker compose down
docker compose -d --build


echo "Removing checkout directory: $checkout_directory"
sudo -u $docker_user rm -rf $checkout_directory