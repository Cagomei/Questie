import csv

"""

This script prints a zoneLookup table that maps AreaIDs to their ContinentIDs like this:

zoneLookup={
    [ContinentID]={
        [AreaID]="AreaName_lang",
        ...
    },
    ...
}

Because some areas are "physically" on a different continent map then the one they are shown on
ingame (e.g. Eversong Woods is on the Outland map but shown in Eastern Kingdoms) we need to do some
cross-referencing first.

"""

areatable = {}

mop_build_version = '5.5.0.60700'
with open('DBC - WoW.tools/AreaTable.%s.csv' % mop_build_version, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        areatable[row['ID']] = row

uimap = {}
with open('DBC - WoW.tools/UiMap.%s.csv' % mop_build_version, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        uimap[row['ID']] = row

uimapassignment = {}
with open('DBC - WoW.tools/UiMapAssignment.%s.csv' % mop_build_version, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        uimapassignment[row['ID']] = row

areaIdToUiMapId = {}
uiMapIdToAreaId = {}

for weirdID in uimapassignment:
    item = uimapassignment[weirdID]
    if item['OrderIndex'] == '0' and item['AreaID'] != '0':
        if item['AreaID'] not in areaIdToUiMapId:
            areaIdToUiMapId[item['AreaID']] = item['UiMapID']
        else:
            print('double for AreaID:', item['AreaID'])
        if item['UiMapID'] not in uiMapIdToAreaId:
            uiMapIdToAreaId[item['UiMapID']] = item['AreaID']
        else:
            print('double for UiMapID:', item['UiMapID'])

map0 = {}
# Pre-Mop values
# '<ID>' = ID from UiMap
# map1 = {
#     #'946': ('Cosmic', 0, -1),
#     #'947': ('Azeroth', 946, -1),
#     '113': ('Northrend', '947', '571'),
#     '1414': ('Kalimdor', '947', '1'),
#     '1415': ('Eastern Kingdoms', '947', '0'),
#     '1945': ('Outland', '946', '530'),
#     '1945': ('Pandaria', '947', '0'),
# }
map1 = {
    #'946': ('Cosmic', 0, -1),
    #'947': ('Azeroth', 946, -1),
    '988': ('Northrend', '947', '571'),
    '1464': ('Kalimdor', '947', '1'),
    '1463': ('Eastern Kingdoms', '947', '0'),
    '1467': ('Outland', '946', '530'),
    '2473': ('Pandaria', '947', '0'),
}
map2 = {}
map3 = {}

for entry in uimap:
    if uimap[entry]['Type'] in ['3', '4', '6'] and uimap[entry]['ParentUiMapID'] != 0:
        parent = uimap[entry]['ParentUiMapID']
        if parent not in map1 and uimap[parent]['ParentUiMapID'] in map1:
            parent = uimap[parent]['ParentUiMapID']
        if parent not in map2:
            map2[parent] = []
        map2[parent].append(entry)
        map3[entry] = parent

x = []
for entry in areatable:
    parent = areatable[entry]['ParentAreaID']
    continent = areatable[entry]['ContinentID']
    if parent == '0' and\
    (entry in areaIdToUiMapId) and\
    (areaIdToUiMapId[entry] in map3) and\
    (map3[areaIdToUiMapId[entry]] in map1):
        continent = map1[map3[areaIdToUiMapId[entry]]][2]
    while parent != '0':
        continent = areatable[parent]['ContinentID']
        if (parent in areaIdToUiMapId) and\
        (areaIdToUiMapId[parent] in map3) and\
        (map3[areaIdToUiMapId[parent]] in map1):
            continent = map1[map3[areaIdToUiMapId[parent]]][2]
        parent = areatable[parent]['ParentAreaID']

    if continent not in map0:
        map0[continent] = []
        x.append(int(continent))
    map0[continent].append((entry, areatable[entry]['AreaName_lang']))

print('l10n.zoneLookup = {')
for y in sorted(x):
    print('    [%d]={'%y)
    for id, name in map0[str(y)]:
        print('        [%s]="%s",' % (id, name))
    print('    },')
print('}')
