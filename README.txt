Copyright (c) 2012 Provideotech.org										 
                                                                           
Castor - PresSTORE/CatDV integration                                      
                                                                           
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
NO EVENT SHALL THE ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,       
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR     
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE 
USE OR OTHER DEALINGS IN THE SOFTWARE.                                    
                                                                          
Except as contained in this notice, the name(s) of the above copyright    
holders shall not be used in advertising or otherwise to promote the      
sale, use or other dealings in this Software without prior written        
authorization.                                                            

This software is used to connect Archiware PresSTORE to Squarebox CatDV.  It
allows for CatDV full res media to be stored and recovered using the Archiware
PresSTORE product.

Castor is a work in progress, but this file will show the changes in public
release below.

As of this writing, it has been tested on MacOS X 10.7.2 and 10.6.8

Roadmap:

Add scripting to create appropriate archive plans, indexes, and fields in PS
Add scripting to create proper fields on CatDV server
Add manual to explain how it all works
Maybe do a GUI at some point

BUG FIXES
=================
3-12-2012
Added folder creation to configure.pl, fixes issue where if directories didn't
exist configure would fail.

Modified metadata.conf file to have correct format in comments

1-24-2012
Fixed problems with relative paths (not good practice)
Fixed issue with installer and permissions

CHANGELOG
=================
3-12-2012
Bug fixes

1-24-2012
Bug fixes

1-23-2012

Rebranded software as Castor

Modified folder structure so all documents are in one directory 
(/usr/local/Castor)

Added this README file

Modified XML mapping to make it easier (less to modify for the customer

Added github repository (github/szumlins/Castor)

Added LOTS of validation and function tests.  Errors should be much easier 
to find.

Added CLI tools for all scripts so they can be run manually to test

Wrote configure.pl script to write all the config scripts and do 
basic installation
Created .pkg installer