# install GPU replated packages for raspberry pi system
sudo apt-get install gpsd gpsd-clients
sudo apt install python3-picamera2
sudo apt-get install python3-opencv

# open venv and install required libraries
python -m venv venv --system-site-packages
source venv/bin/activate
pip install -r requirements.txt

