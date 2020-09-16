import cdsapi
import yaml

with open('.adsapirc', 'r') as f:
    credentials = yaml.safe_load(f)

c = cdsapi.Client(url=credentials['url'], key=credentials['key'])

c.retrieve(
    'cams-europe-air-quality-forecasts',
    {
        'model': 'ensemble',
        'date': '2020-01-01/2020-05-31',
        'format': 'grib',
        'variable': 'particulate_matter_2.5um',
        'level': '0',
        'time': [
            '00:00', '01:00', '02:00',
            '03:00', '04:00', '05:00',
            '06:00', '07:00', '08:00',
            '09:00', '10:00', '11:00',
            '12:00', '13:00', '14:00',
            '15:00', '16:00', '17:00',
            '18:00', '19:00', '20:00',
            '21:00', '22:00', '23:00',
        ],
        'type': 'analysis',
        'leadtime_hour': '0',
    },
    'cds-cams-pm2pt5-hourly.grib')
