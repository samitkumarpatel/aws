mkdir app

cd app/

wget https://download.java.net/openjdk/jdk21/ri/openjdk-21+35_linux-x64_bin.tar.gz

tar -xzvf openjdk-21+35_linux-x64_bin.tar.gz 

wget https://github.com/samitkumarpatel/hello-world/releases/download/v1.0.20/hello-world-1.0.0-SNAPSHOT.jar

./jdk-21/bin/java --version

./jdk-21/bin/java -jar ./hello-world-1.0.0-SNAPSHOT.jar 

sudo yum install amazon-cloudwatch-agent

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard 

sudo ./amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Change If any missing config on config.json file
sudo ./amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
