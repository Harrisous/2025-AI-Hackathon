import gpsd
import time
from datetime import datetime

# 连接到本地的GPSD服务
gpsd.connect()

class GPS:
    def __init__(self):
        pass
    
    def get_location(self):
        try:
            packet = gpsd.get_current()
            formatted_time = datetime.now().strftime("%Y-%m-%d+%H-%M")
            if packet.mode >= 2:  # 有效定位（2D/3D fix）
                print('time', formatted_time)
                print('Latitude:', packet.lat)
                print('Longitude:', packet.lon)
            else:
                print('No fix yet, retry...')
        except Exception as e:
            print('Error reading GPS data:', e)

if __name__ == '__main__':
    gps = GPS()
    while True:
        gps.get_location()
        time.sleep(1)
