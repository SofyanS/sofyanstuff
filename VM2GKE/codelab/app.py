import cherrypy
from yaml import load
import socket
from sqlalchemy import create_engine
from sqlalchemy.sql import select
conf = load(open("config/config.yaml"))
conn_string = 'mysql+pymysql://root:solution-admin@10.128.0.2'
print conn_string
engine = create_engine(conn_string)

print conf['db-host']
class AppServer(object):
    @cherrypy.expose
    def index(self):
        try:
                result = ["<style>table, th, td {border: 1px solid black;}</style><table>"]
                connection = engine.connect()
                rows = connection.execute("select * from source_db.source_table")
                for row in rows:
                        result.append("<tr>")
                        for cell in row:
                                result.append("<td>%s</td>" % str(cell))
                        result.append("</tr>")
                result.append("</table>")
                return "".join(result)
        except:
                return "Database is initializing, please try again in a minute."
cherrypy.config.update({'server.socket_port': 80})
cherrypy.server.socket_host = "0.0.0.0"
cherrypy.quickstart(AppServer())
                                       
