#!/bin/sh
JAVA=/usr/bin/java
JARFILE=LanguageTool-2.4.1/languagetool-server.jar
PORT=8000
sudo ${JAVA} -cp ${JARFILE} org.languagetool.server.HTTPServer --port ${PORT}
# sudo /usr/bin/java -cp LanguageTool-2.4.1/languagetool-server.jar org.languagetool.server.HTTPServer --port 8000
