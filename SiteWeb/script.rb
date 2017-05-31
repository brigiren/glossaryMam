#!/usr/bin/env ruby

system "cls"
system "clear"

puts "---------------------------------"
puts "Website Generator"
puts "---------------------------------"


# Gem pour la gestion des templates
require 'erb'
# Gem pour la manipulation de structure
require 'ostruct'
# Gem pour la manipulation de fichier/r�pertoire
require 'fileutils'
# Gem pour la manipulation des XML
require 'rexml/document'
include REXML

# Logs
#logg = File.open('logg.txt','w')

# Traitement des arguments
glossary_file = nil

ARGV.each{ |arg|
	case arg
		when /glossary=(.*)/
		glossary_file = arg.gsub(/(glossary=)/, "")
	end
}

# V�rification des d'arguments
if glossary_file == nil
	puts "Set a valid glossary data file path with glossary="
	exit
end

# Ouverture du fichier si existant
if File.exist?(glossary_file) == false
	puts "Invalid file Path"
	exit
end
file = File.open(glossary_file)
doc = Document.new(file)
root = doc.root

# R�cup�ration des don�es automatiques
time = Time.new
date = time.strftime("%Y-%m-%d")
user = ENV['USER']

# Cr�ation des structures recevant les infos
fileDataStruct = Struct.new( :pageName, :frWord, :frExample, :enWord, :enExample, :domain )

# On cr�e le fichier d'�num�rateurs
ERB_glossary_page_template = ERB.new( File.read( './glossary_page_template.erb' ), nil, '-' )
ERB_glossary_ABC_template = ERB.new( File.read( './glossary_ABC_template.erb' ), nil, '-' )

# Cr�ation du dossier de sortie si non existant
if File.directory?('Output') == false
	FileUtils::mkdir_p 'Output'
end


#########################################################
#	Traitement des don�es brutes						#
#-------------------------------------------------------#
#	Args : 	- filePath: Fichier	data (csv)  			#
#			- itemList: Tableau des don�es             	#
#########################################################
def compute_glossary_data_file( filePath, itemList )
fileDataStruct = Struct.new( :pageName, :frWord, :frExample, :enWord, :enExample, :domain )

	# Ouverture du fichier si existant
	if File.exist?(filePath) == false
		puts "Invalid file Path"
		exit
	end
	file = File.open(filePath)

	puts "Computing " + filePath + "..."
	
	# Traitement du fichier
	file.each {|line|
	  if ((line.include? "mot anglais") == false )	# Exclusion de la premi�re ligne
		splitted_Line = line.split("\t")
		# Mise en forme du mot
		pageName = splitted_Line[2].downcase.gsub(/(\/| |'|-)/, "_").gsub(/(\(|\))/, "").gsub(/(,|_$|^_)/, "")
		itemList << fileDataStruct.new( pageName, splitted_Line[0], splitted_Line[1], splitted_Line[2], splitted_Line[3], splitted_Line[4] )
	  end
	}
	
	puts "Computed " + itemList.count.to_s + " items"
end

#########################################################
#	Tri par ordre alphabetique EN						#
#-------------------------------------------------------#
#	Args : 	- itemList: Tableau des don�es             	#
#########################################################
def sort_glossary_data_en( itemList )
fileDataStruct = Struct.new( :pageName, :frWord, :frExample, :enWord, :enExample, :domain )

return itemList.sort_by { |item| [item.enWord.downcase] }
	
	itemList.each {|item|
	#puts item.enWord
	}
end

#########################################################
#	Tri par ordre alphabetique FR						#
#-------------------------------------------------------#
#	Args : 	- itemList: Tableau des don�es             	#
#########################################################
def sort_glossary_data_fr( itemList )
fileDataStruct = Struct.new( :pageName, :frWord, :frExample, :enWord, :enExample, :domain )

itemList = itemList.sort_by { |item| [item.frWord.downcase] }
	
	itemList.each {|item|
	puts item.frWord
	}
end

#########################################################
#	Cr�ation des pages									#
#-------------------------------------------------------#
#	Args : 	- outputPath: Dossier de sortie  			#
#			- itemList: Tableau des don�es             	#
#			- namespace: Namespace             			#
#########################################################
def create_glossary_pages_file( outputPath, itemList, namespace )
	fileDataStruct = Struct.new( :frWord, :frExample, :enWord, :enExample, :domain )

	puts "Creating pages in " + outputPath + "..."
	
	# Traitement du fichier
	itemList.each {|item|
	#puts item.pageName
	File.open( outputPath + "/" + item.pageName + ".html", 'w' ) { |objectFile| objectFile.write( ERB_glossary_page_template.result( namespace.instance_eval { binding } )  ) }
	}
	
	puts "Created " + itemList.count.to_s + " pages"
end

################################################################################################################################

###############################
#	Parcours du fichier CSV   #
###############################
itemList = Array.new
itemListSorted = Array.new

# Traitement du fichier data existant
compute_glossary_data_file( glossary_file, itemList )

# Tri des mots
itemListSortedEN = sort_glossary_data_en( itemList )
	itemListSortedEN.each {|item|
	puts item.enWord
	}

# Creation des fichiers
namespaceFile = OpenStruct.new( glossary_file: glossary_file, itemList: itemList, date: date, user: user )
create_glossary_pages_file( "Output", itemList, namespaceFile )

File.open( "Output" + "/" + "ABC.html", 'w' ) { |objectFile| objectFile.write( ERB_glossary_ABC_template.result( namespaceFile.instance_eval { binding } )  ) }
