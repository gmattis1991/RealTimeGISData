import pyodbc
import os
from arcgis.gis import GIS

#lists for calls used during the update process
agol_calls = []
current_calls = []
call_numbers = []

# SQL Query being passed through the ODBC connection
SQL_QUERY = """
select callid, type,nature,rtaddr,rtcity,priort,zone,reprtd,xpos,ypos,CommonName
from database.schema.view
order by reprtd desc
"""

def ODBC_connect():
    SERVER = '' # Server FQDN
    DATABASE = '' # Database Name
    ## Connection string to pass in pyodbc connection request. Using Trusted_Connect=yes to have SQL Server Native Client ODBC driver use Windows Authentication of the account running the script
    ## Using the Windows Authentication of the account running the script allows for the use of a Managed Service Account to run the scheduled python script
    connectionString = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes'
    conn = pyodbc.connect(connectionString)
    cursor = conn.cursor()
    cursor.execute(SQL_QUERY)
    records = cursor.fetchall()
    for r in records:
        record = [r.callid,r.type,r.nature,r.rtaddr,r.rtcity,r.priort,r.zone,r.reprtd,r.xpos,r.ypos,r.CommonName]
        current_calls.append(record)
        call_numbers.append(r.callid)

def Portal_push():
    user = os.getenv('') # System Environmental Variable Name for Username
    password = os.getenv('') # System Environmental Variable Name for Password
    portal = os.getenv('') # System Environmental Variable Name for Portal URL
    gis = GIS(portal,user,password,use_gen_token=True)
    agol_item = gis.content.get('') # ArcGIS Online Item ID
    cadLayer = agol_item.layers[0]
    cadFSet = cadLayer.query(where= '1=1')
    cad_list = cadFSet.features

    # Retrieving the call numbers that are existing in the ArcGIS Online Feature Service
    for exsting_call in cad_list:
        agol_calls.append(exsting_call.attributes['ID'])

    for call in agol_calls:
        if call not in call_numbers:
            call_feature = [f for f in cad_list if f.attributes['ID'] == call][0]
            call_objid = call_feature.get_value('OBJECTID')
            cadLayer.edit_features(deletes=str(call_objid))

    # Adding Calls
    for call in current_calls:
        if call[0] not in agol_calls:
            call_dict = {"attributes":
                        {"ID":call[0],
                        "CallType":call[1],
                        "CallNature":call[2],
                        "ReportedAddress":call[3].upper(),
                        "City":call[4],
                        "CallPriority":call[5],
                        "CallZone":call[6],
                        "DT_Reported":call[7],
                        "CommonName":call[10]},
                        "geometry":
                        {"x": call[8], "y": call[9]}}
            cadLayer.edit_features(adds=[call_dict])

if __name__ == '__main__':
    ODBC_connect()
    Portal_push()
