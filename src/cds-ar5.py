import cdsapi

c = cdsapi.Client()

c.retrieve(
    'ecv-for-climate-change',
    {
        'format': 'zip',
        'origin': 'era5',
        'month': [
            '01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
        ],
        'year': [
            '2019', '2020',
        ],
        'time_aggregation': '1_month',
        'product_type': 'monthly_mean',
        'variable': [
            'surface_air_relative_humidity', 'surface_air_temperature',
        ],
    },
    'cds-ar5.zip')
