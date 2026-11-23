-- Populate the states table with the 50 states, DC and Puerto Rico.
-- Census regions and divisions follow the Census Bureau classifications.
-- Puerto Rico is not assigned a region or division.

USE consumer_complaints;

-- Clear existing records before inserting the state list.
DELETE FROM states;

INSERT INTO states (state_code, state_abbreviation, state_name, census_region, census_division) VALUES
-- Northeast
('09', 'CT', 'Connecticut',          'Northeast', 'New England'),
('23', 'ME', 'Maine',                'Northeast', 'New England'),
('25', 'MA', 'Massachusetts',        'Northeast', 'New England'),
('33', 'NH', 'New Hampshire',        'Northeast', 'New England'),
('44', 'RI', 'Rhode Island',         'Northeast', 'New England'),
('50', 'VT', 'Vermont',              'Northeast', 'New England'),
('34', 'NJ', 'New Jersey',           'Northeast', 'Middle Atlantic'),
('36', 'NY', 'New York',             'Northeast', 'Middle Atlantic'),
('42', 'PA', 'Pennsylvania',         'Northeast', 'Middle Atlantic'),

-- Midwest
('17', 'IL', 'Illinois',             'Midwest', 'East North Central'),
('18', 'IN', 'Indiana',              'Midwest', 'East North Central'),
('26', 'MI', 'Michigan',             'Midwest', 'East North Central'),
('39', 'OH', 'Ohio',                 'Midwest', 'East North Central'),
('55', 'WI', 'Wisconsin',            'Midwest', 'East North Central'),
('19', 'IA', 'Iowa',                 'Midwest', 'West North Central'),
('20', 'KS', 'Kansas',               'Midwest', 'West North Central'),
('27', 'MN', 'Minnesota',            'Midwest', 'West North Central'),
('29', 'MO', 'Missouri',             'Midwest', 'West North Central'),
('31', 'NE', 'Nebraska',             'Midwest', 'West North Central'),
('38', 'ND', 'North Dakota',         'Midwest', 'West North Central'),
('46', 'SD', 'South Dakota',         'Midwest', 'West North Central'),

-- South
('10', 'DE', 'Delaware',             'South', 'South Atlantic'),
('11', 'DC', 'District of Columbia', 'South', 'South Atlantic'),
('12', 'FL', 'Florida',              'South', 'South Atlantic'),
('13', 'GA', 'Georgia',              'South', 'South Atlantic'),
('24', 'MD', 'Maryland',             'South', 'South Atlantic'),
('37', 'NC', 'North Carolina',       'South', 'South Atlantic'),
('45', 'SC', 'South Carolina',       'South', 'South Atlantic'),
('51', 'VA', 'Virginia',             'South', 'South Atlantic'),
('54', 'WV', 'West Virginia',        'South', 'South Atlantic'),
('01', 'AL', 'Alabama',              'South', 'East South Central'),
('21', 'KY', 'Kentucky',             'South', 'East South Central'),
('28', 'MS', 'Mississippi',          'South', 'East South Central'),
('47', 'TN', 'Tennessee',            'South', 'East South Central'),
('05', 'AR', 'Arkansas',             'South', 'West South Central'),
('22', 'LA', 'Louisiana',            'South', 'West South Central'),
('40', 'OK', 'Oklahoma',             'South', 'West South Central'),
('48', 'TX', 'Texas',                'South', 'West South Central'),

-- West
('04', 'AZ', 'Arizona',              'West', 'Mountain'),
('08', 'CO', 'Colorado',             'West', 'Mountain'),
('16', 'ID', 'Idaho',                'West', 'Mountain'),
('30', 'MT', 'Montana',              'West', 'Mountain'),
('32', 'NV', 'Nevada',               'West', 'Mountain'),
('35', 'NM', 'New Mexico',           'West', 'Mountain'),
('49', 'UT', 'Utah',                 'West', 'Mountain'),
('56', 'WY', 'Wyoming',              'West', 'Mountain'),
('02', 'AK', 'Alaska',               'West', 'Pacific'),
('06', 'CA', 'California',           'West', 'Pacific'),
('15', 'HI', 'Hawaii',               'West', 'Pacific'),
('41', 'OR', 'Oregon',               'West', 'Pacific'),
('53', 'WA', 'Washington',           'West', 'Pacific'),

-- Territory
('72', 'PR', 'Puerto Rico',          NULL, NULL);

-- Check that all 52 entries were inserted.
SELECT COUNT(*) AS state_count FROM states;
