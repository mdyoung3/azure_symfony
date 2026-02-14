#! /bin/bash
sudo apt update
sudo apt install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
sudo cat > /var/www/html/index.html << WEBSITE
<html>
<head>
    <title>From the edge of the Jellobelt - ${environment}</title>
</head>
<body>
<p style="text-align:center;">Welcome to the Edge of the Jellobelt  - ${environment}</p>
</body>
</html>
WEBSITE
