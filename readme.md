# Multiply. The definitive addon for Dandanator ZX Mini
Addon for [Dandanator Mini](http://www.dandare.es/Proyectos_Dandare/ZX_Dandanator!_Mini.html). A Spectrum ZX peripheral with many features.

##Requirements
Arduino IDE, Sjasmplus or similar Z80 compiler
jar file for the "Java Romset generator" from https://github.com/teiram/dandanator-mini.git
##Cloning the repository
 git clone https://github.com/mad3001/Multiply
 
##Building
 1.Use the Arduino IDE to upload the sketch to the Multiply's Arduino Nano. This process requires the Multiply to be disconnected from the Dandanator ZX Mini
 2.Use SJASMPlus to create the MLD file containing the navigation menu
##Executing
 1.Open "Java Romset generator" and insert your created MLD file as if it was a Multiload File for Dandanator ZX Mini
 2.Connect Multiply to Dandanator ZX Mini, all to ZX Spectrum and then power the system. From Dandanator menu use L=Loader to upload romset from "Java Romset generator" including the Multiply MLD file created previously.