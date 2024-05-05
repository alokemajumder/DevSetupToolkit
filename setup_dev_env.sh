#!/bin/bash

# This script sets up development environments for Python, Node.js, Java, C++, Ruby, and PHP.
# It also provides options to install IDEs, databases, and web servers for PHP applications.
# Usage: Run this script as root or using sudo. Customize installations by following the prompts.

# Author: Aloke Majumder
# GitHub: https://github.com/alokemajumder
# License: MIT License

# DISCLAIMER:
# This script is provided "AS IS" without warranty of any kind, express or implied. The author expressly disclaims any and all warranties, 
# express or implied, including any warranties as to the usability, suitability or effectiveness of any methods or measures this script 
# attempts to apply. By using this script, you agree that the author shall not be held liable for any damages resulting from the use of this script.

# Function to detect the Linux distribution and set package manager

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        echo "Cannot detect Linux distribution."
        exit 1
    fi

    case $DISTRO in
        ubuntu|debian)
            PKG_MANAGER="apt-get"
            ;;
        fedora|centos)
            PKG_MANAGER="dnf"
            ;;
        *)
            echo "Distribution not supported by this script."
            exit 1
            ;;
    esac
}

# Function to update the package manager
update_system() {
    echo "Updating package manager..."
    $PKG_MANAGER update -y
}

# Function to check if a package is installed
is_installed() {
    if command -v $1 &> /dev/null
    then
        return 0  # 0 = true
    else
        return 1  # 1 = false
    fi
}

# Function to install and configure Python environment
install_python() {
    echo "Installing Python..."
    $PKG_MANAGER install python3 python3-venv python3-pip -y
    pip3 install virtualenv
    echo "export PATH=\"$PATH:/usr/local/bin/python3\"" >> ~/.bashrc
    source ~/.bashrc
    echo "Python configured with PATH."
}

# Function to install and configure Node.js environment including optional packages
install_nodejs() {
    echo "Installing Node.js..."
    $PKG_MANAGER install nodejs npm -y

    # Optionally install yarn
    read -p "Do you want to install Yarn? (y/n): " install_yarn
    if [[ "$install_yarn" =~ ^[Yy]$ ]]; then
        npm install -g yarn
        echo "Yarn installed."
    fi

    # Optionally install React.js
    read -p "Do you want to install React.js? (y/n): " install_react
    if [[ "$install_react" =~ ^[Yy]$ ]]; then
        npm install -g create-react-app
        echo "React.js installed."
    fi

    # Optionally install Next.js
    read -p "Do you want to install Next.js? (y/n): " install_next
    if [[ "$install_next" =~ ^[Yy]$ ]]; then
        npm install -g next
        echo "Next.js installed."
    fi

    # Optionally install TypeScript
    read -p "Do you want to install TypeScript? (y/n): " install_ts
    if [[ "$install_ts" =~ ^[Yy]$ ]]; then
        npm install -g typescript
        echo "TypeScript installed."
    fi

    # Optionally install Tailwind CSS
    read -p "Do you want to install Tailwind CSS? (y/n): " install_tailwind
    if [[ "$install_tailwind" =~ ^[Yy]$ ]]; then
        npm install -g tailwindcss
        echo "Tailwind CSS installed."
    fi

    echo "Node.js and selected packages have been installed and configured."
}

# Function to install and configure Java environment
install_java() {
    echo "Installing Java..."
    $PKG_MANAGER install java-11-openjdk java-11-openjdk-devel -y
    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
    echo "export PATH=$PATH:$JAVA_HOME/bin" >> ~/.bashrc
    source ~/.bashrc
    echo "Java configured with JAVA_HOME and PATH."
}

# Function to install and configure C++ environment
install_cpp() {
    echo "Installing C++ compilers and tools..."
    $PKG_MANAGER install gcc g++ gdb -y
    echo "C++ tools installed and configured."
}

# Function to install and configure Ruby environment
install_ruby() {
    echo "Installing Ruby using RVM..."
    curl -sSL https://get.rvm.io | bash -s stable
    source /etc/profile.d/rvm.sh
    rvm install ruby
    echo "Ruby configured using RVM."
}

# Function to install and configure PHP with optional web server choices
install_php() {
    # Check if PHP is installed
    if is_installed php; then
        echo "PHP is already installed."
    else
        echo "Installing PHP..."
        $PKG_MANAGER install php php-cli php-fpm php-mysql -y
        # Choose the web server
        read -p "Do you want to use Apache or Nginx for PHP? (apache/nginx): " web_server
        case $web_server in
            apache)
                $PKG_MANAGER install apache2 -y
                systemctl start apache2
                systemctl enable apache2
                echo "Apache installed and configured for PHP."
                ;;
            nginx)
                $PKG_MANAGER install nginx -y
                systemctl start nginx
                systemctl enable nginx
                echo "Nginx installed and configured for PHP."
                ;;
            *)
                echo "No valid web server selected, PHP installed without web server configuration."
                ;;
        esac
    fi

    # Optionally install MySQL and phpMyAdmin
    if ! is_installed mysql; then
        read -p "Do you want to install MySQL and phpMyAdmin? (y/n): " install_mysql_phpmyadmin
        if [[ "$install_mysql_phpmyadmin" =~ ^[Yy]$ ]]; then
            $PKG_MANAGER install mysql-server phpmyadmin -y
            systemctl start mysql
            systemctl enable mysql
            echo "MySQL and phpMyAdmin installed. Please configure phpMyAdmin manually."
            echo "Running mysql_secure_installation..."
            mysql_secure_installation
        fi
    fi
}

# Function to install IDEs
install_ide() {
    echo "Installing IDEs..."
    case $IDE_CHOICE in
        vscode)
            snap install --classic code
            ;;
        jetbrains)
            snap install --classic pycharm-community
            ;;
        *)
            echo "No IDE installation selected."
            ;;
    esac
}

# Function to install and configure databases
install_database() {
    echo "Database installation options:"
    
    # Install MySQL
    read -p "Do you want to install MySQL? (y/n): " install_mysql
    if [[ "$install_mysql" =~ ^[Yy]$ ]]; then
        $PKG_MANAGER install mysql-server -y
        systemctl start mysql
        systemctl enable mysql
        echo "MySQL installed and started."
        
        # Prompt to run mysql_secure_installation
        read -p "Do you want to secure MySQL now using mysql_secure_installation? (y/n): " secure_mysql
        if [[ "$secure_mysql" =~ ^[Yy]$ ]]; then
            echo "Running mysql_secure_installation..."
            mysql_secure_installation
        else
            echo "You can run 'mysql_secure_installation' manually later to secure MySQL."
        fi
    fi

    # Install PostgreSQL
    read -p "Do you want to install PostgreSQL? (y/n): " install_pgsql
    if [[ "$install_pgsql" =~ ^[Yy]$ ]]; then
        $PKG_MANAGER install postgresql postgresql-server -y
        systemctl start postgresql
        systemctl enable postgresql
        sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
        echo "PostgreSQL installed and started. Password for 'postgres' user set to 'postgres'."
    fi

    # Install MongoDB
    read -p "Do you want to install MongoDB? (y/n): " install_mongo
    if [[ "$install_mongo" =~ ^[Yy]$ ]]; then
        $PKG_MANAGER install mongodb-org -y
        systemctl start mongod
        systemctl enable mongod
        echo "MongoDB installed and started."
    fi

    # Install Redis
    read -p "Do you want to install Redis? (y/n): " install_redis
    if [[ "$install_redis" =~ ^[Yy]$ ]]; then
        $PKG_MANAGER install redis -y
        systemctl start redis
        systemctl enable redis
        echo "Redis installed and started."
    fi

    echo "Selected databases have been installed and configured."
}

# Main script starts here
detect_distro
read -p "Which IDE do you want to install? (vscode/jetbrains/none): " IDE_CHOICE

update_system
install_python
install_nodejs
install_java
install_cpp
install_ruby
install_php
install_ide

# Ask to install databases after setting up other environments
read -p "Do you want to proceed with database installation? (y/n): " db_install
if [[ "$db_install" =~ ^[Yy]$ ]]; then
    install_database
fi

echo "All selected environments, tools, and databases have been installed and configured."
